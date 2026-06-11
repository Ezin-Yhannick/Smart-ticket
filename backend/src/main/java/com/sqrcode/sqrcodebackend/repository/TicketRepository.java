// src/main/java/com/sqrcode/sqrcodebackend/repository/TicketRepository.java
package com.sqrcode.sqrcodebackend.repository;

import com.sqrcode.sqrcodebackend.entity.Ticket;
import com.sqrcode.sqrcodebackend.entity.Event;
import com.sqrcode.sqrcodebackend.entity.TicketCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface TicketRepository extends JpaRepository<Ticket, Long> {
    List<Ticket> findByEvent(Event event);
    Optional<Ticket> findByUuid(String uuid);
    int countByEventAndStatus(Event event, Ticket.TicketStatus status);
    int countByEventAndCategoryAndStatus(
            Event event, TicketCategory category, Ticket.TicketStatus status);
    List<Ticket> findByEventAndCategory(Event event, TicketCategory category);
    int countByStatus(Ticket.TicketStatus status);
}