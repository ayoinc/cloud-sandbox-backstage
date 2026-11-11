"use strict";
{% if values.triggerType == "http" %}
const ALLOWED_METHODS = ["GET", "POST"];

/** Writes one structured log entry; Cloud Logging reads the severity. */
function log(severity, message, fields = {}) {
  console.log(JSON.stringify({ severity, message, ...fields }));
}

/**
 * Greets the caller named in the query string or the JSON body.
 *
 * @param {import("@google-cloud/functions-framework").Request} req
 * @param {import("@google-cloud/functions-framework").Response} res
 */
function handleRequest(req, res) {
  if (!ALLOWED_METHODS.includes(req.method)) {
    res.set("Allow", ALLOWED_METHODS.join(", "));
    res.status(405).json({ error: "Method not allowed" });
    return;
  }

  const name = (req.query && req.query.name) || (req.body && req.body.name) || "world";
  if (typeof name !== "string" || name.length > 100) {
    res.status(400).json({ error: "name must be a string of at most 100 characters" });
    return;
  }

  log("INFO", "Request handled", { method: req.method });
  res.status(200).json({
    message: `Hello, ${name}!`,
    environment: process.env.APP_ENVIRONMENT || "local",
  });
}

module.exports = { handleRequest };
{%- else %}
/** Writes one structured log entry; Cloud Logging reads the severity. */
function log(severity, message, fields = {}) {
  console.log(JSON.stringify({ severity, message, ...fields }));
}

/**
 * Extracts the Pub/Sub message from a CloudEvent. The payload is parsed as
 * JSON when it is JSON, and returned as text otherwise.
 *
 * @param {import("@google-cloud/functions-framework").CloudEvent<{ message?: { data?: string, messageId?: string, attributes?: Record<string, string> } }>} cloudEvent
 */
function decodeMessage(cloudEvent) {
  const message = cloudEvent && cloudEvent.data && cloudEvent.data.message;
  if (!message) {
    throw new Error("The event carries no Pub/Sub message");
  }

  const text = message.data ? Buffer.from(message.data, "base64").toString("utf8") : "";
  let payload = text;
  try {
    payload = JSON.parse(text);
  } catch {
    // Not JSON: keep the text.
  }

  return { id: message.messageId, attributes: message.attributes || {}, payload };
}

/**
 * Handles one message. Returning acknowledges it; throwing makes Pub/Sub
 * deliver it again, so the work done here must be safe to repeat.
 */
function handleMessage(cloudEvent) {
  const { id, attributes, payload } = decodeMessage(cloudEvent);
  log("INFO", "Message received", {
    messageId: id,
    attributes,
    payloadType: typeof payload,
  });
}

module.exports = { decodeMessage, handleMessage };
{%- endif %}
