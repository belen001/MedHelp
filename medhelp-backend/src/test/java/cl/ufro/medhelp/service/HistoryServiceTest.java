package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.HistoryResponse;
import cl.ufro.medhelp.dto.HistoryStatsResponse;
import cl.ufro.medhelp.entity.DoseLog;
import cl.ufro.medhelp.entity.DoseStatus;
import cl.ufro.medhelp.entity.Medication;
import cl.ufro.medhelp.repository.DoseLogRepository;
import cl.ufro.medhelp.repository.MedicationRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Collections;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class HistoryServiceTest {

    @Mock
    private DoseLogRepository doseLogRepository;
    @Mock
    private MedicationRepository medicationRepository;

    @InjectMocks
    private HistoryService historyService;

    private static final Long USER_ID = 1L;
    private static final LocalDate TODAY = LocalDate.of(2026, 7, 2);
    private static final LocalDate WEEK_AGO = TODAY.minusDays(7);

    @BeforeEach
    void setUp() {
        var auth = new UsernamePasswordAuthenticationToken(
                "user@test.com", USER_ID,
                List.of(new SimpleGrantedAuthority("ROLE_USER")));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    // ── getHistory ───────────────────────────────────────────

    @Test
    void getHistory_shouldReturnDailyRecordsGroupedByDate() {
        Medication med = Medication.builder().id(10L).name("Lisinopril")
                .dosage("10mg").quantity("1 pastilla").build();

        DoseLog log1 = DoseLog.builder()
                .id(1L).userId(USER_ID).medicationId(10L)
                .doseDate(TODAY).doseTime(LocalTime.of(8, 0))
                .status(DoseStatus.taken).takenAt(LocalDateTime.of(2026, 7, 2, 8, 5))
                .build();
        DoseLog log2 = DoseLog.builder()
                .id(2L).userId(USER_ID).medicationId(10L)
                .doseDate(TODAY).doseTime(LocalTime.of(16, 0))
                .status(DoseStatus.pending).build();

        when(doseLogRepository.findHistoryByDateRange(USER_ID, WEEK_AGO, TODAY))
                .thenReturn(List.of(log1, log2));
        when(medicationRepository.findAllById(Set.of(10L))).thenReturn(List.of(med));

        HistoryResponse result = historyService.getHistory(WEEK_AGO, TODAY);

        assertThat(result.getTotalDoses()).isEqualTo(2);
        assertThat(result.getTakenDoses()).isEqualTo(1);
        assertThat(result.getDailyRecords()).hasSize(1); // both logs on same date
        assertThat(result.getDailyRecords().get(0).getDate()).isEqualTo("2026-07-02");
        assertThat(result.getDailyRecords().get(0).getTaken()).isEqualTo(1);
        assertThat(result.getAdherenceRate()).isEqualTo(50.0);
    }

    @Test
    void getHistory_emptyResult_shouldReturnZeroStats() {
        when(doseLogRepository.findHistoryByDateRange(USER_ID, WEEK_AGO, TODAY))
                .thenReturn(Collections.emptyList());

        HistoryResponse result = historyService.getHistory(WEEK_AGO, TODAY);

        assertThat(result.getTotalDoses()).isZero();
        assertThat(result.getAdherenceRate()).isZero();
        assertThat(result.getDailyRecords()).isEmpty();
    }

    @Test
    void getHistory_nullDates_shouldUseDefaults() {
        when(doseLogRepository.findHistoryByDateRange(
                eq(USER_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(Collections.emptyList());

        historyService.getHistory(null, null);

        verify(doseLogRepository).findHistoryByDateRange(
                eq(USER_ID), any(LocalDate.class), any(LocalDate.class));
    }

    // ── getStats ─────────────────────────────────────────────

    @Test
    void getStats_shouldReturnAdherenceRateAndBreakdownByMedication() {
        List<Object[]> overallStats = List.<Object[]>of(
                new Object[]{10L, 7L, 2L, 1L, 0L}); // total, taken, skipped, missed, pending
        List<Object[]> medStats = List.<Object[]>of(
                new Object[]{10L, "Lisinopril", 10L, 7L, 2L, 1L});

        when(doseLogRepository.findStatsByDateRange(
                eq(USER_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(overallStats);
        when(doseLogRepository.findStatsByMedication(
                eq(USER_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(medStats);

        HistoryStatsResponse result = historyService.getStats(30);

        assertThat(result.getTotalDoses()).isEqualTo(10);
        assertThat(result.getTakenDoses()).isEqualTo(7);
        assertThat(result.getSkippedDoses()).isEqualTo(2);
        assertThat(result.getMissedDoses()).isEqualTo(1);
        assertThat(result.getAdherenceRate()).isEqualTo(70.0);

        assertThat(result.getByMedication()).hasSize(1);
        assertThat(result.getByMedication().get(0).getMedicationName())
                .isEqualTo("Lisinopril");
        assertThat(result.getByMedication().get(0).getAdherenceRate()).isEqualTo(70.0);
    }

    @Test
    void getStats_emptyData_shouldReturnZeros() {
        when(doseLogRepository.findStatsByDateRange(
                eq(USER_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(Collections.emptyList());
        when(doseLogRepository.findStatsByMedication(
                eq(USER_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(Collections.emptyList());

        HistoryStatsResponse result = historyService.getStats(7);

        assertThat(result.getTotalDoses()).isZero();
        assertThat(result.getAdherenceRate()).isZero();
        assertThat(result.getByMedication()).isEmpty();
    }
}
