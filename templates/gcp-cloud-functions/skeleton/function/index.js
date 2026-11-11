"use strict";

const functions = require("@google-cloud/functions-framework");
{%- if values.triggerType == "http" %}
const { handleRequest } = require("./src/handler");

// The name registered here is the entry point of the function (entry_point).
functions.http("handler", handleRequest);
{%- else %}
const { handleMessage } = require("./src/handler");

// The name registered here is the entry point of the function (entry_point).
functions.cloudEvent("handler", handleMessage);
{%- endif %}
