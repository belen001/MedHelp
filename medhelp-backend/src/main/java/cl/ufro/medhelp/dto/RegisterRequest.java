package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {

    @NotBlank(message = "El campo name es requerido.")
    @Size(min = 2, max = 120, message = "El nombre debe tener entre 2 y 120 caracteres.")
    private String name;

    @NotBlank(message = "El campo email es requerido.")
    @Email(message = "El formato del email no es válido.")
    private String email;

    @NotBlank(message = "El campo password es requerido.")
    @Size(min = 6, max = 100, message = "La contraseña debe tener al menos 6 caracteres.")
    private String password;

    @NotBlank(message = "El campo password_confirmation es requerido.")
    @JsonProperty("password_confirmation")
    private String passwordConfirmation;
}
