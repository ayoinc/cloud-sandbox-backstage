//! Items kept in process memory. The content is lost on restart and is not
//! shared between replicas: replace this module to persist it.

use std::convert::Infallible;
use std::sync::Arc;

use serde::Serialize;
use tokio::sync::RwLock;
use uuid::Uuid;

/// The in-memory store cannot fail.
pub type StoreError = Infallible;

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct Item {
    pub id: Uuid,
    pub name: String,
}

#[derive(Clone, Default)]
pub struct Store {
    items: Arc<RwLock<Vec<Item>>>,
}

impl Store {
    /// Every item, oldest first.
    pub async fn list(&self) -> Result<Vec<Item>, StoreError> {
        Ok(self.items.read().await.clone())
    }

    pub async fn get(&self, id: Uuid) -> Result<Option<Item>, StoreError> {
        let items = self.items.read().await;
        Ok(items.iter().find(|item| item.id == id).cloned())
    }

    pub async fn create(&self, name: &str) -> Result<Item, StoreError> {
        let item = Item {
            id: Uuid::now_v7(),
            name: name.to_owned(),
        };
        self.items.write().await.push(item.clone());
        Ok(item)
    }

    /// Whether the store is reachable; always, in memory. Async like the
    /// other methods, so that a database can replace this store.
    #[allow(clippy::unused_async, clippy::unused_async_trait_impl)]
    pub async fn ping(&self) -> Result<(), StoreError> {
        Ok(())
    }
}
