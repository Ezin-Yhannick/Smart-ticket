// src/main/java/com/sqrcode/sqrcodebackend/dto/AgentResponse.java
//
// Ce que le backend retourne quand Flutter demande la liste
// des agents ou crée un nouvel agent :
// {
//   "id": 5,
//   "name": "Kouassi Jean",
//   "email": "kouassi@gmail.com",
//   "status": "ACTIVE",
//   "createdAt": "2025-08-15T10:30:00"
// }

package com.sqrcode.sqrcodebackend.dto;

import lombok.Data;

@Data
public class AgentResponse {
    private Long id;
    private String name;
    private String email;
    private String status;
    private String createdAt;
}