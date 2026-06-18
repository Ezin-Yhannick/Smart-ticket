package com.sqrcode.sqrcodebackend.dto;

import lombok.Data;
import java.util.List;

@Data
public class AssignAgentsRequest {
    // Liste des IDs des agents à assigner
    // Ex: [1, 3, 5]
    private List<Long> agentIds;
}