package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdatePreferencesRequest {

    @JsonProperty("push_notifications")
    private Boolean pushNotifications;

    @JsonProperty("alert_sound")
    @Size(max = 80, message = "El sonido de alerta no puede exceder 80 caracteres.")
    private String alertSound;

    @JsonProperty("font_size")
    @Pattern(regexp = "^(pequena|normal|grande)$", message = "font_size debe ser pequena, normal o grande.")
    private String fontSize;

    @Pattern(regexp = "^[a-z]{2}$", message = "language debe ser un código ISO de 2 letras.")
    private String language;
}
