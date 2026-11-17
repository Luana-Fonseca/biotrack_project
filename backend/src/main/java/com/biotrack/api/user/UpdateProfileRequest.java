package com.biotrack.api.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

/** Fields editable from the "Editar perfil" screen — a subset of User, deliberately excluding email/password/role
 * (the login password has its own dedicated endpoint, {@link ChangePasswordRequest}). */
public record UpdateProfileRequest(
        @NotBlank(message = "Nome é obrigatório") @Size(max = 150) String name,
        @Size(max = 100) String profession,
        @Size(max = 100) String city,
        LocalDate birthDate
) {
}
