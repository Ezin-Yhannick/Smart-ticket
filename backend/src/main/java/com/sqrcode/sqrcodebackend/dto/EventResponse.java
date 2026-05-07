package com.sqrcode.sqrcodebackend.dto;

import lombok.Data;

import java.util.List;

@Data
public class EventResponse {
    private Long id;
    private String name;
    private String type;
    private String date;
    private String location;
    private String description;
    private Integer ticketsSold;
    private Integer ticketsUsed;
    private String status;
    private String createdAt;
    private List<CategoryResponse> categories;
    private Integer ticketQuota;
}
