// src/main/java/com/sqrcode/sqrcodebackend/dto/CategoryResponse.java
package com.sqrcode.sqrcodebackend.dto;

import lombok.Data;

@Data
public class CategoryResponse {
    private Long id;
    private String name;
    private Integer price;
    private Integer quota;
    private String color;
    private String validFrom;
    private String validTo;
    private Integer ticketsSold;
    private Integer ticketsUsed;
}