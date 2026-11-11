package com.example.api;

import java.util.Map;

/** An API Gateway proxy response. */
public record Response(int statusCode, Map<String, String> headers, String body) {}
