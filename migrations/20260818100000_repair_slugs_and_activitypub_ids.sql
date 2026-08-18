-- Repair data corrupted by deriving new apps' ActivityPub ids and slugs from
-- the table row count: once rows had been deleted, the count fell behind the
-- real ids, so slugs were attached to the wrong (older) rows and new beacon
-- numbers collided with existing apps.

-- 1. Regenerate every slug from the app's own name. ASCII approximation of
--    slug::slugify; duplicates get a -2/-3/... suffix like generate_unique_slug.
UPDATE apps SET slug = NULL;

WITH base AS (
    SELECT id,
           COALESCE(
               NULLIF(trim(BOTH '-' FROM regexp_replace(lower(COALESCE(name, '')), '[^a-z0-9]+', '-', 'g')), ''),
               'world'
           ) AS base_slug
    FROM apps
),
numbered AS (
    SELECT id,
           base_slug,
           row_number() OVER (PARTITION BY base_slug ORDER BY id) AS rn
    FROM base
)
UPDATE apps a
SET slug = CASE WHEN n.rn = 1 THEN n.base_slug ELSE n.base_slug || '-' || n.rn END
FROM numbered n
WHERE a.id = n.id;

-- 2. Renumber local beacons so the invariant the routes rely on holds again:
--    beacon number = id - 1 (/world/{n} resolves row id n + 1). Apps received
--    from other relays keep the ids minted by their home relay.
UPDATE apps a
SET activitypub_id = split_part(a.activitypub_id, '/beacon/', 1) || '/beacon/' || (a.id - 1)
FROM relays r
WHERE r.is_local
  AND a.activitypub_id LIKE '%/beacon/%'
  AND trim(TRAILING '/' FROM split_part(a.activitypub_id, '/beacon/', 1))
      = trim(TRAILING '/' FROM r.activitypub_id)
  AND split_part(a.activitypub_id, '/beacon/', 2) IS DISTINCT FROM (a.id - 1)::text;

-- 3. Any rows still sharing an ActivityPub id are true duplicates
--    (e.g. a remote Create delivered twice); keep the oldest.
DELETE FROM apps a
USING apps b
WHERE a.activitypub_id = b.activitypub_id
  AND a.id > b.id;

-- 4. Enforce uniqueness so a future collision fails loudly instead of
--    silently corrupting the catalog.
CREATE UNIQUE INDEX IF NOT EXISTS idx_apps_activitypub_id ON apps (activitypub_id);

-- 5. Make sure the id sequence is ahead of the data, since ids are now
--    reserved with nextval before insert.
SELECT setval(pg_get_serial_sequence('apps', 'id'), (SELECT COALESCE(MAX(id), 0) + 1 FROM apps), false);
