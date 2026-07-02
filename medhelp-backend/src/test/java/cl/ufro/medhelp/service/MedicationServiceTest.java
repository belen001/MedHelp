package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.CreateMedicationRequest;
import cl.ufro.medhelp.dto.MedicationResponse;
import cl.ufro.medhelp.dto.TodayScheduleResponse;
import cl.ufro.medhelp.dto.UpdateMedicationRequest;
import cl.ufro.medhelp.entity.*;
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
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MedicationServiceTest {

    @Mock
    private MedicationRepository medicationRepository;
    @Mock
    private DoseLogRepository doseLogRepository;

    @InjectMocks
    private MedicationService medicationService;

    private static final Long USER_ID = 1L;
    private static final LocalDate TODAY = LocalDate.of(2026, 7, 2);

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

    // ── getMedications ───────────────────────────────────────

    @Test
    void getMedications_shouldReturnAllForUser() {
        Medication med = buildMedication(1L, "Lisinopril", MedicationStatus.active,
                List.of(LocalTime.of(8, 0), LocalTime.of(16, 0)));

        when(medicationRepository.findByUserId(USER_ID)).thenReturn(List.of(med));

        List<MedicationResponse> result = medicationService.getMedications(null);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Lisinopril");
        assertThat(result.get(0).getTimes()).containsExactly("08:00", "16:00");
    }

    @Test
    void getMedications_withStatusFilter_shouldFilter() {
        when(medicationRepository.findByUserIdAndStatus(USER_ID, MedicationStatus.active))
                .thenReturn(List.of());

        List<MedicationResponse> result = medicationService.getMedications("active");

        assertThat(result).isEmpty();
    }

    @Test
    void getMedications_invalidStatus_shouldThrowIllegalArgumentException() {
        assertThatThrownBy(() -> medicationService.getMedications("invalid"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    // ── getTodaySchedule ─────────────────────────────────────

    @Test
    void getTodaySchedule_shouldShowCorrectStatusFromDoseLogs() {
        Medication med = buildMedication(1L, "Paracetamol", MedicationStatus.active,
                List.of(LocalTime.of(8, 0)));

        DoseLog takenLog = DoseLog.builder()
                .id(100L).userId(USER_ID).medicationId(1L)
                .doseDate(TODAY).doseTime(LocalTime.of(8, 0))
                .status(DoseStatus.taken)
                .takenAt(LocalDateTime.of(2026, 7, 2, 8, 5))
                .build();

        when(medicationRepository.findTodaySchedule(USER_ID)).thenReturn(List.of(med));
        when(doseLogRepository.findByUserIdAndDoseDateBetween(
                USER_ID, TODAY, TODAY)).thenReturn(List.of(takenLog));

        TodayScheduleResponse result = medicationService.getTodaySchedule(TODAY);

        assertThat(result.getTotal()).isEqualTo(1);
        assertThat(result.getCompleted()).isEqualTo(1);
        assertThat(result.getSchedule()).containsKey("08:00");
        assertThat(result.getSchedule().get("08:00").get(0).getStatus()).isEqualTo("taken");
        assertThat(result.getSchedule().get("08:00").get(0).getTakenAt()).isNotNull();
    }

    @Test
    void getTodaySchedule_pendingDoses_shouldShowPending() {
        Medication med = buildMedication(1L, "Paracetamol", MedicationStatus.active,
                List.of(LocalTime.of(16, 0)));

        // No dose logs — all pending
        when(medicationRepository.findTodaySchedule(USER_ID)).thenReturn(List.of(med));
        when(doseLogRepository.findByUserIdAndDoseDateBetween(
                USER_ID, TODAY, TODAY)).thenReturn(Collections.emptyList());

        TodayScheduleResponse result = medicationService.getTodaySchedule(TODAY);

        assertThat(result.getCompleted()).isZero();
        assertThat(result.getSchedule().get("16:00").get(0).getStatus()).isEqualTo("pending");
    }

    @Test
    void getTodaySchedule_nullDate_shouldUseToday() {
        when(medicationRepository.findTodaySchedule(USER_ID)).thenReturn(Collections.emptyList());
        when(doseLogRepository.findByUserIdAndDoseDateBetween(
                eq(USER_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(Collections.emptyList());

        medicationService.getTodaySchedule(null);

        verify(doseLogRepository).findByUserIdAndDoseDateBetween(
                eq(USER_ID), any(LocalDate.class), any(LocalDate.class));
    }

    // ── create ───────────────────────────────────────────────

    @Test
    void create_shouldPersistMedicationWithTimes() {
        CreateMedicationRequest request = CreateMedicationRequest.builder()
                .name("Ibuprofeno").dosage("400mg").frequency("1 vez al día")
                .quantity("1 cápsula")
                .times(List.of("08:00", "20:00"))
                .startDate(TODAY)
                .build();

        Medication saved = buildMedication(5L, "Ibuprofeno", MedicationStatus.active,
                List.of(LocalTime.of(8, 0), LocalTime.of(20, 0)));
        when(medicationRepository.save(any(Medication.class))).thenReturn(saved);

        MedicationResponse result = medicationService.create(request);

        assertThat(result.getName()).isEqualTo("Ibuprofeno");
        assertThat(result.getTimes()).containsExactly("08:00", "20:00");
    }

    // ── update ───────────────────────────────────────────────

    @Test
    void update_shouldModifyMedicationAndReplaceTimes() {
        UpdateMedicationRequest request = UpdateMedicationRequest.builder()
                .name("Updated").dosage("200mg").frequency("2 veces al día")
                .quantity("2 cápsulas")
                .times(List.of("09:00", "21:00"))
                .startDate(TODAY)
                .build();

        Medication existing = buildMedication(5L, "Original", MedicationStatus.active,
                List.of(LocalTime.of(8, 0)));
        when(medicationRepository.findByIdAndUserId(5L, USER_ID))
                .thenReturn(Optional.of(existing));
        when(medicationRepository.save(any())).thenReturn(existing);

        MedicationResponse result = medicationService.update(5L, request);

        assertThat(result.getName()).isEqualTo("Updated");
        assertThat(result.getTimes()).containsExactly("09:00", "21:00");
    }

    @Test
    void update_nonExistent_shouldThrowNotFoundException() {
        UpdateMedicationRequest request = UpdateMedicationRequest.builder()
                .name("X").dosage("X").frequency("X").quantity("X")
                .times(List.of("08:00")).startDate(TODAY).build();
        when(medicationRepository.findByIdAndUserId(999L, USER_ID))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> medicationService.update(999L, request))
                .isInstanceOf(MedicationService.MedicationNotFoundException.class);
    }

    // ── delete ───────────────────────────────────────────────

    @Test
    void delete_shouldSoftDeleteMedication() {
        Medication existing = buildMedication(5L, "Test", MedicationStatus.active,
                List.of(LocalTime.of(8, 0)));
        when(medicationRepository.findByIdAndUserId(5L, USER_ID))
                .thenReturn(Optional.of(existing));

        medicationService.delete(5L);

        assertThat(existing.getStatus()).isEqualTo(MedicationStatus.deleted);
        verify(medicationRepository).save(existing);
    }

    // ── helper ───────────────────────────────────────────────

    private Medication buildMedication(Long id, String name, MedicationStatus status,
                                       List<LocalTime> times) {
        Medication med = Medication.builder()
                .id(id).userId(USER_ID).name(name)
                .dosage("10mg").frequency("1 vez al día").quantity("1 pastilla")
                .startDate(TODAY).status(status)
                .build();
        List<MedicationTime> timeEntities = times.stream()
                .map(t -> MedicationTime.builder().doseTime(t).medication(med).build())
                .toList();
        med.setTimes(timeEntities);
        return med;
    }
}
