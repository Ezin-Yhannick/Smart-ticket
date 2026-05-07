package com.sqrcode.sqrcodebackend.service;

import com.sqrcode.sqrcodebackend.dto.AuthResponse;
import com.sqrcode.sqrcodebackend.dto.LoginRequest;
import com.sqrcode.sqrcodebackend.entity.User;
import com.sqrcode.sqrcodebackend.repository.UserRepository;
import com.sqrcode.sqrcodebackend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email ou mot de passe incorrect"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Email ou mot de passe incorrect");
        }

        if (user.getStatus() == User.Status.SUSPENDED) {
            throw new RuntimeException("Compte suspendu. Contactez l'administrateur.");
        }

        String token = jwtService.generateToken(
                user.getEmail(),
                user.getRole().name(),
                user.getId()
        );

        return new AuthResponse(
                token,
                user.getRole().name(),
                user.getName(),
                user.getEmail(),
                user.getId()
        );
    }
}