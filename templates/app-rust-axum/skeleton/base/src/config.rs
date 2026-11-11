//! Settings read from the environment.

use std::env::VarError;

/// Name of the service in logs and in the health endpoint.
pub const SERVICE_NAME: &str = env!("CARGO_PKG_NAME");
/// Version of the crate, reported by the health endpoint.
pub const SERVICE_VERSION: &str = env!("CARGO_PKG_VERSION");

const DEFAULT_PORT: u16 = ${{ values.port }};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Config {
    pub port: u16,
    pub environment: String,
    /// Filter directives of `tracing`, such as `info` or `info,tower_http=debug`.
    pub log_level: String,
{%- if values.database == 'postgres' %}
    pub database_url: String,
{%- endif %}
}

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum ConfigError {
    #[error("{0} is not set")]
    Missing(&'static str),
    #[error("{name} is invalid: {reason}")]
    Invalid { name: &'static str, reason: String },
}

impl Config {
    /// Reads the configuration from the process environment.
    pub fn from_env() -> Result<Self, ConfigError> {
        Self::from_lookup(std::env::var)
    }

    /// Reads the configuration with `lookup`, which tests replace.
    pub fn from_lookup(
        lookup: impl Fn(&'static str) -> Result<String, VarError>,
    ) -> Result<Self, ConfigError> {
        let optional = |name| match lookup(name) {
            Ok(value) if !value.is_empty() => Ok(Some(value)),
            Ok(_) | Err(VarError::NotPresent) => Ok(None),
            Err(VarError::NotUnicode(_)) => Err(ConfigError::Invalid {
                name,
                reason: "not valid Unicode".to_owned(),
            }),
        };

        let port = match optional("PORT")? {
            Some(value) => value.parse().map_err(|_| ConfigError::Invalid {
                name: "PORT",
                reason: format!("{value:?} is not a port number"),
            })?,
            None => DEFAULT_PORT,
        };

        Ok(Self {
            port,
            environment: optional("APP_ENV")?.unwrap_or_else(|| "development".to_owned()),
            log_level: optional("LOG_LEVEL")?.unwrap_or_else(|| "info".to_owned()),
{%- if values.database == 'postgres' %}
            database_url: optional("DATABASE_URL")?.ok_or(ConfigError::Missing("DATABASE_URL"))?,
{%- endif %}
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn lookup(
        values: &'static [(&'static str, &'static str)],
    ) -> impl Fn(&'static str) -> Result<String, VarError> {
        move |name| {
            values
                .iter()
                .find(|(key, _)| *key == name)
                .map(|(_, value)| (*value).to_owned())
                .ok_or(VarError::NotPresent)
        }
    }

    #[test]
    fn defaults_apply_when_nothing_is_set() {
{%- if values.database == 'postgres' %}
        let config = Config::from_lookup(lookup(&[("DATABASE_URL", "postgres://db/app")])).unwrap();
{%- else %}
        let config = Config::from_lookup(lookup(&[])).unwrap();
{%- endif %}
        assert_eq!(config.port, DEFAULT_PORT);
        assert_eq!(config.environment, "development");
        assert_eq!(config.log_level, "info");
    }

    #[test]
    fn values_from_the_environment_win() {
        let config = Config::from_lookup(lookup(&[
            ("PORT", "9000"),
            ("APP_ENV", "production"),
            ("LOG_LEVEL", "debug"),
            ("DATABASE_URL", "postgres://db/app"),
        ]))
        .unwrap();
        assert_eq!(config.port, 9000);
        assert_eq!(config.environment, "production");
        assert_eq!(config.log_level, "debug");
    }

    #[test]
    fn an_invalid_port_is_rejected() {
        let error = Config::from_lookup(lookup(&[
            ("PORT", "http"),
            ("DATABASE_URL", "postgres://db/app"),
        ]))
        .unwrap_err();
        assert!(matches!(error, ConfigError::Invalid { name: "PORT", .. }));
    }
{%- if values.database == 'postgres' %}

    #[test]
    fn the_database_url_is_required() {
        let error = Config::from_lookup(lookup(&[])).unwrap_err();
        assert_eq!(error, ConfigError::Missing("DATABASE_URL"));
    }
{%- endif %}
}
