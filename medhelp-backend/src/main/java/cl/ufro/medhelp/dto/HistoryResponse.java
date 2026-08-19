package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class HistoryResponse {

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

    @JsonProperty("daily_records")
    private List<DailyRecord> dailyRecords;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public static class DailyRecord {

        private String date;
        private int total;
        private int taken;
        private int skipped;
        private int missed;

        private List<DoseEntry> doses;

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        @JsonInclude(JsonInclude.Include.NON_NULL)
        public static class DoseEntry {

            @JsonProperty("medication_id")
            private Long medicationId;

            @JsonProperty("medication_name")
            private String medicationName;

            private String dosage;
            private String quantity;

            @JsonProperty("dose_time")
            private String doseTime;

            private String status;

            @JsonProperty("taken_at")
            private String takenAt;

            @JsonProperty("skip_reason")
            private String skipReason;
        }
    }
}
