package config

import (
	"log/slog"
	"testing"
	"time"
)

func env(values map[string]string) func(string) string {
	return func(key string) string { return values[key] }
}

func TestLoadDefaults(t *testing.T) {
	cfg, err := Load(env(nil))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if cfg.Port != defaultPort || cfg.Environment != defaultEnvironment ||
		cfg.LogLevel != slog.LevelInfo || cfg.ShutdownTimeout != defaultShutdownTimeout {
		t.Errorf("unexpected defaults: %+v", cfg)
	}
}

func TestLoadOverrides(t *testing.T) {
	cfg, err := Load(env(map[string]string{
		"PORT":             "9000",
		"APP_ENV":          "production",
		"LOG_LEVEL":        "debug",
		"SHUTDOWN_TIMEOUT": "3s",
	}))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	want := Config{Port: 9000, Environment: "production", LogLevel: slog.LevelDebug, ShutdownTimeout: 3 * time.Second}
	if cfg != want {
		t.Errorf("got %+v, want %+v", cfg, want)
	}
}

func TestLoadRejectsInvalidValues(t *testing.T) {
	for name, values := range map[string]map[string]string{
		"port not a number": {"PORT": "http"},
		"port out of range": {"PORT": "70000"},
		"unknown log level": {"LOG_LEVEL": "loud"},
		"negative timeout":  {"SHUTDOWN_TIMEOUT": "-1s"},
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := Load(env(values)); err == nil {
				t.Error("expected an error")
			}
		})
	}
}
