// src/main/java/com/sqrcode/sqrcodebackend/repository/EventRepository.java
package com.sqrcode.sqrcodebackend.repository;

import com.sqrcode.sqrcodebackend.entity.Event;
import com.sqrcode.sqrcodebackend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface EventRepository extends JpaRepository<Event, Long> {
    // Tous les événements d'un admin
    List<Event> findByAdminOrderByCreatedAtDesc(User admin);
}