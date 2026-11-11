package com.example.api;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.Map;

/**
 * The fields of an API Gateway REST proxy event that the function uses.
 *
 * @param httpMethod request method, for example {@code GET}
 * @param resource path template of the matched route, for example {@code /items/{id}}
 * @param pathParameters values of the path template's variables, or null when it has none
 * @param body request body, or null
 * @param isBase64Encoded whether {@code body} is Base64 encoded
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record Request(
    @JsonProperty("httpMethod") String httpMethod,
    @JsonProperty("resource") String resource,
    @JsonProperty("pathParameters") Map<String, String> pathParameters,
    @JsonProperty("body") String body,
    @JsonProperty("isBase64Encoded") boolean isBase64Encoded) {

  /** The value of a path variable, or null when the route has no such variable. */
  public String pathParameter(String name) {
    return pathParameters == null ? null : pathParameters.get(name);
  }
}
