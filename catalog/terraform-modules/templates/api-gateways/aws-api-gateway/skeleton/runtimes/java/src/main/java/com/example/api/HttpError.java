package com.example.api;

/** Thrown by a handler to answer with a specific status and message. */
public final class HttpError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  private final int statusCode;

  public HttpError(int statusCode, String message) {
    super(message);
    this.statusCode = statusCode;
  }

  public int statusCode() {
    return statusCode;
  }
}
