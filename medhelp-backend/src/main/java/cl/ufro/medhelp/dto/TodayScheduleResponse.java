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
public class TodayScheduleResponse {

    private String date;
    private int total;
    private int completed;

    private Map<String, List<DoseItem>> schedule;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DoseItem {

        @JsonProperty("medication_id")
        private Long medicationId;

        private String name;
        private String dosage;
        private String quantity;

        @JsonProperty("special_instructions")
        private String specialInstructions;

        private String status;

        @JsonProperty("taken_at")
        private String takenAt;
    }
}
