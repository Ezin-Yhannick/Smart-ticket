// src/main/java/com/sqrcode/sqrcodebackend/service/AssignmentService.java
//
// Gère l'assignation des agents aux événements.
//
// Quand un admin assigne des agents à un événement :
//   1. On vérifie que l'événement appartient bien à cet admin
//   2. On vérifie que les agents appartiennent bien à cet admin
//   3. On crée les liens dans la table event_agents
//   4. On envoie email + WhatsApp à chaque agent assigné

package com.sqrcode.sqrcodebackend.service;

import com.sqrcode.sqrcodebackend.dto.AgentResponse;
import com.sqrcode.sqrcodebackend.dto.AssignAgentsRequest;
import com.sqrcode.sqrcodebackend.entity.Event;
import com.sqrcode.sqrcodebackend.entity.User;
import com.sqrcode.sqrcodebackend.repository.EventRepository;
import com.sqrcode.sqrcodebackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Slf4j
public class AssignmentService {

    private final EventRepository eventRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final WhatsAppService whatsAppService;

    // ── Assigne des agents à un événement ──
    @Transactional
    public void assignAgents(
            String adminEmail,
            Long eventId,
            AssignAgentsRequest req) {

        // Trouve l'admin connecté
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() ->
                        new RuntimeException("Admin introuvable"));

        // Trouve l'événement
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() ->
                        new RuntimeException("Événement introuvable"));

        // Vérifie que l'événement appartient bien à cet admin
        if (!event.getAdmin().getId().equals(admin.getId())) {
            throw new RuntimeException(
                    "Vous n'avez pas accès à cet événement");
        }

        // Récupère les agents à assigner
        List<User> agentsToAssign = userRepository
                .findAllById(req.getAgentIds());

        // Vérifie que chaque agent appartient bien à cet admin
        for (User agent : agentsToAssign) {
            if (agent.getRole() != User.Role.AGENT) {
                throw new RuntimeException(
                        agent.getName() + " n'est pas un agent");
            }
            if (agent.getCreatedBy() == null ||
                    !agent.getCreatedBy().getId().equals(admin.getId())) {
                throw new RuntimeException(
                        "L'agent " + agent.getName() +
                                " n'appartient pas à votre équipe");
            }
        }

        // Ajoute les agents à l'événement
        // addAll évite les doublons grâce au Set
        event.getAgents().addAll(agentsToAssign);
        eventRepository.save(event);

        // Envoie email + WhatsApp à chaque agent assigné
        for (User agent : agentsToAssign) {
            // Email
            emailService.sendAssignmentEmail(
                    agent.getEmail(),
                    agent.getName(),
                    event.getName(),
                    event.getDate().toString(),
                    event.getLocation()
            );

            // WhatsApp (si numéro disponible)
            if (agent.getPhone() != null &&
                    !agent.getPhone().isBlank()) {
                whatsAppService.sendAssignmentMessage(
                        agent.getPhone(),
                        agent.getName(),
                        event.getName(),
                        event.getDate().toString(),
                        event.getLocation()
                );
            }
        }

        log.info("{} agents assignés à l'événement {}",
                agentsToAssign.size(), event.getName());
    }

    // ── Désassigne un agent d'un événement ──
    @Transactional
    public void unassignAgent(
            String adminEmail,
            Long eventId,
            Long agentId) {

        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() ->
                        new RuntimeException("Admin introuvable"));

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() ->
                        new RuntimeException("Événement introuvable"));

        if (!event.getAdmin().getId().equals(admin.getId())) {
            throw new RuntimeException(
                    "Vous n'avez pas accès à cet événement");
        }

        // Supprime l'agent de la liste
        event.getAgents().removeIf(a -> a.getId().equals(agentId));
        eventRepository.save(event);
    }

    // ── Liste des agents assignés à un événement ──
    public List<AgentResponse> getEventAgents(
            String adminEmail,
            Long eventId) {

        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() ->
                        new RuntimeException("Admin introuvable"));

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() ->
                        new RuntimeException("Événement introuvable"));

        if (!event.getAdmin().getId().equals(admin.getId())) {
            throw new RuntimeException(
                    "Vous n'avez pas accès à cet événement");
        }

        return event.getAgents().stream()
                .map(agent -> {
                    AgentResponse r = new AgentResponse();
                    r.setId(agent.getId());
                    r.setName(agent.getName());
                    r.setEmail(agent.getEmail());
                    r.setStatus(agent.getStatus().name());
                    r.setCreatedAt(agent.getCreatedAt().toString());
                    return r;
                })
                .toList();
    }

    // ── Événements assignés à l'agent connecté ──
    // Utilisé par l'app Agent pour charger ses événements
    public List<Event> getAgentEvents(String agentEmail) {
        User agent = userRepository.findByEmail(agentEmail)
                .orElseThrow(() ->
                        new RuntimeException("Agent introuvable"));

        return eventRepository.findByAgentsContaining(agent);
    }
}