package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * Fluent builder for a Chain.  Supports serial steps, forEach loops, and parallel branches.
 */
public final class ChainBuilder {

    private final List<Step> steps = new ArrayList<>();
    private final ChatConfig defaults;

    private ChainBuilder(ChatConfig defaults) {
        this.defaults = defaults;
    }

    /** Start a new ChainBuilder with the given global defaults. */
    public static ChainBuilder start(ChatConfig defaults) {
        return new ChainBuilder(defaults);
    }

    /** Begin a serial chat‐completion step. */
    public StepBuilderDSL step(String name) {
        return new StepBuilderDSL(name);
    }

    /** Begin a forEach loop over a list in the context (infers element type T). */
    public <T> ForEachBuilder<T> forEach(Label<? extends Collection<T>> sourceLabel) {
        return new ForEachBuilder<>(sourceLabel);
    }

    /** Begin a parallel block of named branches. */
    public ParallelBuilder parallel() {
        return new ParallelBuilder();
    }

    /** Finalize the builder and get a Chain you can run. */
    public Chain build() {
        return new Chain(steps, defaults);
    }

    // ── Serial step DSL ──────────────────────────────────────────────────────

    public final class StepBuilderDSL {
        private final StepBuilder inner;

        StepBuilderDSL(String name) {
            this.inner = new StepBuilder(name, defaults);
        }

        public StepBuilderDSL system(String msg)         { inner.system(msg); return this; }
        public StepBuilderDSL user(String msg)           { inner.user(msg);   return this; }
        public StepBuilderDSL assistant(String msg)      { inner.assistant(msg); return this; }
        public StepBuilderDSL history()                  { inner.history();   return this; }
        public StepBuilderDSL history(int pairs)         { inner.history(pairs); return this; }
        public StepBuilderDSL parse(Parser<?> p)         { inner.parse(p);    return this; }
        public <T> StepBuilderDSL label(Label<T> lbl)    { inner.label(lbl);  return this; }
        public StepBuilderDSL model(String m)            { inner.model(m);    return this; }
        public StepBuilderDSL maxTokens(int t)           { inner.maxTokens(t);return this; }
        public StepBuilderDSL temperature(double v)      { inner.temperature(v); return this; }
        public StepBuilderDSL topP(double v)             { inner.topP(v);     return this; }
        public StepBuilderDSL presencePenalty(double v)  { inner.presencePenalty(v); return this; }
        public StepBuilderDSL frequencyPenalty(double v) { inner.frequencyPenalty(v); return this; }

        /** End this step and add it to the chain. */
        public ChainBuilder endStep() {
            steps.add(inner.build());
            return ChainBuilder.this;
        }
    }

    // ── forEach DSL ──────────────────────────────────────────────────────────

    public final class ForEachBuilder<T> {
        private final Label<? extends Collection<T>> sourceLabel;
        private String alias        = "item";
        private int    maxElements  = 100;
        private final List<Step> subSteps = new ArrayList<>();
        private Label<? extends List<?>> joinLabel;

        private ForEachBuilder(Label<? extends Collection<T>> sourceLabel) {
            this.sourceLabel = sourceLabel;
        }

        /** Name to use in prompts for the current element (default "item"). */
        public ForEachBuilder<T> alias(String alias) {
            this.alias = alias;
            return this;
        }

        /** Cap on the number of items to process (default 100). */
        public ForEachBuilder<T> maxElements(int cap) {
            this.maxElements = cap;
            return this;
        }

        /** Add one Step (e.g. a SimpleStep) to run for each item. */
        public ForEachBuilder<T> addStep(Step step) {
            this.subSteps.add(step);
            return this;
        }

        /**
         * After the loop, join all branch outputs under this label.
         * The R element type is inferred from the Label<List<R>> you pass in.
         */
        public <R> ForEachBuilder<T> joinInto(Label<List<R>> joinLabel) {
            this.joinLabel = joinLabel;
            return this;
        }

        /**
         * Ends the loop, builds the ForEachStep and adds it to the chain.
         * Must have called joinInto(...) first.
         */
        @SuppressWarnings({"unchecked", "rawtypes"})
        public ChainBuilder endForEach() {
            if (joinLabel == null) {
                throw new IllegalStateException("Must call joinInto(...) before endForEach()");
            }

            // Use the public builder API on ForEachStep instead of calling constructor
            ForEachStep.Builder builder = ForEachStep.builder(sourceLabel);
            builder.alias(alias);
            builder.maxElements(maxElements);
            for (Step step : subSteps) {
                builder.addStep(step);
            }
            builder.joinInto((Label) joinLabel);

            steps.add(builder.build());
            return ChainBuilder.this;
        }
    }

    // ── parallel DSL ─────────────────────────────────────────────────────────

    public final class ParallelBuilder extends ParallelStep.Builder {
        private ParallelBuilder() { }

        @Override
        public ParallelBuilder branch(String name, SimpleStep step) {
            super.branch(name, step);
            return this;
        }

        @Override
        public ParallelBuilder joinInto(Label<Map<String,Object>> jl) {
            super.joinInto(jl);
            return this;
        }

        @Override
        public ParallelStep build() {
            if (joinLabel == null) {
                SimpleStep first = branches.values().iterator().next();
                @SuppressWarnings("unchecked")
                Label<Map<String,Object>> inferred =
                        (Label<Map<String,Object>>) first.getLabel();
                super.joinInto(inferred);
            }
            return super.build();
        }

        public ChainBuilder endParallel() {
            steps.add(this.build());
            return ChainBuilder.this;
        }
    }
}
