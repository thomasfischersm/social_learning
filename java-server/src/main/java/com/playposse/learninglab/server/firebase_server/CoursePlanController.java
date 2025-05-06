package com.playposse.learninglab.server.firebase_server;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class CoursePlanController {

    private final CoursePlanService coursePlanService;

    public CoursePlanController(CoursePlanService coursePlanService) {
        this.coursePlanService = coursePlanService;
    }

    @PostMapping("/generate-course-plan")
    public ResponseEntity<?> generateCoursePlan(
            @RequestHeader(HttpHeaders.AUTHORIZATION) String authorization,
            @RequestBody GenerateCoursePlanRequest request) {
        System.out.println("Received /api/generate-course-plan request from client.");
        try {
            if (authorization == null || !authorization.startsWith("Bearer ")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "Missing or invalid Authorization header"));
            }

            String idToken = authorization.substring(7);
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            String uid = decodedToken.getUid();

            request.uid = uid; // override UID from token, not caller

            coursePlanService.generateCoursePlan(request);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    public static class GenerateCoursePlanRequest {
        public String uid;
        public String coursePlanId;
    }
}
