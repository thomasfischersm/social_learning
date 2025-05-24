package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import java.util.List;

/**
 * A Step that fans out over a collection from a previous label,
 * runs the same sub-chain for each item (in parallel), then
 * joins all results into one List under the given joinLabel.
 * <p>
 * If the source list is longer than maxElements, it is
 * quietly truncated to that cap, and an ErrorInfo is
 * recorded on the joinLabel to note how many items were dropped.
 */
public final class ForEachStep<T, R> implements Step {

    private final Label<? extends Collection<T>> sourceLabel;
    private final String alias;                         // placeholder name
    private final List<Step> subSteps;                  // the sub-chain to run per item
    private final int maxElements;
    private final Label<List<R>> joinLabel;             // where to store the List<R>

    private ForEachStep(
            Label<? extends Collection<T>> sourceLabel,
            String alias,
            List<Step> subSteps,
            int maxElements,
            Label<List<R>> joinLabel
    ) {
        this.sourceLabel = sourceLabel;
        this.alias = alias;
        this.subSteps = List.copyOf(subSteps);
        this.maxElements = maxElements;
        this.joinLabel = joinLabel;
    }

    @Override
    public CompletableFuture<ChainContext> run(
            ChainContext ctx,
            Executor executor,
            OpenAiClient client,
            List<CallLog> logs
    ) {
        // 1) Fetch and cap the source list
        Collection<T> raw = ctx.get(sourceLabel);
        List<T> items = new ArrayList<>(raw);
        if (items.size() > maxElements) {
            int dropped = items.size() - maxElements;
            items = items.subList(0, maxElements);
            ErrorInfo err = new ErrorInfo(
                    "forEach(" + sourceLabel.name() + ")",
                    null,
                    new IllegalArgumentException(
                            "Truncated " + dropped + " items down to cap of " + maxElements
                    ),
                    Instant.now()
            );
            logs.add(new CallLog(joinLabel, List.of(), null, null, null, err, 0));
        }

        // 2) Fan out each item
        List<CompletableFuture<ChainContext>> futures = new ArrayList<>();
        for (T item : items) {
            // fork + inject loop variable
            Label<T> aliasLabel = Label.of(alias, (Class<T>) item.getClass());
            ChainContext branchCtx = ctx.fork().plus(aliasLabel, item);

            CompletableFuture<ChainContext> cf = CompletableFuture.completedFuture(branchCtx);
            for (Step step : subSteps) {
                cf = cf.thenCompose(c -> step.run(c, executor, client, logs));
            }
            futures.add(cf);
        }

        // 3) Join: extract each branch’s single new label (the sub-step output),
        //    collect its value, and bind the list under joinLabel.
        return CompletableFuture
                .allOf(futures.toArray(new CompletableFuture[0]))
                .thenApply(_void -> {
                    List<R> collected = new ArrayList<>(futures.size());
                    for (var f : futures) {
                        ChainContext brCtx = f.join();
                        // find the one label in branch context that is neither
                        // the sourceLabel nor the aliasLabel
                        Label<?> outputLabel = brCtx.vars().keySet().stream()
                                .filter(lbl -> !lbl.equals(sourceLabel))
                                .filter(lbl -> !lbl.name().equals(alias))
                                .reduce((a, b) -> {
                                    throw new IllegalStateException(
                                            "Expected exactly one output label, but found: "
                                                    + brCtx.vars().keySet());
                                })
                                .orElseThrow(() -> new IllegalStateException(
                                        "No output label found in branch for " + sourceLabel.name()
                                ));

                        @SuppressWarnings("unchecked")
                        R out = (R) brCtx.get((Label<R>) outputLabel);
                        collected.add(out);
                    }

                    return ctx.plus(joinLabel, collected);
                });
    }

    /**
     * Entry point for fluent construction of a ForEachStep.
     */
    public static <T, R> Builder<T, R> builder(
            Label<? extends Collection<T>> sourceLabel
    ) {
        return new Builder<>(sourceLabel);
    }

    /**
     * Builder sugar for ForEachStep.
     */
    public static class Builder<T, R> {
        private final Label<? extends Collection<T>> sourceLabel;
        private String alias = "item";
        private final List<Step> subSteps = new ArrayList<>();
        private int maxElements = 100;
        private Label<List<R>> joinLabel;

        protected Builder(Label<? extends Collection<T>> sourceLabel) {
            this.sourceLabel = sourceLabel;
        }

        /**
         * Name to use in prompts for the current element (default `"item"`).
         */
        public Builder<T, R> alias(String alias) {
            this.alias = alias;
            return this;
        }

        /**
         * Cap on the number of items to process (default 100).
         */
        public Builder<T, R> maxElements(int cap) {
            this.maxElements = cap;
            return this;
        }

        /**
         * Add one Step (e.g. a SimpleStep) to run for each item.
         */
        public Builder<T, R> addStep(Step step) {
            this.subSteps.add(step);
            return this;
        }

        /**
         * After the loop, join all branch outputs under this label.
         * The subSteps must each write a value to this same label.
         */
        public Builder<T, R> joinInto(Label<List<R>> joinLabel) {
            this.joinLabel = joinLabel;
            return this;
        }

        /**
         * Build the ForEachStep.
         */
        public ForEachStep<T, R> build() {
            Objects.requireNonNull(joinLabel, "Must call joinInto(...)");
            if (subSteps.isEmpty()) {
                throw new IllegalStateException("Must add at least one step");
            }
            return new ForEachStep<>(
                    sourceLabel, alias, subSteps, maxElements, joinLabel
            );
        }
    }
}