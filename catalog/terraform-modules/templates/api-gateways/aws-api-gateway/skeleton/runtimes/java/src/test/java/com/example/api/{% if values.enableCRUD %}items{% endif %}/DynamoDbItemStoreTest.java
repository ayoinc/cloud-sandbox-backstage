package com.example.api.items;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.example.api.Request;
import com.example.api.Router;
import java.util.Map;
import org.junit.jupiter.api.Test;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

class DynamoDbItemStoreTest {
  private static final String JSON =
      "{\"id\":\"a1\",\"name\":\"first\",\"count\":3,\"price\":12.50,\"active\":true,"
          + "\"note\":null,\"tags\":[\"x\",1,false],\"size\":{\"width\":2,\"unit\":\"cm\"}}";

  private static Request request() {
    return new Request("POST", "/items", null, JSON, false);
  }

  @Test
  void aJsonObjectSurvivesTheConversionToAttributesAndBack() {
    Map<String, Object> object = Router.parseObject(request());
    Map<String, AttributeValue> attributes = DynamoDbItemStore.toAttributes(object);

    assertEquals(AttributeValue.fromS("a1"), attributes.get("id"));
    assertEquals(AttributeValue.fromN("3"), attributes.get("count"));
    assertEquals(AttributeValue.fromN("12.5"), attributes.get("price"));
    assertEquals(AttributeValue.fromBool(true), attributes.get("active"));
    assertEquals(AttributeValue.fromNul(true), attributes.get("note"));

    Map<String, Object> restored = DynamoDbItemStore.fromAttributes(attributes);
    assertEquals(Router.json(200, object).body(), Router.json(200, restored).body());
  }
}
