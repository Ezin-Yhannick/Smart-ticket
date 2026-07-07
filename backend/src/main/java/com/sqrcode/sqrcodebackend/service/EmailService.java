// src/main/java/com/sqrcode/sqrcodebackend/service/EmailService.java
//
// Service responsable de l'envoi d'emails automatiques.
// Utilise Spring Mail + Thymeleaf pour les templates HTML.
//
// Appelé dans SuperAdminService.createAdmin()
// et dans AdminService.createAgent() (à venir)

package com.sqrcode.sqrcodebackend.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

@Service
@RequiredArgsConstructor
@Slf4j // permet d'utiliser log.info(), log.error(), etc.
public class EmailService {

    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;

    // Récupère les valeurs depuis application.properties
    @Value("${app.mail.from}")
    private String fromEmail;

    @Value("${app.download.url}")
    private String downloadUrl;

    // ── Envoie l'email de bienvenue avec les identifiants ──
    //
    // @Async : l'email est envoyé en arrière-plan
    // L'API répond immédiatement sans attendre l'envoi
    @Async
    public void sendWelcomeEmail(
            String toEmail,
            String name,
            String password,
            String role) {

        try {
            // 1. Prépare le contexte Thymeleaf
            // Ce sont les variables utilisées dans le template HTML
            Context context = new Context();
            context.setVariable("name", name);
            context.setVariable("email", toEmail);
            context.setVariable("password", password);
            context.setVariable("role", role);
            context.setVariable("downloadUrl", downloadUrl);

            // 2. Génère le HTML à partir du template
            String htmlContent = templateEngine.process(
                    "welcome-email", // nom du fichier dans /templates/
                    context
            );

            // 3. Crée le message email
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message,
                    true,    // multipart (permet le HTML)
                    "UTF-8"
            );

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("🎫 Vos identifiants Smart-Ticket");
            helper.setText(htmlContent, true); // true = HTML

            // 4. Envoie l'email
            mailSender.send(message);

            log.info("Email de bienvenue envoyé à : {}", toEmail);

        } catch (MessagingException e) {
            // On log l'erreur mais on ne bloque pas le système
            // Si l'email échoue, le compte est quand même créé
            log.error("Erreur envoi email à {} : {}", toEmail, e.getMessage());
        }
    }

    // ── Email d'assignation à un événement ──
    @Async
    public void sendAssignmentEmail(
            String toEmail,
            String name,
            String eventName,
            String eventDate,
            String eventLocation) {

        try {
            Context context = new Context();
            context.setVariable("name", name);
            context.setVariable("eventName", eventName);
            context.setVariable("eventDate", eventDate);
            context.setVariable("eventLocation", eventLocation);

            String htmlContent = templateEngine.process(
                    "assignment-email", context);

            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("🎫 Vous êtes assigné à " + eventName);
            helper.setText(htmlContent, true);

            mailSender.send(message);
            log.info("Email assignation envoyé à : {}", toEmail);

        } catch (MessagingException e) {
            log.error("Erreur email assignation {} : {}",
                    toEmail, e.getMessage());
        }
    }
}