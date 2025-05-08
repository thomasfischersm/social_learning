package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.List;

/** Minimal interface to your OpenAI wrapper. */
public interface OpenAiClient {
    ChatCompletionResult chatCompletion(List<ChatMsg> messages, ChatConfig config)
            throws Exception;
}