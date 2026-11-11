// Package config reads the service settings from the environment.
package config

import (
	"fmt"
	"log/slog"
	"strconv"
	"time"
)

// ServiceName identifies the service in logs, traces and the health endpoint.
const ServiceName = "${{ values.name }}"

const (
	defaultPort            = ${{ values.port }}
	defaultEnvironment     = "development"
	defaultShutdownTimeout = 15 * time.Second
)

// Config holds the settings of the service.
type Config struct {
	Port            int
	Environment     string
	LogLevel        slog.Level
	ShutdownTimeout time.Duration
}

// Load reads the configuration with getenv, which is os.Getenv outside tests.
// Unset variables take their default; invalid values are an error.
func Load(getenv func(string) string) (Config, error) {
	cfg := Config{
		Port:            defaultPort,
		Environment:     defaultEnvironment,
		LogLevel:        slog.LevelInfo,
		ShutdownTimeout: defaultShutdownTimeout,
	}

	if v := getenv("PORT"); v != "" {
		port, err := strconv.Atoi(v)
		if err != nil || port < 1 || port > 65535 {
			return Config{}, fmt.Errorf("PORT %q is not a port number", v)
		}
		cfg.Port = port
	}
	if v := getenv("APP_ENV"); v != "" {
		cfg.Environment = v
	}
	if v := getenv("LOG_LEVEL"); v != "" {
		if err := cfg.LogLevel.UnmarshalText([]byte(v)); err != nil {
			return Config{}, fmt.Errorf("LOG_LEVEL %q is not debug, info, warn or error", v)
		}
	}
	if v := getenv("SHUTDOWN_TIMEOUT"); v != "" {
		timeout, err := time.ParseDuration(v)
		if err != nil || timeout <= 0 {
			return Config{}, fmt.Errorf("SHUTDOWN_TIMEOUT %q is not a positive duration such as 15s", v)
		}
		cfg.ShutdownTimeout = timeout
	}
	return cfg, nil
}
