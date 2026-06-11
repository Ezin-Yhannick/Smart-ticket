// src/main/java/com/sqrcode/sqrcodebackend/dto/AdminUserResponse.java
package com.sqrcode.sqrcodebackend.dto;

import lombok.Data;

@Data
public class AdminUserResponse {
    private Long id;
    private String name;
    private String email;
    private String role;
    private String status;
    private String createdAt;
    private int totalEvents;
    private int totalTickets;
}