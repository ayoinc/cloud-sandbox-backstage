package com.example.controller;

import java.time.Instant;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ApiController {

    private final String service;
    private final String environment;

    public ApiController(
            @Value("${spring.application.name}") String service,
            @Value("${app.environment}") String environment) {
        this.service = service;
        this.environment = environment;
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> root() {
        return ResponseEntity.ok(Map.of(
            "service", service,
            "version", "1.0.0",
            "message", "Welcome to " + service + " API"
        ));
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
            "status", "healthy",
            "timestamp", Instant.now().toString(),
            "service", service,
            "environment", environment
        ));
    }
}
