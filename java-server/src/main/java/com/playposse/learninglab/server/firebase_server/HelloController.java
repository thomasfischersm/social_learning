package com.playposse.learninglab.server.firebase_server;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @Autowired
    private OpenAiService openAiService;

    @GetMapping("/ask")
    public String ask(@RequestParam(defaultValue = "Tell me a joke") String prompt) throws Exception {
        return openAiService.askChatGPT(prompt);
    }
    @GetMapping("/hello")
    public String hello() {
        return "Hello from Learning Lab server!";
    }
}
