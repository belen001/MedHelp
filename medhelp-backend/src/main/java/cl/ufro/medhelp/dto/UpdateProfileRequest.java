package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateProfileRequest {

    @Size(min = 2, max = 120, message = "El nombre debe tener entre 2 y 120 caracteres.")
    private String name;

    @Size(max = 30, message = "El teléfono no puede exceder 30 caracteres.")
    private String phone;

    @JsonFormat(pattern = "yyyy-MM-dd")
    @JsonProperty("birth_date")
    private LocalDate birthDate;

    @JsonProperty("blood_type")
    @Size(max = 5, message = "El tipo de sangre no puede exceder 5 caracteres.")
    private String bloodType;

    private String allergies;

    @JsonProperty("medical_conditions")
    private String medicalConditions;
}
