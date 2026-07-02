package cl.ufro.medhelp.dto;

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
public class CreateContactRequest {

    @NotBlank(message = "El campo name es requerido.")
    @Size(max = 120, message = "El nombre no puede exceder 120 caracteres.")
    private String name;

    @Size(max = 30, message = "El teléfono no puede exceder 30 caracteres.")
    private String phone;

    @Email(message = "El formato del email no es válido.")
    @Size(max = 160, message = "El email no puede exceder 160 caracteres.")
    private String email;

    private String relationship;

    private String status;
}
