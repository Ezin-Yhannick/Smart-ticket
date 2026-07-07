package com.sqrcode.sqrcodebackend.controller;

import com.sqrcode.sqrcodebackend.dto.AuthResponse;
import com.sqrcode.sqrcodebackend.dto.LoginRequest;
import com.sqrcode.sqrcodebackend.dto.ProfileUpdateRequest;
import com.sqrcode.sqrcodebackend.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PutMapping("/profile")
    public ResponseEntity<Void> updateProfile(
            @AuthenticationPrincipal String email,
            @Valid @RequestBody ProfileUpdateRequest request) {
        authService.updateProfile(email, request);
        return ResponseEntity.ok().build();
    }

    // Endpoint de test pour vérifier que le serveur tourne
    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        return ResponseEntity.ok("Smart-Ticket API is running!");
    }
}
