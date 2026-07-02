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
public class DoseResponse {

    @JsonProperty("medication_id")
    private Long medicationId;

    @JsonProperty("dose_date")
    private String doseDate;

    @JsonProperty("dose_time")
    private String doseTime;

    @JsonProperty("taken_at")
    private String takenAt;

    private String status;

    @JsonProperty("skip_reason")
    private String skipReason;

    @JsonProperty("new_reminder_at")
    private String newReminderAt;

    private Integer minutes;
}
