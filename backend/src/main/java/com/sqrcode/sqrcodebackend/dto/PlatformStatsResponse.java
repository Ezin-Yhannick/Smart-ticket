// src/main/java/com/sqrcode/sqrcodebackend/dto/PlatformStatsResponse.java
package com.sqrcode.sqrcodebackend.dto;

import lombok.Data;
import lombok.AllArgsConstructor;

@Data
@AllArgsConstructor
public class PlatformStatsResponse {
    private int totalAdmins;
    private int totalEvents;
    private int totalTickets;
    private int totalSold;
    private int totalUsed;
    private int activeAdmins;
    private int suspendedAdmins;
}