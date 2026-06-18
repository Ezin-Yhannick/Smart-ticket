// src/main/java/com/sqrcode/sqrcodebackend/config/AsyncConfig.java
//
// Active l'annotation @Async dans Spring Boot.
// Sans ça, @Async dans EmailService ne fonctionnerait pas.
//
// Grâce à @Async, l'envoi d'email se fait en arrière-plan :
// L'API répond immédiatement au client Flutter
// pendant que l'email part en parallèle.

package com.sqrcode.sqrcodebackend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;

@Configuration
@EnableAsync // active le support de @Async dans toute l'application
public class AsyncConfig {
    // Pas besoin de code supplémentaire
    // @EnableAsync suffit pour activer l'exécution asynchrone
}