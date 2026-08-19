package cl.ufro.medhelp.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {

    @NotBlank(message = "El campo email es requerido.")
    @Email(message = "El formato del email no es válido.")
    private String email;

    @NotBlank(message = "El campo password es requerido.")
    private String password;
}
