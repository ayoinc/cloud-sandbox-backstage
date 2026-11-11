use axum::Json;
use axum::extract::rejection::{JsonRejection, PathRejection};
use axum::extract::{Path, State};
use axum::http::{StatusCode, header};
use axum::response::IntoResponse;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::AppState;
use crate::error::AppError;
use crate::store::Item;

const MAX_NAME_LENGTH: usize = 200;

#[derive(Serialize)]
pub struct ItemList {
    items: Vec<Item>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct NewItem {
    name: String,
}

pub async fn list(State(state): State<AppState>) -> Result<Json<ItemList>, AppError> {
    let items = state.store.list().await?;
    Ok(Json(ItemList { items }))
}

pub async fn get(
    State(state): State<AppState>,
    id: Result<Path<Uuid>, PathRejection>,
) -> Result<Json<Item>, AppError> {
    let Path(id) = id?;
    let item = state.store.get(id).await?.ok_or(AppError::NotFound)?;
    Ok(Json(item))
}

pub async fn create(
    State(state): State<AppState>,
    body: Result<Json<NewItem>, JsonRejection>,
) -> Result<impl IntoResponse, AppError> {
    let Json(input) = body?;
    let name = input.name.trim();
    if name.is_empty() || name.chars().count() > MAX_NAME_LENGTH {
        return Err(AppError::Validation(format!(
            "name must have between 1 and {MAX_NAME_LENGTH} characters"
        )));
    }

    let item = state.store.create(name).await?;
    let location = format!("/api/items/{}", item.id);
    Ok((
        StatusCode::CREATED,
        [(header::LOCATION, location)],
        Json(item),
    ))
}
