// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/FakeOpenAiClient.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Returns canned or prefixed responses based on the user message text.
 */
public class FakeOpenAiClient implements OpenAiClient {

    // map snippet -> "reply" or "prefix-"
    private final Map<String,String> responses = new ConcurrentHashMap<>();

    /** Pre-load a static or prefix reply. */
    public void whenContains(String snippet, String replyOrPrefix) {
        responses.put(snippet, replyOrPrefix);
    }

    @Override
    public ChatCompletionResult chatCompletion(List<ChatMsg> messages, ChatConfig cfg) {
        String user = messages.stream()
                .filter(m -> m.role() == Role.USER)
                .reduce((first, second) -> second)
                .map(ChatMsg::content)
                .orElse("");

        for (var entry : responses.entrySet()) {
            String key    = entry.getKey();
            String value  = entry.getValue();
            if (user.contains(key)) {
                // build fake usage
                JsonNode usage = JsonNodeFactory.instance.objectNode()
                        .put("prompt_tokens", 1)
                        .put("completion_tokens", value.length());

                if (value.endsWith("-")) {
                    // dynamic prefix: grab whatever follows the key in the prompt
                    String suffix = user.substring(user.indexOf(key) + key.length()).trim();
                    return new ChatCompletionResult(value + suffix, usage);
                } else {
                    // static reply
                    return new ChatCompletionResult(value, usage);
                }
            }
        }

        throw new IllegalStateException("No stubbed response for: " + user);
    }
}
