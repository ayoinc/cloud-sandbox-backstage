//! The tests marked `sqlx::test` need PostgreSQL: start it with
//! `docker compose up -d --wait` and set `DATABASE_URL` as in `.env.example`.
//! Each of them runs in its own temporary database with the migrations
//! applied.

use axum::Router;
use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use http_body_util::BodyExt;
use serde_json::{Value, json};
use tower::ServiceExt;

use ${{ values.name | replace("-", "_") }}::store::Store;
use ${{ values.name | replace("-", "_") }}::{AppState, app};

fn test_app(store: Store) -> Router {
    app(AppState {
        environment: "test".to_owned(),
        store,
    })
}

async fn call(app: &Router, request: Request<Body>) -> (StatusCode, Value) {
    let response = app.clone().oneshot(request).await.unwrap();
    let status = response.status();
    let bytes = response.into_body().collect().await.unwrap().to_bytes();
    let body = serde_json::from_slice(&bytes).unwrap_or(Value::Null);
    (status, body)
}

fn get(path: &str) -> Request<Body> {
    Request::get(path).body(Body::empty()).unwrap()
}

fn post(path: &str, body: &str) -> Request<Body> {
    Request::post(path)
        .header(header::CONTENT_TYPE, "application/json")
        .body(Body::from(body.to_owned()))
        .unwrap()
}

async fn health_reports_the_service(app: Router) {
    let (status, body) = call(&app, get("/health")).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body["status"], "ok");
    assert_eq!(body["service"], env!("CARGO_PKG_NAME"));
    assert_eq!(body["environment"], "test");

    let (status, body) = call(&app, get("/health/live")).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body, json!({ "alive": true }));
}

async fn items_can_be_created_and_read(app: Router) {
    let (status, created) = call(&app, post("/api/items", r#"{"name":"  first  "}"#)).await;
    assert_eq!(status, StatusCode::CREATED);
    assert_eq!(created["name"], "first");
    let id = created["id"].as_str().unwrap();

    let (status, fetched) = call(&app, get(&format!("/api/items/{id}"))).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(fetched, created);

    let (status, listed) = call(&app, get("/api/items")).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(listed, json!({ "items": [created] }));
}

async fn invalid_input_is_rejected(app: Router) {
    for (body, expected) in [
        ("name=first", StatusCode::BAD_REQUEST),
        (r#"{"name":"first","admin":true}"#, StatusCode::BAD_REQUEST),
        (r#"{"name":"   "}"#, StatusCode::UNPROCESSABLE_ENTITY),
    ] {
        let (status, response) = call(&app, post("/api/items", body)).await;
        assert_eq!(status, expected, "{body}");
        assert!(response["error"].is_string(), "{body}");
    }
}

async fn unknown_resources_are_not_found(app: Router) {
    for path in [
        "/api/items/0198c1de-0000-7000-8000-000000000000",
        "/api/items/not-a-uuid",
        "/nowhere",
    ] {
        let (status, body) = call(&app, get(path)).await;
        assert_eq!(status, StatusCode::NOT_FOUND, "{path}");
        assert_eq!(body, json!({ "error": "Not Found" }), "{path}");
    }
}

/// A store whose database does not exist: nothing listens on port 1.
fn unreachable_store() -> Store {
    Store::connect("postgres://app:app@127.0.0.1:1/app").unwrap()
}

#[tokio::test]
async fn health_does_not_need_the_database() {
    health_reports_the_service(test_app(unreachable_store())).await;
}

#[tokio::test]
async fn not_ready_without_the_database() {
    let (status, body) = call(&test_app(unreachable_store()), get("/health/ready")).await;
    assert_eq!(status, StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(body, json!({ "ready": false }));
}

#[sqlx::test]
async fn ready(pool: sqlx::PgPool) {
    let (status, body) = call(&test_app(Store::from_pool(pool)), get("/health/ready")).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body, json!({ "ready": true }));
}

#[sqlx::test]
async fn items(pool: sqlx::PgPool) {
    items_can_be_created_and_read(test_app(Store::from_pool(pool))).await;
}

#[sqlx::test]
async fn invalid_input(pool: sqlx::PgPool) {
    invalid_input_is_rejected(test_app(Store::from_pool(pool))).await;
}

#[sqlx::test]
async fn not_found(pool: sqlx::PgPool) {
    unknown_resources_are_not_found(test_app(Store::from_pool(pool))).await;
}
