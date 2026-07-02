package cl.ufro.medhelp.controller;

import cl.ufro.medhelp.dto.DoseResponse;
import cl.ufro.medhelp.exception.GlobalExceptionHandler;
import cl.ufro.medhelp.service.DoseService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class DoseControllerTest {

    @Mock
    private DoseService doseService;

    @InjectMocks
    private DoseController doseController;

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .standaloneSetup(doseController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    // ── POST /api/doses/confirm ──────────────────────────────

    @Test
    void confirm_shouldReturn200() throws Exception {
        DoseResponse response = DoseResponse.builder()
                .medicationId(10L).doseDate("2026-07-02").doseTime("08:00")
                .status("taken").takenAt("2026-07-02 08:05:00").build();
        when(doseService.confirm(any())).thenReturn(response);

        String body = objectMapper.writeValueAsString(Map.of(
                "medication_id", 10, "dose_date", "2026-07-02", "dose_time", "08:00"));

        mockMvc.perform(post("/api/doses/confirm")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("taken"))
                .andExpect(jsonPath("$.data.taken_at").value("2026-07-02 08:05:00"));
    }

    @Test
    void confirm_missingMedicationId_shouldReturn422() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "dose_date", "2026-07-02", "dose_time", "08:00"));

        mockMvc.perform(post("/api/doses/confirm")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.errors.medication_id").exists());
    }

    @Test
    void confirm_alreadyTaken_shouldReturn409() throws Exception {
        when(doseService.confirm(any()))
                .thenThrow(new DoseService.DoseAlreadyConfirmedException(
                        "Dose already confirmed for this date and time"));

        String body = objectMapper.writeValueAsString(Map.of(
                "medication_id", 10, "dose_date", "2026-07-02", "dose_time", "08:00"));

        mockMvc.perform(post("/api/doses/confirm")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value(
                        "Dose already confirmed for this date and time"));
    }

    @Test
    void confirm_medicationNotFound_shouldReturn404() throws Exception {
        when(doseService.confirm(any()))
                .thenThrow(new DoseService.MedicationNotFoundException(
                        "Medication not found"));

        String body = objectMapper.writeValueAsString(Map.of(
                "medication_id", 999, "dose_date", "2026-07-02", "dose_time", "08:00"));

        mockMvc.perform(post("/api/doses/confirm")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isNotFound());
    }

    // ── POST /api/doses/skip ─────────────────────────────────

    @Test
    void skip_shouldReturn200() throws Exception {
        DoseResponse response = DoseResponse.builder()
                .medicationId(10L).doseDate("2026-07-02").doseTime("08:00")
                .status("skipped").skipReason("Se me olvidó").build();
        when(doseService.skip(any())).thenReturn(response);

        String body = objectMapper.writeValueAsString(Map.of(
                "medication_id", 10, "dose_date", "2026-07-02",
                "dose_time", "08:00", "reason", "Se me olvidó"));

        mockMvc.perform(post("/api/doses/skip")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.skip_reason").value("Se me olvidó"));
    }

    // ── POST /api/doses/snooze ───────────────────────────────

    @Test
    void snooze_shouldReturn200() throws Exception {
        DoseResponse response = DoseResponse.builder()
                .medicationId(10L).doseDate("2026-07-02").doseTime("08:00")
                .status("snoozed").minutes(15)
                .newReminderAt("2026-07-02 08:15:00").build();
        when(doseService.snooze(any())).thenReturn(response);

        String body = objectMapper.writeValueAsString(Map.of(
                "medication_id", 10, "dose_date", "2026-07-02",
                "dose_time", "08:00", "minutes", 15));

        mockMvc.perform(post("/api/doses/snooze")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.minutes").value(15));
    }

    @Test
    void snooze_minutesOutOfRange_shouldReturn422() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "medication_id", 10, "dose_date", "2026-07-02",
                "dose_time", "08:00", "minutes", 300));

        mockMvc.perform(post("/api/doses/snooze")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.errors.minutes").exists());
    }
}
