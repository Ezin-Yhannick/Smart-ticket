package com.sqrcode.sqrcodebackend.service;


import com.sqrcode.sqrcodebackend.entity.Ticket;
import com.sqrcode.sqrcodebackend.repository.TicketRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class TicketService {
    private final TicketRepository ticketRepository;

    @Transactional
    public void markAsSold(String uuid) {
        Ticket ticket = ticketRepository.findByUuid(uuid)
                .orElseThrow(() -> new RuntimeException("Ticket introuvable"));
        ticket.setStatus(Ticket.TicketStatus.VENDU);
        ticketRepository.save(ticket);
    }
}
