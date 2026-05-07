// src/main/java/com/sqrcode/sqrcodebackend/controller/EventController.java
package com.sqrcode.sqrcodebackend.controller;

import com.sqrcode.sqrcodebackend.dto.*;
import com.sqrcode.sqrcodebackend.service.EventService;
import com.sqrcode.sqrcodebackend.service.WordExportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class EventController {

    private final EventService eventService;
    private final WordExportService wordExportService;

    // POST /api/events — créer un événement
    @PostMapping
    public ResponseEntity<EventResponse> createEvent(
            @Valid @RequestBody CreateEventRequest req,
            @AuthenticationPrincipal String adminEmail) {
        return ResponseEntity.ok(eventService.createEvent(req, adminEmail));
    }

    // GET /api/events — liste des événements de l'admin connecté
    @GetMapping
    public ResponseEntity<List<EventResponse>> getMyEvents(
            @AuthenticationPrincipal String adminEmail) {
        return ResponseEntity.ok(eventService.getMyEvents(adminEmail));
    }

    // GET /api/events/{id}/tickets — tickets d'un événement
    @GetMapping("/{id}/tickets")
    public ResponseEntity<List<TicketResponse>> getTickets(@PathVariable Long id) {
        return ResponseEntity.ok(eventService.getTickets(id));
    }

    // GET /api/events/{id}/export?filter=tous|non_vendus&categoryId=1
    @GetMapping("/{id}/export")
    public ResponseEntity<byte[]> exportWord(
            @PathVariable Long id,
            @RequestParam(defaultValue = "tous") String filter,
            @RequestParam(required = false) Long categoryId) throws Exception {  // ✅ categoryId ajouté

        byte[] wordFile = wordExportService.exportTicketsToWord(id, filter, categoryId);  // ✅ 3 arguments

        return ResponseEntity.ok()
                .header("Content-Disposition",
                        "attachment; filename=\"tickets-event-" + id + ".docx\"")
                .header("Content-Type",
                        "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
                .body(wordFile);
    }

   /*
    // GET /api/events/all — tous les événements actifs
    // Accessible par les agents pour choisir leur événement
    @GetMapping("/all")
    public ResponseEntity<List<EventResponse>> getAllEvents() {
        return ResponseEntity.ok(eventService.getAllEvents());
    }/
    */
}
