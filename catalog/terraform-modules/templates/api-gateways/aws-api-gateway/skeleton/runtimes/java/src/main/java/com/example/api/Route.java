package com.example.api;

/** Handler of one entry of the route table. */
@FunctionalInterface
public interface Route {
  Response handle(Request request) throws Exception;
}
