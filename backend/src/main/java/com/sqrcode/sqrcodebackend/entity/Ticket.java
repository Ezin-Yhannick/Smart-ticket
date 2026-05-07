package com.sqrcode.sqrcodebackend.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "tickets")
@Data
@NoArgsConstructor
public class Ticket {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // UUID unique — c'est ce qui est encodé dans le QR code
    @Column(nullable = false, unique = true)
    private String uuid = UUID.randomUUID().toString();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TicketStatus status = TicketStatus.NON_VENDU;

    // L'événement auquel appartient ce ticket
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    // Rempli lors du scan à l'entrée
    private LocalDateTime scannedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "scanned_by")
    private User scannedBy; // le marchand qui a scanné

    @Column(updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public enum TicketStatus {
        NON_VENDU,
        VENDU,
        UTILISE
    }

    // La catégorie du ticket (VIP, Standard...)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = true)
    private TicketCategory category;

    // Prix snapshot (au moment de la génération)
    private Integer price;

    // Validité snapshot
    private LocalDate validFrom;

    private LocalDate validTo;

    // Numéro de série lisible (ex: "VIP-0042")
    private String serialNumber;
}