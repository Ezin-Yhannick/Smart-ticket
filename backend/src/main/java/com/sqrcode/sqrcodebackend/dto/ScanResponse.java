// src/main/java/com/sqrcode/sqrcodebackend/dto/ScanResponse.java
package com.sqrcode.sqrcodebackend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ScanResponse {
    private String status;    // VALID / ALREADY_USED / INVALID
    private String message;   // message principal
    private String detail;    // détail optionnel
    private String ticketId;  // UUID du ticket
}