package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.List;
import com.fasterxml.jackson.databind.JsonNode;

/**
 * A record of one completed OpenAI call, including prompt, response, and usage.
 *
 * @param label      the label under which this call's result is stored
 * @param prompt     the exact list of messages sent (roles preserved)
 * @param config     the ChatConfig used for this call
 * @param completion the raw assistant reply (null if error)
 * @param usage      token usage metrics as JSON (null if unavailable)
 * @param error      ErrorInfo if the call failed (null if success)
 */
public record CallLog(
        Label<?> label,
        List<ChatMsg> prompt,
        ChatConfig config,
        String completion,
        JsonNode usage,
        ErrorInfo error
) {}

