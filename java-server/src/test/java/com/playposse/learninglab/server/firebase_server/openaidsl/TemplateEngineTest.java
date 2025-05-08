// src/test/java/com/playposse/learninglab/server/firebase_server/openaidsl/TemplateEngineTest.java
package com.playposse.learninglab.server.firebase_server.openaidsl;

import static org.junit.jupiter.api.Assertions.*;

import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class TemplateEngineTest {

    private ChainContext baseCtx;

    @BeforeEach
    void setUp() {
        // We only need the vars map; history and config are irrelevant here.
        baseCtx = ChainContext
                .root(new DefaultsBuilder().build())
                .plus(Label.of("foo", String.class), "FOO")
                .plus(Label.of("num", Integer.class), 42);
    }

    @Test
    void testResolveSimplePlaceholder() {
        String template = "Value=${foo}";
        Map<String, String> vars = TemplateEngine.buildStringMap(baseCtx);
        String result = TemplateEngine.resolve(template, vars);
        assertEquals("Value=FOO", result);
    }

    @Test
    void testResolveMultiplePlaceholders() {
        String template = "Foo=${foo},Num=${num}";
        Map<String, String> vars = TemplateEngine.buildStringMap(baseCtx);
        String result = TemplateEngine.resolve(template, vars);
        assertEquals("Foo=FOO,Num=42", result);
    }

    @Test
    void testResolveMissingPlaceholderLeavesIntact() {
        String template = "Hello ${missing}!";
        Map<String, String> vars = TemplateEngine.buildStringMap(baseCtx);
        String result = TemplateEngine.resolve(template, vars);
        assertEquals("Hello ${missing}!", result);
    }

    @Test
    void testResolveEscapesDollarAndBackslashInValues() {
        // Insert a var whose toString includes $ and \
        Label<String> special = Label.of("sp", String.class);
        ChainContext ctx = baseCtx.plus(special, "X$Y\\Z");
        Map<String, String> vars = TemplateEngine.buildStringMap(ctx);

        String template = "Path=${sp}";
        String result = TemplateEngine.resolve(template, vars);
        // Should substitute literally, not treat $Y as group or break on backslash
        assertEquals("Path=X$Y\\Z", result);
    }

    @Test
    void testBuildStringMapIncludesAllVars() {
        Map<String, String> map = TemplateEngine.buildStringMap(baseCtx);
        assertEquals(2, map.size());
        assertEquals("FOO", map.get("foo"));
        assertEquals("42",  map.get("num"));
    }
}
