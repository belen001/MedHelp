package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConfirmDoseRequest {

    @NotNull(message = "El campo medication_id es requerido.")
    @JsonProperty("medication_id")
    private Long medicationId;

    @NotNull(message = "El campo dose_date es requerido.")
    @JsonFormat(pattern = "yyyy-MM-dd")
    @JsonProperty("dose_date")
    private LocalDate doseDate;

    @NotNull(message = "El campo dose_time es requerido.")
    @JsonFormat(pattern = "HH:mm")
    @JsonProperty("dose_time")
    private LocalTime doseTime;

    @JsonProperty("taken_at")
    private String takenAt;
}
