// src/main/java/com/sqrcode/sqrcodebackend/service/SuperAdminService.java
package com.sqrcode.sqrcodebackend.service;

import com.sqrcode.sqrcodebackend.dto.*;
import com.sqrcode.sqrcodebackend.entity.Ticket;
import com.sqrcode.sqrcodebackend.entity.User;
import com.sqrcode.sqrcodebackend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SuperAdminService {

    private final UserRepository userRepository;
    private final EventRepository eventRepository;
    private final TicketRepository ticketRepository;
    private final PasswordEncoder passwordEncoder;

    // ── Stats globales de la plateforme ──
    public PlatformStatsResponse getPlatformStats() {
        List<User> admins = userRepository.findByRole(User.Role.ADMIN);
        int totalAdmins = admins.size();
        int activeAdmins = (int) admins.stream()
                .filter(a -> a.getStatus() == User.Status.ACTIVE)
                .count();
        int suspendedAdmins = totalAdmins - activeAdmins;

        int totalEvents  = (int) eventRepository.count();
        int totalTickets = (int) ticketRepository.count();
        int totalSold    = ticketRepository
                .countByStatus(Ticket.TicketStatus.VENDU);
        int totalUsed    = ticketRepository
                .countByStatus(Ticket.TicketStatus.UTILISE);

        return new PlatformStatsResponse(
                totalAdmins, totalEvents, totalTickets,
                totalSold, totalUsed, activeAdmins, suspendedAdmins
        );
    }

    // ── Liste de tous les admins ──
    public List<AdminUserResponse> getAllAdmins() {
        return userRepository.findByRole(User.Role.ADMIN)
                .stream()
                .map(u -> {
                    AdminUserResponse r = new AdminUserResponse();
                    r.setId(u.getId());
                    r.setName(u.getName());
                    r.setEmail(u.getEmail());
                    r.setRole(u.getRole().name());
                    r.setStatus(u.getStatus().name());
                    r.setCreatedAt(u.getCreatedAt().toString());
                    int events = eventRepository.findByAdmin(u).size();
                    r.setTotalEvents(events);
                    r.setTotalTickets(
                        eventRepository.findByAdmin(u).stream()
                            .mapToInt(e -> e.getTicketQuota() != null
                                    ? e.getTicketQuota() : 0)
                            .sum()
                    );
                    return r;
                })
                .toList();
    }

    // ── Créer un compte Admin ──
    public AdminUserResponse createAdmin(CreateAdminRequest req) {
        if (userRepository.existsByEmail(req.getEmail())) {
            throw new RuntimeException("Un compte avec cet email existe déjà");
        }
        User user = new User();
        user.setEmail(req.getEmail());
        user.setName(req.getName());
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        user.setRole(User.Role.ADMIN);
        user.setStatus(User.Status.ACTIVE);
        user = userRepository.save(user);

        AdminUserResponse r = new AdminUserResponse();
        r.setId(user.getId());
        r.setName(user.getName());
        r.setEmail(user.getEmail());
        r.setRole(user.getRole().name());
        r.setStatus(user.getStatus().name());
        r.setCreatedAt(user.getCreatedAt().toString());
        r.setTotalEvents(0);
        r.setTotalTickets(0);
        return r;
    }

    // ── Suspendre un Admin ──
    public void suspendAdmin(Long adminId) {
        User user = userRepository.findById(adminId)
                .orElseThrow(() -> new RuntimeException("Admin introuvable"));
        if (user.getRole() != User.Role.ADMIN) {
            throw new RuntimeException("Cet utilisateur n'est pas un Admin");
        }
        user.setStatus(User.Status.SUSPENDED);
        userRepository.save(user);
    }

    // ── Activer un Admin ──
    public void activateAdmin(Long adminId) {
        User user = userRepository.findById(adminId)
                .orElseThrow(() -> new RuntimeException("Admin introuvable"));
        user.setStatus(User.Status.ACTIVE);
        userRepository.save(user);
    }

    // ── Supprimer un Admin ──
    public void deleteAdmin(Long adminId) {
        User user = userRepository.findById(adminId)
                .orElseThrow(() -> new RuntimeException("Admin introuvable"));
        if (user.getRole() != User.Role.ADMIN) {
            throw new RuntimeException("Cet utilisateur n'est pas un Admin");
        }
        userRepository.delete(user);
    }
}