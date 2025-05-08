// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/HistoryInjectionTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class HistoryInjectionTest {

    private ChatConfig      defaults;
    private FakeOpenAiClient fakeClient;

    @BeforeEach
    void setUp() {
        defaults   = new DefaultsBuilder().build();
        fakeClient = new FakeOpenAiClient();
    }

    @Test
    void testFullHistoryInjection() {
        // Stub step0 and step1 replies
        fakeClient.whenContains("first",  "out0");
        fakeClient.whenContains("second", "out1");

        Label<String> L0 = Label.of("step0", String.class);
        Label<String> L1 = Label.of("step1", String.class);

        Chain chain = ChainBuilder
                .start(defaults)
                // step0: no history
                .step("step0")
                .user("first")
                .parse(Parsers.string())
                .label(L0)
                .endStep()
                // step1: inject full history
                .step("step1")
                .history()
                .user("second")
                .parse(Parsers.string())
                .label(L1)
                .endStep()
                .build();

        ChainResult result = chain.run(fakeClient);
        List<CallLog> logs = result.callLogs();
        assertEquals(2, logs.size());

        // Inspect callLogs[1].prompt: should contain
        // [ USER:first, ASSISTANT:out0, USER:second ]
        List<ChatMsg> prompt1 = logs.get(1).prompt();

        assertEquals(3, prompt1.size(), "Full history + new prompt");

        assertEquals(Role.USER,      prompt1.get(0).role());
        assertEquals("first",        prompt1.get(0).content());

        assertEquals(Role.ASSISTANT, prompt1.get(1).role());
        assertEquals("out0",         prompt1.get(1).content());

        assertEquals(Role.USER,      prompt1.get(2).role());
        assertEquals("second",       prompt1.get(2).content());
    }

    @Test
    void testLimitedHistoryInjection() {
        // Stub step0, step1, step2 replies
        fakeClient.whenContains("a", "A");
        fakeClient.whenContains("b", "B");
        fakeClient.whenContains("c", "C");

        Label<String> L0 = Label.of("step0", String.class);
        Label<String> L1 = Label.of("step1", String.class);
        Label<String> L2 = Label.of("step2", String.class);

        Chain chain = ChainBuilder
                .start(defaults)
                // step0
                .step("step0")
                .user("a")
                .parse(Parsers.string())
                .label(L0)
                .endStep()
                // step1
                .step("step1")
                .user("b")
                .parse(Parsers.string())
                .label(L1)
                .endStep()
                // step2: history(1) -> only last pair from step1
                .step("step2")
                .history(1)
                .user("c")
                .parse(Parsers.string())
                .label(L2)
                .endStep()
                .build();

        ChainResult result = chain.run(fakeClient);
        List<CallLog> logs = result.callLogs();
        assertEquals(3, logs.size());

        // Inspect callLogs[2].prompt: should contain
        // [ USER:b, ASSISTANT:B, USER:c ]
        List<ChatMsg> prompt2 = logs.get(2).prompt();

        assertEquals(3, prompt2.size(), "Only last 1 pair + new prompt");

        assertEquals(Role.USER,      prompt2.get(0).role());
        assertEquals("b",            prompt2.get(0).content());

        assertEquals(Role.ASSISTANT, prompt2.get(1).role());
        assertEquals("B",            prompt2.get(1).content());

        assertEquals(Role.USER,      prompt2.get(2).role());
        assertEquals("c",            prompt2.get(2).content());
    }
}
