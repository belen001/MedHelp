package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserPreferencesResponse {

    @JsonProperty("push_notifications")
    private Boolean pushNotifications;

    @JsonProperty("alert_sound")
    private String alertSound;

    @JsonProperty("font_size")
    private String fontSize;

    private String language;
}
