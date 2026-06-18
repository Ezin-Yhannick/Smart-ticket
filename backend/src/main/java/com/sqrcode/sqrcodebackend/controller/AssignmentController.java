// src/main/java/com/sqrcode/sqrcodebackend/controller/AssignmentController.java
//
// Endpoints pour gérer l'assignation des agents aux événements.
//
// Routes Admin :
//   POST   /api/admin/events/{eventId}/assign          → assigner des agents
//   DELETE /api/admin/events/{eventId}/agents/{agentId} → désassigner
//   GET    /api/admin/events/{eventId}/agents           → liste agents assignés
//
// Route Agent :
//   GET    /api/agent/my-events → événements de l'agent connecté

package com.sqrcode.sqrcodebackend.controller;

import com.sqrcode.sqrcodebackend.dto.AgentResponse;
import com.sqrcode.sqrcodebackend.dto.AssignAgentsRequest;
import com.sqrcode.sqrcodebackend.entity.Event;
import com.sqrcode.sqrcodebackend.service.AssignmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AssignmentController {

    private final AssignmentService assignmentService;

    // ── Assigne des agents à un événement ──
    // Body : { "agentIds": [1, 3, 5] }
    @PostMapping("/api/admin/events/{eventId}/assign")
    public ResponseEntity<Map<String, String>> assignAgents(
            Authentication authentication,
            @PathVariable Long eventId,
            @RequestBody AssignAgentsRequest req) {

        assignmentService.assignAgents(
                authentication.getName(),
                eventId,
                req
        );
        return ResponseEntity.ok(
                Map.of("message", "Agents assignés avec succès"));
    }

    // ── Désassigne un agent d'un événement ──
    @DeleteMapping("/api/admin/events/{eventId}/agents/{agentId}")
    public ResponseEntity<Void> unassignAgent(
            Authentication authentication,
            @PathVariable Long eventId,
            @PathVariable Long agentId) {

        assignmentService.unassignAgent(
                authentication.getName(),
                eventId,
                agentId
        );
        return ResponseEntity.ok().build();
    }

    // ── Liste des agents assignés à un événement ──
    @GetMapping("/api/admin/events/{eventId}/agents")
    public ResponseEntity<List<AgentResponse>> getEventAgents(
            Authentication authentication,
            @PathVariable Long eventId) {

        return ResponseEntity.ok(
                assignmentService.getEventAgents(
                        authentication.getName(),
                        eventId
                )
        );
    }

    // ── Événements de l'agent connecté ──
    // Utilisé par l'app Agent pour le sélecteur d'événements
    @GetMapping("/api/agent/my-events")
    public ResponseEntity<List<Map<String, Object>>> getMyEvents(
            Authentication authentication) {

        List<Event> events = assignmentService
                .getAgentEvents(authentication.getName());

        // On retourne seulement les infos utiles pour l'Agent
        List<Map<String, Object>> response = events.stream()
                .map(e -> Map.<String, Object>of(
                        "id", e.getId(),
                        "name", e.getName(),
                        "date", e.getDate().toString(),
                        "location", e.getLocation(),
                        "type", e.getType()
                ))
                .toList();

        return ResponseEntity.ok(response);
    }
}