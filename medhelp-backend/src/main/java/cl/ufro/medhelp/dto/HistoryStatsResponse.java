package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class HistoryStatsResponse {

    private String period;

    @JsonProperty("start_date")
    private String startDate;

    @JsonProperty("end_date")
    private String endDate;

    @JsonProperty("total_doses")
    private int totalDoses;

    @JsonProperty("taken_doses")
    private int takenDoses;

    @JsonProperty("skipped_doses")
    private int skippedDoses;

    @JsonProperty("missed_doses")
    private int missedDoses;

    @JsonProperty("adherence_rate")
    private double adherenceRate;

    @JsonProperty("by_medication")
    private List<MedicationStats> byMedication;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public static class MedicationStats {

        @JsonProperty("medication_id")
        private Long medicationId;

        @JsonProperty("medication_name")
        private String medicationName;

        private int total;
        private int taken;
        private int skipped;
        private int missed;

        @JsonProperty("adherence_rate")
        private double adherenceRate;
    }
}
