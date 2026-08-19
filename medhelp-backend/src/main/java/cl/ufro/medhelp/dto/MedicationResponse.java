package cl.ufro.medhelp.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
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
public class MedicationResponse {

    private Long id;
    private String name;
    private String dosage;
    private String frequency;
    private String quantity;

    private List<String> times;

    @JsonFormat(pattern = "yyyy-MM-dd")
    @JsonProperty("start_date")
    private LocalDate startDate;

    @JsonProperty("special_instructions")
    private String specialInstructions;

    @JsonProperty("photo_url")
    private String photoUrl;

    private String status;
}
