mod health;
mod items;

use axum::Router;
use axum::routing::get;

use crate::AppState;
use crate::error::AppError;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/health", get(health::health))
        .route("/health/live", get(health::live))
        .route("/health/ready", get(health::ready))
        .route("/api/items", get(items::list).post(items::create))
        .route("/api/items/{id}", get(items::get))
        .fallback(|| async { AppError::NotFound })
}
