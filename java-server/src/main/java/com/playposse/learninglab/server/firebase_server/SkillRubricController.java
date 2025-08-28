package com.playposse.learninglab.server.firebase_server;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * REST endpoint for generating skill rubrics using OpenAI.
 */
@RestController
@RequestMapping("/api")
public class SkillRubricController {

    private final SkillRubricService skillRubricService;

    public SkillRubricController(SkillRubricService skillRubricService) {
        this.skillRubricService = skillRubricService;
    }

    @PostMapping("/generate-skill-rubric")
    public ResponseEntity<?> generateSkillRubric(
            @RequestHeader(HttpHeaders.AUTHORIZATION) String authorization,
            @RequestBody GenerateSkillRubricRequest request) {
        try {
            if (authorization == null || !authorization.startsWith("Bearer ")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "Missing or invalid Authorization header"));
            }

            String idToken = authorization.substring(7);
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            request.uid = decodedToken.getUid();

            SkillRubricResponse result = skillRubricService.generateRubric(request);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}
