use axum::Json;
use axum::extract::State;
use axum::http::StatusCode;
use serde_json::{Value, json};

use crate::AppState;
use crate::config::{SERVICE_NAME, SERVICE_VERSION};

pub async fn health(State(state): State<AppState>) -> Json<Value> {
    Json(json!({
        "status": "ok",
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "environment": state.environment,
    }))
}

pub async fn live() -> Json<Value> {
    Json(json!({ "alive": true }))
}

/// Ready when the store answers.
pub async fn ready(State(state): State<AppState>) -> (StatusCode, Json<Value>) {
    match state.store.ping().await {
        Ok(()) => (StatusCode::OK, Json(json!({ "ready": true }))),
        Err(error) => {
            tracing::warn!(%error, "store is not reachable");
            (
                StatusCode::SERVICE_UNAVAILABLE,
                Json(json!({ "ready": false })),
            )
        }
    }
}
