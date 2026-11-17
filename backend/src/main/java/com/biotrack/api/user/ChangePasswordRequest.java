package com.biotrack.api.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record ChangePasswordRequest(
        @NotBlank(message = "Nova senha é obrigatória")
        @Pattern(
                regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,}$",
                message = "A nova senha precisa ter no mínimo 8 caracteres, com letra maiúscula, minúscula, número e caractere especial"
        )
        String newPassword
) {
}
