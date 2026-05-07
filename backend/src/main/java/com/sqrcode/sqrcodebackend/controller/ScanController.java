// src/main/java/com/sqrcode/sqrcodebackend/controller/ScanController.java
package com.sqrcode.sqrcodebackend.controller;

import com.sqrcode.sqrcodebackend.dto.ScanResponse;
import com.sqrcode.sqrcodebackend.service.ScanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/scan")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ScanController {

    private final ScanService scanService;

    @PostMapping
    public ResponseEntity<ScanResponse> scan(
            @RequestParam String uuid,
            @AuthenticationPrincipal String agentEmail) {

        return ResponseEntity.ok(scanService.scan(uuid, agentEmail));
    }
}