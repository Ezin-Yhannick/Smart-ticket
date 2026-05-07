// src/main/java/com/sqrcode/sqrcodebackend/dto/ScanRequest.java
package com.sqrcode.sqrcodebackend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ScanRequest {
    @NotBlank
    private String uuid;        // contenu du QR scanné

    @NotBlank
    private String agentEmail;  // extrait du JWT côté serveur

    private Long eventId;       // l'événement en cours de contrôle
}