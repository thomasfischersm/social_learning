package com.playposse.learninglab.server.firebase_server.openaidsl;

import com.fasterxml.jackson.databind.JsonNode;

/** Raw result from the client with text and usage info. */
public record ChatCompletionResult(String content, JsonNode usage) {}