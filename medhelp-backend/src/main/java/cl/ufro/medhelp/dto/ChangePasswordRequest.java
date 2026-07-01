package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
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
public class ChangePasswordRequest {

    @NotBlank(message = "El campo current_password es requerido.")
    @JsonProperty("current_password")
    private String currentPassword;

    @NotBlank(message = "El campo new_password es requerido.")
    @Size(min = 6, max = 100, message = "La nueva contraseña debe tener al menos 6 caracteres.")
    @JsonProperty("new_password")
    private String newPassword;

    @NotBlank(message = "El campo new_password_confirmation es requerido.")
    @JsonProperty("new_password_confirmation")
    private String newPasswordConfirmation;
}
