package com.sqrcode.sqrcodebackend.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.List;

@Data
public class CreateEventRequest {
    @NotBlank
    private String name;

    @NotBlank
    private String type;

    @NotNull
    private String date; // format "yyyy-MM-dd"

    @NotBlank
    private String location;

    private String description;

    @NotNull @Size(min = 1)
    private List<CategoryRequest> categories;
}
