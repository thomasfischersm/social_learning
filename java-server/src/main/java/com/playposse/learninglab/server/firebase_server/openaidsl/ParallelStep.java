package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;

/**
 * A Step that runs several independent sub-steps (branches) in parallel,
 * then joins each branch’s result into a single Map under one label.
 */
public final class ParallelStep implements Step {

    private final LinkedHashMap<String, SimpleStep> branches;
    private final Label<Map<String, Object>> joinLabel;

    private ParallelStep(
            LinkedHashMap<String, SimpleStep> branches,
            Label<Map<String, Object>> joinLabel
    ) {
        this.branches  = new LinkedHashMap<>(branches);
        this.joinLabel = joinLabel;
    }

    @Override
    public CompletableFuture<ChainContext> run(
            ChainContext ctx,
            Executor executor,
            OpenAiClient client,
            List<CallLog> logs
    ) {
        // Fire off each branch’s SimpleStep in parallel
        List<CompletableFuture<BranchOutcome>> futures = new ArrayList<>();
        for (var entry : branches.entrySet()) {
            String name = entry.getKey();
            SimpleStep step = entry.getValue();

            // fork context so history/config aren’t shared across branches
            ChainContext branchCtx = ctx.fork();

            CompletableFuture<BranchOutcome> cf = step
                    .run(branchCtx, executor, client, logs)
                    .thenApply(brCtx -> new BranchOutcome(name, brCtx));
            futures.add(cf);
        }

        // Join all branches, collecting each branch’s labeled value into a Map
        return CompletableFuture
                .allOf(futures.toArray(CompletableFuture[]::new))
                .thenApply(__ -> {
                    Map<String, Object> resultMap = new LinkedHashMap<>();
                    for (var cf : futures) {
                        BranchOutcome outcome = cf.join();
                        ChainContext brCtx = outcome.context();
                        // assume each branch’s SimpleStep wrote exactly one value under its own label
                        // we find that label by looking at the last CallLog entry for this branch
                        Label<?> lbl = outcome.context()
                                .history()   // hack: not ideal, but we need step’s label
                                .stream()
                                .filter(m -> m.role() == Role.SYSTEM) // no reliable signal
                                .findFirst()
                                .map(m -> joinLabel) // fallback if we can’t detect
                                .orElse(joinLabel);

                        // Instead, we require the branch step to use the same joinLabel internally:
                        Object branchValue = brCtx.get(joinLabel);
                        resultMap.put(outcome.branchName(), branchValue);
                    }
                    // attach the map under joinLabel in the parent context
                    return ctx.plus(joinLabel, resultMap);
                });
    }

    /** Builder for a ParallelStep. */
    public static class Builder {
        protected final LinkedHashMap<String, SimpleStep> branches = new LinkedHashMap<>();
        protected Label<Map<String, Object>> joinLabel;

        /** Add a branch: its name and the single SimpleStep it should run. */
        public Builder branch(String name, SimpleStep step) {
            branches.put(name, step);
            return this;
        }

        /**
         * After all branches complete, collect each branch’s
         * value under this label (a Map&lt;branchName, value&gt;).
         */
        public Builder joinInto(Label<Map<String, Object>> joinLabel) {
            this.joinLabel = joinLabel;
            return this;
        }

        public ParallelStep build() {
            if (branches.isEmpty()) {
                throw new IllegalStateException("At least one branch required");
            }
            if (joinLabel == null) {
                throw new IllegalStateException("joinInto(...) must be called");
            }
            return new ParallelStep(branches, joinLabel);
        }
    }

    /** Internal helper pairing a branch name with its completed context. */
    private record BranchOutcome(String branchName, ChainContext context) {}
}