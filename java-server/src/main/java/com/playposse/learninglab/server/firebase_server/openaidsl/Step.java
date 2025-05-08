package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;

/** A single unit of work in the chain. */
public interface Step {
    CompletableFuture<ChainContext> run(
            ChainContext ctx,
            Executor      executor,
            OpenAiClient  client,
            List<CallLog> logs
    );
}

