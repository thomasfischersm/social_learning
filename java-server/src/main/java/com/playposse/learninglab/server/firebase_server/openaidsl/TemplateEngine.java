package com.playposse.learninglab.server.firebase_server.openaidsl;

import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Simple template engine for resolving placeholders of the form ${key}
 * within strings, using values from a context map.
 */
public final class TemplateEngine {
    private static final Pattern VAR_PATTERN = Pattern.compile("\\$\\{([^}]+)}");

    private TemplateEngine() {
        // static helper
    }

    /**
     * Resolves all placeholders in the input text by looking up each key in vars.
     * Placeholders with no matching entry are left unchanged.
     *
     * @param text the input containing zero or more ${key} expressions
     * @param vars a map from placeholder names to their String values
     * @return the text with substitutions applied
     */
    public static String resolve(String text, Map<String,String> vars) {
        Matcher m = VAR_PATTERN.matcher(text);
        StringBuffer sb = new StringBuffer();
        while (m.find()) {
            String key = m.group(1);
            String replacement = vars.getOrDefault(key, m.group(0));
            // escape backslashes and dollars in replacement
            replacement = replacement.replace("\\\\", "\\\\\\\\").replace("$", "\\$");
            m.appendReplacement(sb, replacement);
        }
        m.appendTail(sb);
        return sb.toString();
    }

    /**
     * Builds a flat map of String→String from the ChainContext's vars,
     * converting values via toString().  Also injects any loop alias under name 'item'.
     */
    public static Map<String,String> buildStringMap(ChainContext ctx) {
        Map<String,String> map = new java.util.HashMap<>();
        for (Map.Entry<Label<?>, Object> entry : ctx.vars().entrySet()) {
            map.put(entry.getKey().name(), entry.getValue().toString());
        }
        return map;
    }
}
