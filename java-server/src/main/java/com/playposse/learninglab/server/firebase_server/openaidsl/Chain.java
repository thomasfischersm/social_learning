package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Executes a list of Steps in serial order, passing a shared context
 * and collecting values into a ChainResult.
 */
public final class Chain {

    private final List<Step> steps;
    private final ChatConfig defaults;

    /**
     * @param steps    Ordered list of steps to execute.
     * @param defaults Initial chat config applied to every step.
     */
    public Chain(List<Step> steps, ChatConfig defaults) {
        this.steps = List.copyOf(steps);
        this.defaults = defaults;
    }

    /**
     * Runs all steps in sequence and returns the result. Blocks until complete.
     *
     * @param client OpenAI client implementation.
     * @return Immutable ChainResult with final values (errors empty for now).
     */
    public ChainResult run(OpenAiClient client) {
        // Use virtual threads so each step’s blocking call doesn’t starve
        ExecutorService exec = Executors.newVirtualThreadPerTaskExecutor();
        try {
            // Initial context: no vars, empty history, default config
            ChainContext ctx0 = ChainContext.root(defaults);
            List<CallLog> logs = Collections.synchronizedList(new ArrayList<>());
            CompletableFuture<ChainContext> cf = CompletableFuture.completedFuture(ctx0);

            // Chain the steps serially
            for (Step step : steps) {
                cf = cf.thenCompose(ctx -> step.run(ctx, exec, client, logs));
            }

            ChainContext finalCtx = cf.join();
            // Minimal result: only values (errors and callLogs not exposed yet)
            return new ChainResultImpl(finalCtx.vars(), logs);
        } finally {
            exec.close();
        }
    }
}