//! Items stored in PostgreSQL through sqlx.

use std::time::Duration;

use serde::Serialize;
use sqlx::PgPool;
use sqlx::postgres::PgPoolOptions;
use uuid::Uuid;

pub type StoreError = sqlx::Error;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, sqlx::FromRow)]
pub struct Item {
    pub id: Uuid,
    pub name: String,
}

#[derive(Clone)]
pub struct Store {
    pool: PgPool,
}

impl Store {
    /// A store on a pool that connects on first use, so the service starts
    /// while the database is still coming up; `/health/ready` reports when it
    /// is reachable.
    pub fn connect(database_url: &str) -> Result<Self, StoreError> {
        let pool = PgPoolOptions::new()
            .max_connections(10)
            .acquire_timeout(Duration::from_secs(5))
            .connect_lazy(database_url)?;
        Ok(Self { pool })
    }

    /// A store on an existing pool; the tests use it.
    #[must_use]
    pub fn from_pool(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Applies the migrations in `migrations/`, which are compiled into the
    /// binary.
    pub async fn migrate(&self) -> Result<(), sqlx::migrate::MigrateError> {
        sqlx::migrate!().run(&self.pool).await
    }

    /// Every item, oldest first: version 7 UUIDs sort by creation time.
    pub async fn list(&self) -> Result<Vec<Item>, StoreError> {
        sqlx::query_as("SELECT id, name FROM items ORDER BY id")
            .fetch_all(&self.pool)
            .await
    }

    pub async fn get(&self, id: Uuid) -> Result<Option<Item>, StoreError> {
        sqlx::query_as("SELECT id, name FROM items WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
    }

    pub async fn create(&self, name: &str) -> Result<Item, StoreError> {
        sqlx::query_as("INSERT INTO items (id, name) VALUES ($1, $2) RETURNING id, name")
            .bind(Uuid::now_v7())
            .bind(name)
            .fetch_one(&self.pool)
            .await
    }

    /// Whether the database answers.
    pub async fn ping(&self) -> Result<(), StoreError> {
        sqlx::query("SELECT 1").execute(&self.pool).await?;
        Ok(())
    }
}
