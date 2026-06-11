// src/main/java/com/sqrcode/sqrcodebackend/controller/SuperAdminController.java
package com.sqrcode.sqrcodebackend.controller;

import com.sqrcode.sqrcodebackend.dto.*;
import com.sqrcode.sqrcodebackend.service.SuperAdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/super-admin")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SuperAdminController {

    private final SuperAdminService superAdminService;

    // Stats globales
    @GetMapping("/stats")
    public ResponseEntity<PlatformStatsResponse> getStats() {
        return ResponseEntity.ok(superAdminService.getPlatformStats());
    }

    // Liste des admins
    @GetMapping("/admins")
    public ResponseEntity<List<AdminUserResponse>> getAdmins() {
        return ResponseEntity.ok(superAdminService.getAllAdmins());
    }

    // Créer un admin
    @PostMapping("/admins")
    public ResponseEntity<AdminUserResponse> createAdmin(
            @Valid @RequestBody CreateAdminRequest req) {
        return ResponseEntity.ok(superAdminService.createAdmin(req));
    }

    // Suspendre
    @PutMapping("/admins/{id}/suspend")
    public ResponseEntity<Void> suspend(@PathVariable Long id) {
        superAdminService.suspendAdmin(id);
        return ResponseEntity.ok().build();
    }

    // Activer
    @PutMapping("/admins/{id}/activate")
    public ResponseEntity<Void> activate(@PathVariable Long id) {
        superAdminService.activateAdmin(id);
        return ResponseEntity.ok().build();
    }

    // Supprimer
    @DeleteMapping("/admins/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        superAdminService.deleteAdmin(id);
        return ResponseEntity.ok().build();
    }
}