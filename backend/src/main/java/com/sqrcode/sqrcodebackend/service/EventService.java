// src/main/java/com/sqrcode/sqrcodebackend/service/EventService.java
package com.sqrcode.sqrcodebackend.service;

import com.sqrcode.sqrcodebackend.dto.*;
import com.sqrcode.sqrcodebackend.entity.*;
import com.sqrcode.sqrcodebackend.repository.*;
import com.sqrcode.sqrcodebackend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;
    private final TicketRepository ticketRepository;
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final TicketCategoryRepository ticketCategoryRepository;

    // Crée un événement + génère tous les tickets d'un coup
    // Remplace createEvent() complètement
    @Transactional
    public EventResponse createEvent(CreateEventRequest req, String adminEmail) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new RuntimeException("Admin introuvable"));

        // Crée l'événement
        Event event = new Event();
        event.setName(req.getName());
        event.setType(req.getType());
        event.setDate(LocalDate.parse(req.getDate()));
        event.setLocation(req.getLocation());
        event.setDescription(req.getDescription());
        event.setAdmin(admin);
        // ticketQuota sera calculé depuis les catégories
        event.setTicketQuota(req.getCategories().stream()
                .mapToInt(CategoryRequest::getQuota).sum());
        event = eventRepository.save(event);

        // Pour chaque catégorie, génère les tickets
        List<CategoryResponse> categoryResponses = new ArrayList<>();
        for (CategoryRequest catReq : req.getCategories()) {

            // Crée la catégorie
            TicketCategory category = new TicketCategory();
            category.setName(catReq.getName());
            category.setPrice(catReq.getPrice());
            category.setQuota(catReq.getQuota());
            category.setColor(catReq.getColor());
            category.setValidFrom(LocalDate.parse(catReq.getValidFrom()));
            category.setValidTo(LocalDate.parse(catReq.getValidTo()));
            category.setEvent(event);
            category = ticketCategoryRepository.save(category);

            // Génère les tickets pour cette catégorie
            List<Ticket> tickets = new ArrayList<>();
            for (int i = 0; i < catReq.getQuota(); i++) {
                Ticket ticket = new Ticket();
                ticket.setEvent(event);
                ticket.setCategory(category);
                ticket.setPrice(catReq.getPrice());
                ticket.setValidFrom(LocalDate.parse(catReq.getValidFrom()));
                ticket.setValidTo(LocalDate.parse(catReq.getValidTo()));
                // Numéro de série lisible : "VIP-0042"
                ticket.setSerialNumber(
                        catReq.getName().toUpperCase().replace(" ", "")
                                + "-" + String.format("%04d", i + 1)
                );
                tickets.add(ticket);
            }
            ticketRepository.saveAll(tickets);

            CategoryResponse cr = new CategoryResponse();
            cr.setId(category.getId());
            cr.setName(category.getName());
            cr.setPrice(category.getPrice());
            cr.setQuota(category.getQuota());
            cr.setColor(category.getColor());
            cr.setValidFrom(category.getValidFrom().toString());
            cr.setValidTo(category.getValidTo().toString());
            cr.setTicketsSold(0);
            cr.setTicketsUsed(0);
            categoryResponses.add(cr);
        }

        return toResponse(event, categoryResponses);
    }

    // Mets à jour toResponse()
    private EventResponse toResponse(Event e, List<CategoryResponse> categories) {
        EventResponse r = new EventResponse();
        r.setId(e.getId());
        r.setName(e.getName());
        r.setType(e.getType());
        r.setDate(e.getDate().toString());
        r.setLocation(e.getLocation());
        r.setDescription(e.getDescription());
        r.setTicketQuota(e.getTicketQuota());
        r.setTicketsSold(categories.stream().mapToInt(c -> c.getTicketsSold()).sum());
        r.setTicketsUsed(categories.stream().mapToInt(c -> c.getTicketsUsed()).sum());
        r.setStatus(e.getStatus().name());
        r.setCreatedAt(e.getCreatedAt().toString());
        r.setCategories(categories);
        return r;
    }

    // Mets à jour getMyEvents()
    public List<EventResponse> getMyEvents(String adminEmail) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new RuntimeException("Admin introuvable"));

        return eventRepository.findByAdminOrderByCreatedAtDesc(admin)
                .stream()
                .map(e -> {
                    List<CategoryResponse> cats = ticketCategoryRepository
                            .findByEvent(e)
                            .stream()
                            .map(cat -> {
                                CategoryResponse cr = new CategoryResponse();
                                cr.setId(cat.getId());
                                cr.setName(cat.getName());
                                cr.setPrice(cat.getPrice());
                                cr.setQuota(cat.getQuota());
                                cr.setColor(cat.getColor());
                                cr.setValidFrom(cat.getValidFrom().toString());
                                cr.setValidTo(cat.getValidTo().toString());
                                cr.setTicketsSold(ticketRepository
                                        .countByEventAndCategoryAndStatus(e, cat, Ticket.TicketStatus.VENDU));
                                cr.setTicketsUsed(ticketRepository
                                        .countByEventAndCategoryAndStatus(e, cat, Ticket.TicketStatus.UTILISE));
                                return cr;
                            }).toList();
                    return toResponse(e, cats);
                })
                .toList();
    }

    // Mets à jour getTickets()
    public List<TicketResponse> getTickets(Long eventId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("Événement introuvable"));

        return ticketRepository.findByEvent(event)
                .stream()
                .map(t -> {
                    TicketResponse r = new TicketResponse();
                    r.setId(t.getId());
                    r.setUuid(t.getUuid());
                    r.setSerialNumber(t.getSerialNumber());
                    r.setStatus(t.getStatus().name());
                    r.setCategoryName(t.getCategory().getName());
                    r.setPrice(t.getPrice());
                    r.setColor(t.getCategory().getColor());
                    r.setValidFrom(t.getValidFrom().toString());
                    r.setValidTo(t.getValidTo().toString());
                    return r;
                })
                .toList();
    }
    /*
    // Tous les événements actifs (pour les agents)
    public List<EventResponse> getAllEvents() {
        return eventRepository.findAll()
                .stream()
                .filter(e -> e.getStatus() == Event.EventStatus.ACTIVE)
                .map(e -> toResponse(e,
                        ticketRepository.countByEventAndStatus(e, Ticket.TicketStatus.VENDU),
                        ticketRepository.countByEventAndStatus(e, Ticket.TicketStatus.UTILISE)
                ))
                .toList();
    }/
     */
}