// src/main/java/com/sqrcode/sqrcodebackend/service/AgentService.java
//
// Service de gestion des agents.
// Un Admin crée ses propres agents — chaque agent est lié
// à l'Admin qui l'a créé.
//
// Quand un agent est créé :
//   1. On vérifie que l'email n'existe pas déjà
//   2. On crée le compte avec le rôle AGENT
//   3. On envoie l'email de bienvenue automatiquement

package com.sqrcode.sqrcodebackend.service;

import com.sqrcode.sqrcodebackend.dto.CreateAgentRequest;
import com.sqrcode.sqrcodebackend.dto.AgentResponse;
import com.sqrcode.sqrcodebackend.entity.User;
import com.sqrcode.sqrcodebackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AgentService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final WhatsAppService whatsAppService;

    // ── Récupère tous les agents de l'admin connecté ──
    public List<AgentResponse> getMyAgents(String adminEmail) {
        // On trouve l'admin par son email (extrait du JWT)
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() ->
                        new RuntimeException("Admin introuvable"));

        // On récupère tous les agents créés par cet admin
        return userRepository.findByCreatedByAndRole(admin, User.Role.AGENT)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ── Crée un nouvel agent ──
    public AgentResponse createAgent(
            String adminEmail,
            CreateAgentRequest req) {

        // Vérifie que l'email n'est pas déjà utilisé
        if (userRepository.existsByEmail(req.getEmail())) {
            throw new RuntimeException(
                    "Un compte avec cet email existe déjà");
        }

        // Trouve l'admin connecté
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() ->
                        new RuntimeException("Admin introuvable"));

        // Garde le mot de passe en clair avant de le hasher
        // pour l'envoyer par email
        String rawPassword = req.getPassword();

        // Crée le compte agent
        User agent = new User();
        agent.setEmail(req.getEmail());
        agent.setName(req.getName());
        agent.setPassword(passwordEncoder.encode(rawPassword));
        agent.setRole(User.Role.AGENT);
        agent.setStatus(User.Status.ACTIVE);
        agent.setCreatedBy(admin);
        agent.setPhone(req.getPhone());// lié à l'admin créateur
        agent = userRepository.save(agent);

        // Envoie l'email de bienvenue en arrière-plan
        emailService.sendWelcomeEmail(
                agent.getEmail(),
                agent.getName(),
                rawPassword,
                "AGENT"
        );

        // ← NOUVEAU : WhatsApp automatique
        if (agent.getPhone() != null && !agent.getPhone().isBlank()) {
            whatsAppService.sendWelcomeMessage(
                    agent.getPhone(),
                    agent.getName(),
                    agent.getEmail(),
                    rawPassword,
                    "AGENT"
            );
        }
        return toResponse(agent);
    }

    // ── Supprime un agent ──
    public void deleteAgent(String adminEmail, Long agentId) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() ->
                        new RuntimeException("Admin introuvable"));

        User agent = userRepository.findById(agentId)
                .orElseThrow(() ->
                        new RuntimeException("Agent introuvable"));

        // Vérifie que cet agent appartient bien à cet admin
        if (!agent.getCreatedBy().getId().equals(admin.getId())) {
            throw new RuntimeException(
                    "Vous ne pouvez pas supprimer cet agent");
        }

        if (agent.getRole() != User.Role.AGENT) {
            throw new RuntimeException(
                    "Cet utilisateur n'est pas un agent");
        }

        userRepository.delete(agent);
    }

    // ── Convertit un User en AgentResponse ──
    private AgentResponse toResponse(User agent) {
        AgentResponse r = new AgentResponse();
        r.setId(agent.getId());
        r.setName(agent.getName());
        r.setEmail(agent.getEmail());
        r.setStatus(agent.getStatus().name());
        r.setCreatedAt(agent.getCreatedAt().toString());
        return r;
    }
}