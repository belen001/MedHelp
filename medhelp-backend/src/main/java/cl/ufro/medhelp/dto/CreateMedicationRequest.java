package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateMedicationRequest {

    @NotBlank(message = "El campo name es requerido.")
    @Size(max = 160, message = "El nombre no puede exceder 160 caracteres.")
    private String name;

    @NotBlank(message = "El campo dosage es requerido.")
    @Size(max = 80, message = "La dosis no puede exceder 80 caracteres.")
    private String dosage;

    @NotBlank(message = "El campo frequency es requerido.")
    @Size(max = 120, message = "La frecuencia no puede exceder 120 caracteres.")
    private String frequency;

    @NotBlank(message = "El campo quantity es requerido.")
    @Size(max = 80, message = "La cantidad no puede exceder 80 caracteres.")
    private String quantity;

    @NotEmpty(message = "Debe indicar al menos un horario.")
    private List<String> times;

    @NotNull(message = "El campo start_date es requerido.")
    @JsonFormat(pattern = "yyyy-MM-dd")
    @JsonProperty("start_date")
    private LocalDate startDate;

    @JsonProperty("special_instructions")
    private String specialInstructions;

    private String photo;
}
