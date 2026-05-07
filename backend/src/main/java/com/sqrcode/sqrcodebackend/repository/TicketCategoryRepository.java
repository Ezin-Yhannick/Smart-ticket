package com.sqrcode.sqrcodebackend.repository;

import com.sqrcode.sqrcodebackend.entity.TicketCategory;
import com.sqrcode.sqrcodebackend.entity.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface TicketCategoryRepository extends JpaRepository<TicketCategory, Long> {
    List<TicketCategory> findByEvent(Event event);
}