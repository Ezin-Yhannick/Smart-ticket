package com.sqrcode.sqrcodebackend.dto;

import lombok.Data;

@Data
public class TicketResponse {
    private Long id;
    private String uuid;
    private String serialNumber;
    private String status;
    private String categoryName;
    private Integer price;
    private String color;
    private String validFrom;
    private String validTo;
}
