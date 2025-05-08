package com.playposse.learninglab.server.firebase_server.openaidsl;

import com.fasterxml.jackson.databind.JsonNode;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;

/**
 * A single chat‐completion “step” that:
 *  1. Builds a prompt (system/user/assistant + optional history),
 *  2. Calls the OpenAI client,
 *  3. Parses the result,
 *  4. Records a CallLog,
 *  5. Returns a new ChainContext with the label bound.
 */
public final class SimpleStep implements Step {

    private final String                   name;
    private final List<MessageTemplate>    templates;
    private final Parser<?>                parser;
    private final Label<?>                 label;
    private final ChatConfig               config;
    private final boolean                  includeHistory;
    private final int                      historyPairs;

    public SimpleStep(
            String name,
            List<MessageTemplate> templates,
            Parser<?> parser,
            Label<?> label,
            ChatConfig config,
            boolean includeHistory,
            int historyPairs
    ) {
        this.name           = name;
        this.templates      = templates;
        this.parser         = parser;
        this.label          = label;
        this.config         = config;
        this.includeHistory = includeHistory;
        this.historyPairs   = historyPairs;
    }

    @Override
    public CompletableFuture<ChainContext> run(
            ChainContext ctx,
            Executor executor,
            OpenAiClient client,
            List<CallLog> logs
    ) {
        return CompletableFuture.supplyAsync(() -> {
            // 1. Prepare messages
            List<ChatMsg> prompt = new ArrayList<>();

            // inject history if desired
            if (includeHistory) {
                List<ChatMsg> hist = ctx.history();
                if (historyPairs != Integer.MAX_VALUE) {
                    int keep = historyPairs * 2;  // pairs → messages
                    hist = hist.subList(Math.max(0, hist.size() - keep), hist.size());
                }
                prompt.addAll(hist);
            }

            // resolve each template through the current context
            Map<String,String> varsMap = TemplateEngine.buildStringMap(ctx);
            for (var tmpl : templates) {
                String txt = TemplateEngine.resolve(tmpl.content(), varsMap);
                prompt.add(new ChatMsg(tmpl.role(), txt));
            }

            CallLog logEntry;
            ChainContext nextCtx = ctx;
            try {
                // 2. Call OpenAI
                ChatCompletionResult res = client.chatCompletion(prompt, config);
                String completion = res.content();
                JsonNode usage     = res.usage();

                // 3. Parse into T
                Object parsed = parser.parse(completion);

                // 4. Append to history & vars
                ChainContext withUser = nextCtx.appendHistory(
                        new ChatMsg(Role.USER, prompt.get(prompt.size()-1).content())
                );
                ChainContext withBoth = withUser.appendHistory(
                        new ChatMsg(Role.ASSISTANT, completion)
                );
                nextCtx = withBoth.plus(label, parsed);

                // 5. Log success
                logEntry = new CallLog(
                        label,
                        prompt,
                        config,
                        completion,
                        usage,
                        null
                );
            } catch (Exception e) {
                // wrap error
                ErrorInfo err = new ErrorInfo(
                        name,
                        /*callId=*/null,
                        e,
                        Instant.now()
                );
                logEntry = new CallLog(
                        label,
                        prompt,
                        config,
                        /*completion=*/null,
                        /*usage=*/null,
                        err
                );
                // surface the error in the context
                nextCtx = nextCtx.plus(label, null);
            }

            logs.add(logEntry);
            return nextCtx;
        }, executor);
    }
}