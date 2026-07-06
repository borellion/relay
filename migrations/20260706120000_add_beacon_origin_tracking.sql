-- Records beacon PUT attempts rejected because the Origin header host did not
-- match the declared payload url host (e.g. legitimate cross-origin iframe
-- integrations, or spoofing attempts). Reviewed manually from the admin panel.
CREATE TABLE beacon_origin_attempts (
    id SERIAL PRIMARY KEY,
    origin_host TEXT NOT NULL,
    target_host TEXT NOT NULL,
    example_url TEXT NOT NULL,
    attempt_count INTEGER NOT NULL DEFAULT 1,
    first_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (origin_host, target_host)
);

-- Origin hosts explicitly approved (via the admin panel) to register beacons
-- on behalf of a given target host, bypassing the same-host check.
CREATE TABLE beacon_allowed_origins (
    id SERIAL PRIMARY KEY,
    origin_host TEXT NOT NULL,
    target_host TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (origin_host, target_host)
);

CREATE INDEX idx_beacon_origin_attempts_pending ON beacon_origin_attempts (resolved, last_seen DESC);
