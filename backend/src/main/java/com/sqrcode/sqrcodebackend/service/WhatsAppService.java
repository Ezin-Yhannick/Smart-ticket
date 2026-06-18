// src/main/java/com/sqrcode/sqrcodebackend/service/WhatsAppService.java
//
// Service d'envoi de messages WhatsApp via Meta Business API.
//
// Flux :
//   1. Admin/Agent créé → SuperAdminService/AgentService appelle ce service
//   2. On envoie un message WhatsApp avec les identifiants
//   3. L'utilisateur reçoit un message sur son WhatsApp
//
// ⚠️ Important : Meta exige l'utilisation de templates approuvés
// pour les messages envoyés en dehors d'une conversation active.
// Le template doit être créé et approuvé dans Meta Business Manager.

package com.sqrcode.sqrcodebackend.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.http.MediaType;

import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class WhatsAppService {

    private final WebClient webClient;

    @Value("${whatsapp.phone.number.id}")
    private String phoneNumberId;

    @Value("${whatsapp.access.token}")
    private String accessToken;

    @Value("${whatsapp.template.name}")
    private String templateName;

    @Value("${whatsapp.api.url}")
    private String apiUrl;

    public WhatsAppService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.build();
    }

    // ── Envoie le message WhatsApp de bienvenue ──
    //
    // @Async : envoyé en arrière-plan comme l'email
    // L'API répond immédiatement sans attendre l'envoi
    //
    // Paramètres :
    //   phone    → numéro au format international sans + (ex: 22901234567)
    //   name     → nom de l'utilisateur
    //   email    → email de connexion
    //   password → mot de passe temporaire
    //   role     → ADMIN ou AGENT
    @Async
    public void sendWelcomeMessage(
            String phone,
            String name,
            String email,
            String password,
            String role) {

        try {
            // Nettoie le numéro : supprime +, espaces, tirets
            String cleanPhone = phone
                    .replaceAll("\\+", "")
                    .replaceAll("\\s", "")
                    .replaceAll("-", "");

            // Corps de la requête selon le format Meta API
            // Le template doit avoir des paramètres dans cet ordre :
            // {{1}} = name, {{2}} = role, {{3}} = email, {{4}} = password
            Map<String, Object> body = Map.of(
                    "messaging_product", "whatsapp",
                    "to", cleanPhone,
                    "type", "template",
                    "template", Map.of(
                            "name", templateName,
                            "language", Map.of("code", "fr"),
                            "components", List.of(
                                    Map.of(
                                            "type", "body",
                                            "parameters", List.of(
                                                    // {{1}} → Nom
                                                    Map.of("type", "text", "text", name),
                                                    // {{2}} → Rôle
                                                    Map.of("type", "text",
                                                            "text", role.equals("ADMIN")
                                                                    ? "Administrateur"
                                                                    : "Agent de contrôle"),
                                                    // {{3}} → Email
                                                    Map.of("type", "text", "text", email),
                                                    // {{4}} → Mot de passe
                                                    Map.of("type", "text", "text", password)
                                            )
                                    )
                            )
                    )
            );

            // Appel à l'API Meta WhatsApp
            webClient.post()
                    .uri(apiUrl + "/" + phoneNumberId + "/messages")
                    .header("Authorization", "Bearer " + accessToken)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            log.info("WhatsApp envoyé à : {}", cleanPhone);

        } catch (Exception e) {
            // On log l'erreur mais on ne bloque pas le système
            // Si WhatsApp échoue, le compte est quand même créé
            // et l'email a déjà été envoyé
            log.error("Erreur envoi WhatsApp à {} : {}",
                    phone, e.getMessage());
        }
    }

    // ── Message WhatsApp d'assignation ──
    @Async
    public void sendAssignmentMessage(
            String phone,
            String name,
            String eventName,
            String eventDate,
            String eventLocation) {

        try {
            String cleanPhone = phone
                    .replaceAll("\\+", "")
                    .replaceAll("\\s", "")
                    .replaceAll("-", "");

            Map<String, Object> body = Map.of(
                    "messaging_product", "whatsapp",
                    "to", cleanPhone,
                    "type", "template",
                    "template", Map.of(
                            "name", "smart_ticket_assignment",
                            "language", Map.of("code", "fr"),
                            "components", List.of(
                                    Map.of(
                                            "type", "body",
                                            "parameters", List.of(
                                                    Map.of("type", "text", "text", name),
                                                    Map.of("type", "text", "text", eventName),
                                                    Map.of("type", "text", "text", eventDate),
                                                    Map.of("type", "text", "text", eventLocation)
                                            )
                                    )
                            )
                    )
            );

            webClient.post()
                    .uri(apiUrl + "/" + phoneNumberId + "/messages")
                    .header("Authorization", "Bearer " + accessToken)
                    .contentType(MediaType.APPLICATION_JSON)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            log.info("WhatsApp assignation envoyé à : {}", cleanPhone);

        } catch (Exception e) {
            log.error("Erreur WhatsApp assignation {} : {}",
                    phone, e.getMessage());
        }
    }
}