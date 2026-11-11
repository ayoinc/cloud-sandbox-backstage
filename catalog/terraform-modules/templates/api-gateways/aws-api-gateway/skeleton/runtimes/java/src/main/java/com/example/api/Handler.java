package com.example.api;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Map;

/**
 * Entry point of the Lambda function (handler
 * {@code com.example.api.Handler::handleRequest}). Reads the API Gateway proxy
 * event from the input stream and writes the proxy response to the output
 * stream.
 */
public final class Handler implements RequestStreamHandler {
  private static final Map<String, Route> ROUTES = Routes.table();

  @Override
  public void handleRequest(InputStream input, OutputStream output, Context context)
      throws IOException {
    Request request = Router.MAPPER.readValue(input, Request.class);
    Router.MAPPER.writeValue(output, Router.route(ROUTES, request));
  }
}
