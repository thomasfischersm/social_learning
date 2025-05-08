package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.ArrayList;
import java.util.List;

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

    /** Begin a forEach loop over a list in the context. */
    public <T,R> ForEachBuilder<T,R> forEach(Label<? extends java.util.Collection<T>> sourceLabel) {
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
        private final String stepName;
        private final StepBuilder inner;

        private StepBuilderDSL(String name) {
            this.stepName = name;
            // only now that stepName is set can we build the inner StepBuilder
            this.inner = new StepBuilder(stepName, defaults);
        }

        public StepBuilderDSL system(String msg)     { inner.system(msg); return this; }
        public StepBuilderDSL user(String msg)       { inner.user(msg);   return this; }
        public StepBuilderDSL assistant(String msg)  { inner.assistant(msg); return this; }
        public StepBuilderDSL history()              { inner.history();   return this; }
        public StepBuilderDSL history(int pairs)     { inner.history(pairs); return this; }
        public StepBuilderDSL parse(Parser<?> p)     { inner.parse(p);    return this; }
        public <T> StepBuilderDSL label(Label<T> lbl){ inner.label(lbl);  return this; }

        public StepBuilderDSL model(String m)        { inner.model(m);    return this; }
        public StepBuilderDSL maxTokens(int t)       { inner.maxTokens(t);return this; }
        public StepBuilderDSL temperature(double v)  { inner.temperature(v); return this; }
        public StepBuilderDSL topP(double v)         { inner.topP(v);     return this; }
        public StepBuilderDSL presencePenalty(double v) { inner.presencePenalty(v); return this; }
        public StepBuilderDSL frequencyPenalty(double v){ inner.frequencyPenalty(v); return this; }

        /** End this step and add it to the chain. */
        public ChainBuilder endStep() {
            steps.add(inner.build());
            return ChainBuilder.this;
        }
    }

    // ── forEach DSL ──────────────────────────────────────────────────────────

    public final class ForEachBuilder<T,R> extends ForEachStep.Builder<T,R> {
        private ForEachBuilder(Label<? extends java.util.Collection<T>> source) {
            super(source);
        }

        /** Ends the loop, builds the ForEachStep and adds it to the chain. */
        public ChainBuilder endForEach() {
            steps.add(this.build());
            return ChainBuilder.this;
        }
    }

    // ── parallel DSL ─────────────────────────────────────────────────────────

    public final class ParallelBuilder extends ParallelStep.Builder {
        private ParallelBuilder() { }

        /** Ends the parallel block, builds the ParallelStep and adds it. */
        public ChainBuilder endParallel() {
            steps.add(this.build());
            return ChainBuilder.this;
        }
    }
}
