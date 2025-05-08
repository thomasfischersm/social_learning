package com.playposse.learninglab.server.firebase_server.openaidsl;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Describes one callable function for the model’s function‐calling feature.
 */
public record FunctionSchema(
        String       name,
        String       description,
        JsonNode     parameters  // JSON schema: properties, required, types, etc.
) {
    public static FunctionSchema of(
            String name,
            String description,
            JsonNode jsonSchema
    ) {
        return new FunctionSchema(name, description, jsonSchema);
    }
}