// src/main/java/com/sqrcode/sqrcodebackend/controller/ScanController.java
package com.sqrcode.sqrcodebackend.controller;

import com.sqrcode.sqrcodebackend.dto.ScanResponse;
import com.sqrcode.sqrcodebackend.service.ScanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/scan")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ScanController {

    private final ScanService scanService;

    @PostMapping
    public ResponseEntity<ScanResponse> scan(
            @RequestBody Map<String, String> body,
            Authentication authentication) {

        String uuid = body.get("uuid");

        // AJOUTE CES LIGNES TEMPORAIREMENT
        System.out.println("=== DEBUG SCAN ===");
        System.out.println("UUID reçu : [" + uuid + "]");
        System.out.println("Longueur : " + (uuid != null ? uuid.length() : "null"));
        System.out.println("==================");

        String eventId = body.get("eventId");
        String agentEmail = authentication.getName();

        return ResponseEntity.ok(
                scanService.scan(uuid, agentEmail, eventId));
    }
}