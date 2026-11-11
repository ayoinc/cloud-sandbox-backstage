package com.example.api.items;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.GetItemResponse;
import software.amazon.awssdk.services.dynamodb.model.ReturnValue;

/** Items in the DynamoDB table named by the environment variable ITEMS_TABLE. */
public final class DynamoDbItemStore implements ItemStore {
  private final String tableName;
  private DynamoDbClient client;

  public DynamoDbItemStore() {
    this(System.getenv("ITEMS_TABLE"));
  }

  public DynamoDbItemStore(String tableName) {
    this.tableName = tableName;
  }

  // Created on first use, so that building the route table needs neither a
  // region nor credentials.
  private DynamoDbClient client() {
    if (client == null) {
      client = DynamoDbClient.builder().httpClient(UrlConnectionHttpClient.create()).build();
    }
    return client;
  }

  @Override
  public List<Map<String, Object>> list() {
    return client().scan(scan -> scan.tableName(tableName).limit(100)).items().stream()
        .map(DynamoDbItemStore::fromAttributes)
        .toList();
  }

  @Override
  public Optional<Map<String, Object>> get(String id) {
    GetItemResponse response = client().getItem(get -> get.tableName(tableName).key(key(id)));
    return response.hasItem() ? Optional.of(fromAttributes(response.item())) : Optional.empty();
  }

  @Override
  public void put(Map<String, Object> item) {
    client().putItem(put -> put.tableName(tableName).item(toAttributes(item)));
  }

  @Override
  public boolean delete(String id) {
    return client()
        .deleteItem(
            delete -> delete.tableName(tableName).key(key(id)).returnValues(ReturnValue.ALL_OLD))
        .hasAttributes();
  }

  private static Map<String, AttributeValue> key(String id) {
    return Map.of("id", AttributeValue.fromS(id));
  }

  /** A JSON object as DynamoDB attributes. */
  static Map<String, AttributeValue> toAttributes(Map<?, ?> object) {
    Map<String, AttributeValue> attributes = new LinkedHashMap<>();
    object.forEach((name, value) -> attributes.put(String.valueOf(name), toAttribute(value)));
    return attributes;
  }

  private static AttributeValue toAttribute(Object value) {
    if (value == null) {
      return AttributeValue.fromNul(true);
    }
    if (value instanceof String string) {
      return AttributeValue.fromS(string);
    }
    if (value instanceof Boolean bool) {
      return AttributeValue.fromBool(bool);
    }
    if (value instanceof Number number) {
      // DynamoDB takes numbers as decimal strings.
      return AttributeValue.fromN(new BigDecimal(number.toString()).toPlainString());
    }
    if (value instanceof List<?> list) {
      return AttributeValue.fromL(list.stream().map(DynamoDbItemStore::toAttribute).toList());
    }
    if (value instanceof Map<?, ?> map) {
      return AttributeValue.fromM(toAttributes(map));
    }
    throw new IllegalArgumentException("Unsupported value type " + value.getClass().getName());
  }

  /** DynamoDB attributes as a JSON object. */
  static Map<String, Object> fromAttributes(Map<String, AttributeValue> attributes) {
    Map<String, Object> object = new LinkedHashMap<>();
    attributes.forEach((name, value) -> object.put(name, fromAttribute(value)));
    return object;
  }

  private static Object fromAttribute(AttributeValue value) {
    return switch (value.type()) {
      case S -> value.s();
      case N -> new BigDecimal(value.n());
      case BOOL -> value.bool();
      case NUL -> null;
      case L -> value.l().stream().map(DynamoDbItemStore::fromAttribute).toList();
      case M -> fromAttributes(value.m());
      case SS -> value.ss();
      case NS -> value.ns().stream().map(BigDecimal::new).toList();
      default ->
          throw new IllegalStateException("Unsupported attribute type " + value.type());
    };
  }
}
