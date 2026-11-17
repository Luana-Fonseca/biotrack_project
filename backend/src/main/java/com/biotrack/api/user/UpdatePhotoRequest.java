package com.biotrack.api.user;

import jakarta.validation.constraints.NotBlank;

public record UpdatePhotoRequest(@NotBlank(message = "Foto é obrigatória") String photoBase64) {
}
