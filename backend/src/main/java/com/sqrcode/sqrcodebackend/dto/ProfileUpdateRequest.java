package com.sqrcode.sqrcodebackend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ProfileUpdateRequest {
    @NotBlank(message = "Le nom est obligatoire")
    private String name;

    @NotBlank(message = "Le numéro de téléphone est obligatoire")
    private String phone;
}
