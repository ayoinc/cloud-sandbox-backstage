"use strict";

const assert = require("node:assert/strict");
const { test } = require("node:test");
{% if values.triggerType == "http" %}
const { handleRequest } = require("../src/handler");

/** Minimal stand-in for the Express response the framework passes in. */
function createResponse() {
  return {
    statusCode: undefined,
    headers: {},
    body: undefined,
    set(name, value) {
      this.headers[name] = value;
      return this;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
  };
}

test("greets the world by default", () => {
  const res = createResponse();
  handleRequest({ method: "GET", query: {} }, res);
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.message, "Hello, world!");
});

test("greets the name from the query string", () => {
  const res = createResponse();
  handleRequest({ method: "GET", query: { name: "Ada" } }, res);
  assert.equal(res.body.message, "Hello, Ada!");
});

test("greets the name from the JSON body", () => {
  const res = createResponse();
  handleRequest({ method: "POST", query: {}, body: { name: "Grace" } }, res);
  assert.equal(res.body.message, "Hello, Grace!");
});

test("rejects other methods", () => {
  const res = createResponse();
  handleRequest({ method: "DELETE", query: {} }, res);
  assert.equal(res.statusCode, 405);
  assert.equal(res.headers.Allow, "GET, POST");
});

test("rejects a name that is not a short string", () => {
  const res = createResponse();
  handleRequest({ method: "GET", query: { name: "x".repeat(101) } }, res);
  assert.equal(res.statusCode, 400);
});
{%- else %}
const { decodeMessage, handleMessage } = require("../src/handler");

function eventWith(data, attributes) {
  return {
    data: {
      message: {
        messageId: "42",
        attributes,
        data: Buffer.from(data, "utf8").toString("base64"),
      },
    },
  };
}

test("decodes a JSON payload", () => {
  const message = decodeMessage(eventWith('{"orderId":7}', { type: "order.created" }));
  assert.deepEqual(message, {
    id: "42",
    attributes: { type: "order.created" },
    payload: { orderId: 7 },
  });
});

test("keeps a payload that is not JSON as text", () => {
  assert.equal(decodeMessage(eventWith("plain text")).payload, "plain text");
});

test("handles a message without data", () => {
  const message = decodeMessage({ data: { message: { messageId: "1" } } });
  assert.equal(message.payload, "");
  assert.deepEqual(message.attributes, {});
});

test("rejects an event without a message, so it is retried", () => {
  assert.throws(() => handleMessage({ data: {} }), /no Pub\/Sub message/);
});

test("acknowledges a valid message", () => {
  assert.equal(handleMessage(eventWith("{}")), undefined);
});
{%- endif %}
