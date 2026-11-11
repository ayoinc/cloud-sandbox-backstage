use std::net::{Ipv4Addr, SocketAddr};
use std::process::ExitCode;

use tokio::net::TcpListener;
use tokio::signal;
use tracing_subscriber::EnvFilter;

use ${{ values.name | replace("-", "_") }}::config::{Config, SERVICE_NAME, SERVICE_VERSION};
use ${{ values.name | replace("-", "_") }}::store::Store;
use ${{ values.name | replace("-", "_") }}::{AppState, app};

#[tokio::main]
async fn main() -> ExitCode {
    let config = match Config::from_env() {
        Ok(config) => config,
        Err(error) => {
            eprintln!("configuration: {error}");
            return ExitCode::FAILURE;
        }
    };

    let filter = match EnvFilter::try_new(&config.log_level) {
        Ok(filter) => filter,
        Err(error) => {
            eprintln!("configuration: LOG_LEVEL is invalid: {error}");
            return ExitCode::FAILURE;
        }
    };
    tracing_subscriber::fmt()
        .json()
        .flatten_event(true)
        .with_env_filter(filter)
        .init();

    match run(config).await {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            tracing::error!(%error, "service stopped");
            ExitCode::FAILURE
        }
    }
}

async fn run(config: Config) -> Result<(), Box<dyn std::error::Error>> {
{%- if values.database == 'postgres' %}
    let store = Store::connect(&config.database_url)?;

    // `${{ values.name }} migrate` applies the migrations and exits. Run it
    // before a new version starts, for example as an init container or a job.
    if std::env::args().nth(1).as_deref() == Some("migrate") {
        store.migrate().await?;
        tracing::info!("migrations applied");
        return Ok(());
    }
{%- else %}
    let store = Store::default();
{%- endif %}

    let state = AppState {
        environment: config.environment.clone(),
        store,
    };

    let address = SocketAddr::from((Ipv4Addr::UNSPECIFIED, config.port));
    let listener = TcpListener::bind(address).await?;
    tracing::info!(
        service = SERVICE_NAME,
        version = SERVICE_VERSION,
        environment = config.environment,
        %address,
        "listening"
    );

    axum::serve(listener, app(state))
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    tracing::info!("stopped");
    Ok(())
}

/// Resolves on SIGINT or SIGTERM. axum then stops accepting connections and
/// lets requests in flight finish.
async fn shutdown_signal() {
    let interrupt = async {
        signal::ctrl_c().await.expect("install the SIGINT handler");
    };
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("install the SIGTERM handler")
            .recv()
            .await;
    };

    tokio::select! {
        () = interrupt => {},
        () = terminate => {},
    }
    tracing::info!("shutting down");
}
