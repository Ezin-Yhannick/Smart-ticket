// src/main/java/com/sqrcode/sqrcodebackend/service/ScanService.java
package com.sqrcode.sqrcodebackend.service;

import com.sqrcode.sqrcodebackend.dto.ScanResponse;
import com.sqrcode.sqrcodebackend.entity.Ticket;
import com.sqrcode.sqrcodebackend.entity.User;
import com.sqrcode.sqrcodebackend.repository.TicketRepository;
import com.sqrcode.sqrcodebackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ScanService {

    private final TicketRepository ticketRepository;
    private final UserRepository userRepository;

    @Transactional
    public ScanResponse scan(String uuid, String agentEmail) {

        // 1. Cherche le ticket par UUID
        Optional<Ticket> ticketOpt = ticketRepository.findByUuid(uuid);

        // 2. UUID inconnu → fraude
        if (ticketOpt.isEmpty()) {
            return new ScanResponse(
                    "INVALID",
                    "QR code invalide",
                    "Ce ticket n'existe pas dans le système",
                    uuid
            );
        }

        Ticket ticket = ticketOpt.get();

        // 3. Ticket déjà utilisé → doublon
        if (ticket.getStatus() == Ticket.TicketStatus.UTILISE) {
            String firstScan = ticket.getScannedAt() != null
                    ? ticket.getScannedAt().format(
                    DateTimeFormatter.ofPattern("dd/MM/yyyy à HH:mm"))
                    : "date inconnue";

            return new ScanResponse(
                    "ALREADY_USED",
                    "Ticket déjà scanné",
                    "Premier scan le " + firstScan,
                    uuid
            );
        }

        // 4. Ticket non vendu → invalide (pas encore payé)
        if (ticket.getStatus() == Ticket.TicketStatus.NON_VENDU) {
            return new ScanResponse(
                    "INVALID",
                    "Ticket non validé",
                    "Ce ticket n'a pas encore été acheté",
                    uuid
            );
        }

        // 5. Ticket VENDU → accès autorisé → on le marque UTILISE
        User agent = userRepository.findByEmail(agentEmail).orElse(null);

        ticket.setStatus(Ticket.TicketStatus.UTILISE);
        ticket.setScannedAt(LocalDateTime.now());
        ticket.setScannedBy(agent);
        ticketRepository.save(ticket);

        return new ScanResponse(
                "VALID",
                "Accès autorisé",
                "Ticket valide pour " + ticket.getEvent().getName(),
                uuid
        );
    }
}