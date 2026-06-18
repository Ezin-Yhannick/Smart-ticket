// src/main/java/com/sqrcode/sqrcodebackend/controller/AgentController.java
//
// Endpoints REST pour la gestion des agents par un Admin.
//
// Routes :
//   GET    /api/admin/agents        → liste mes agents
//   POST   /api/admin/agents        → créer un agent
//   DELETE /api/admin/agents/{id}   → supprimer un agent
//
// Toutes ces routes nécessitent le rôle ADMIN ou SUPER_ADMIN
// (géré par SecurityConfig)

package com.sqrcode.sqrcodebackend.controller;

import com.sqrcode.sqrcodebackend.dto.AgentResponse;
import com.sqrcode.sqrcodebackend.dto.CreateAgentRequest;
import com.sqrcode.sqrcodebackend.service.AgentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AgentController {

    private final AgentService agentService;

    // ── Liste des agents de l'admin connecté ──
    @GetMapping("/agents")
    public ResponseEntity<List<AgentResponse>> getMyAgents(
            Authentication authentication) {
        // authentication.getName() retourne l'email extrait du JWT
        String adminEmail = authentication.getName();
        return ResponseEntity.ok(
                agentService.getMyAgents(adminEmail));
    }

    // ── Créer un nouvel agent ──
    @PostMapping("/agents")
    public ResponseEntity<AgentResponse> createAgent(
            Authentication authentication,
            @Valid @RequestBody CreateAgentRequest req) {
        String adminEmail = authentication.getName();
        return ResponseEntity.ok(
                agentService.createAgent(adminEmail, req));
    }

    // ── Supprimer un agent ──
    @DeleteMapping("/agents/{id}")
    public ResponseEntity<Void> deleteAgent(
            Authentication authentication,
            @PathVariable Long id) {
        String adminEmail = authentication.getName();
        agentService.deleteAgent(adminEmail, id);
        return ResponseEntity.ok().build();
    }
}