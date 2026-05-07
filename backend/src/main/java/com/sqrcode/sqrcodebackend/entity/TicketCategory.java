// src/main/java/com/sqrcode/sqrcodebackend/entity/TicketCategory.java
package com.sqrcode.sqrcodebackend.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "ticket_categories")
@Data
@NoArgsConstructor
public class TicketCategory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name; // "VIP", "Standard", "Carré OR"...

    @Column(nullable = false)
    private Integer price; // prix en FCFA

    @Column(nullable = false)
    private Integer quota; // nombre de tickets à générer

    // Couleur de la bande verticale sur le ticket (ex: "#FFD700" pour Carré OR)
    @Column(nullable = false)
    private String color;

    // Validité
    @Column(nullable = false)
    private LocalDate validFrom; // début de validité

    @Column(nullable = false)
    private LocalDate validTo;   // fin de validité

    // L'événement auquel appartient cette catégorie
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    // Les tickets de cette catégorie
    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL)
    private List<Ticket> tickets;

    @Column(updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}