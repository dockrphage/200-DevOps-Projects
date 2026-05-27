// src/main/java/com/devops/demo/ScoreController.java
package com.devops.demo;

import org.springframework.web.bind.annotation.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/scores")
public class ScoreController {
    
    private Map<String, Integer> scores = new ConcurrentHashMap<>();
    
    @GetMapping
    public Map<String, Integer> getAllScores() {
        return scores;
    }
    
    @PostMapping("/{player}")
    public String addScore(@PathVariable String player, @RequestParam int score) {
        scores.put(player, scores.getOrDefault(player, 0) + score);
        return "Score added for " + player + ". Total: " + scores.get(player);
    }
    
    @GetMapping("/health")
    public String health() {
        return "OK";
    }
    
    @GetMapping("/info")
    public Map<String, String> info() {
        return Map.of(
            "version", System.getProperty("app.version", "1.0.0"),
            "environment", System.getProperty("spring.profiles.active", "default"),
            "hostname", System.getenv().getOrDefault("HOSTNAME", "unknown")
        );
    }
}
