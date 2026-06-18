package com.sqrcode.sqrcodebackend.controller;

import com.sqrcode.sqrcodebackend.service.TicketService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tickets")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class TicketController {

    private final TicketService ticketService;

    @PatchMapping("/{uuid}/sell")
    public ResponseEntity<Void> sellTicket(@PathVariable String uuid) {
        ticketService.markAsSold(uuid);
        return ResponseEntity.ok().build();
    }
}