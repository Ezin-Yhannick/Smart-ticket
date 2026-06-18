// src/main/java/com/sqrcode/sqrcodebackend/dto/CreateAgentRequest.java
//
// Ce que Flutter envoie quand l'Admin crée un agent :
// {
//   "name": "Kouassi Jean",
//   "email": "kouassi@gmail.com",
//   "password": "MotDePasse123"
// }

package com.sqrcode.sqrcodebackend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateAgentRequest {

    @NotBlank(message = "Le nom est requis")
    private String name;

    @NotBlank(message = "L'email est requis")
    @Email(message = "Email invalide")
    private String email;

    @NotBlank(message = "Le mot de passe est requis")
    @Size(min = 6, message = "Mot de passe trop court (min 6 caractères)")
    private String password;

    @NotBlank(message = "Le numéro WhatsApp est requis")
    private String phone;
}