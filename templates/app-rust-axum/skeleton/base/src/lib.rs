//! ${{ values.name }}: HTTP API built with axum.

pub mod config;
pub mod error;
mod routes;
pub mod store;

use std::time::Duration;

use axum::Router;
use axum::http::StatusCode;
use tower_http::request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer};
use tower_http::timeout::TimeoutLayer;
use tower_http::trace::TraceLayer;

use crate::store::Store;

/// Time a request may take before the service answers 408.
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);

/// What every handler can reach.
#[derive(Clone)]
pub struct AppState {
    pub environment: String,
    pub store: Store,
}

/// The router with its middleware. Layers run from the last added to the
/// first: the request ID is set before the request is traced.
pub fn app(state: AppState) -> Router {
    routes::router()
        .with_state(state)
        .layer(TimeoutLayer::with_status_code(
            StatusCode::REQUEST_TIMEOUT,
            REQUEST_TIMEOUT,
        ))
        .layer(PropagateRequestIdLayer::x_request_id())
        .layer(TraceLayer::new_for_http())
        .layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))
}
