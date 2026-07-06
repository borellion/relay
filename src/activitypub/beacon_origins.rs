use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::postgres::PgRow;
use sqlx::{FromRow, Row};

/// A recorded (and still unresolved) beacon PUT that was rejected because the
/// browser's `Origin` header host didn't match the declared payload `url` host.
/// This is the normal shape of a legitimate cross-origin-iframe integration
/// (e.g. a game embedded on a partner site), not necessarily an attack -- it's
/// surfaced here so an admin can review and, if trusted, allowlist it.
#[derive(Clone, Serialize, Debug)]
pub struct DbBeaconOriginAttempt {
    pub id: i32,
    pub origin_host: String,
    pub target_host: String,
    pub example_url: String,
    pub attempt_count: i32,
    pub first_seen: DateTime<Utc>,
    pub last_seen: DateTime<Utc>,
    pub resolved: bool,
}

impl FromRow<'_, PgRow> for DbBeaconOriginAttempt {
    fn from_row(row: &PgRow) -> Result<Self, sqlx::Error> {
        Ok(Self {
            id: row.try_get("id")?,
            origin_host: row.try_get("origin_host")?,
            target_host: row.try_get("target_host")?,
            example_url: row.try_get("example_url")?,
            attempt_count: row.try_get("attempt_count")?,
            first_seen: row.try_get("first_seen")?,
            last_seen: row.try_get("last_seen")?,
            resolved: row.try_get("resolved")?,
        })
    }
}

/// An origin host that has been explicitly approved to register beacons on
/// behalf of a given target host, bypassing the strict same-host check in
/// `new_beacon`. Populated by an admin from the reviewed attempts list.
#[derive(Clone, Serialize, Debug)]
pub struct DbAllowedBeaconOrigin {
    pub id: i32,
    pub origin_host: String,
    pub target_host: String,
    pub created_at: DateTime<Utc>,
}

impl FromRow<'_, PgRow> for DbAllowedBeaconOrigin {
    fn from_row(row: &PgRow) -> Result<Self, sqlx::Error> {
        Ok(Self {
            id: row.try_get("id")?,
            origin_host: row.try_get("origin_host")?,
            target_host: row.try_get("target_host")?,
            created_at: row.try_get("created_at")?,
        })
    }
}
