// src/main/java/com/sqrcode/sqrcodebackend/dto/CategoryRequest.java
package com.sqrcode.sqrcodebackend.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class CategoryRequest {
    @NotBlank
    private String name;        // "VIP", "Standard"...

    @NotNull @Min(0)
    private Integer price;      // prix en FCFA

    @NotNull @Min(1) @Max(10000)
    private Integer quota;      // nombre de tickets

    @NotBlank
    private String color;       // couleur hex ex: "#1E88E5"

    @NotNull
    private String validFrom;   // "yyyy-MM-dd"

    @NotNull
    private String validTo;     // "yyyy-MM-dd"
}