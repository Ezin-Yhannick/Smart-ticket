package com.sqrcode.sqrcodebackend.config;

import com.sqrcode.sqrcodebackend.entity.User;
import com.sqrcode.sqrcodebackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final  PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        // Crée les comptes seulement s'ils n'existent pas déjà
        createIfNotExists("superadmin@sqr.bj",
                "Super2025",
                "Super Administrateur",
                User.Role.SUPER_ADMIN);

        createIfNotExists("admin@sqr.bj",
                "Admin2025",
                "Organisateur Test",
                User.Role.ADMIN);

        createIfNotExists("agent@sqr.bj",
                "Agent2025",
                "Agent Test",
                User.Role.AGENT);

        System.out.println("✅ Comptes de test initialisés.");
    }

    private void createIfNotExists(String email, String password,
                                   String name, User.Role role) {
        User user = userRepository.findByEmail(email).orElse(new User());
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        user.setName(name);
        user.setRole(role);
        user.setStatus(User.Status.ACTIVE);
        userRepository.save(user);
    }
}
