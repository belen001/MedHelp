package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.ConfirmDoseRequest;
import cl.ufro.medhelp.dto.DoseResponse;
import cl.ufro.medhelp.dto.SkipDoseRequest;
import cl.ufro.medhelp.dto.SnoozeDoseRequest;
import cl.ufro.medhelp.entity.DoseLog;
import cl.ufro.medhelp.entity.DoseStatus;
import cl.ufro.medhelp.entity.Medication;
import cl.ufro.medhelp.repository.DoseLogRepository;
import cl.ufro.medhelp.repository.DoseSnoozeRepository;
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
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DoseServiceTest {

    @Mock
    private DoseLogRepository doseLogRepository;
    @Mock
    private DoseSnoozeRepository doseSnoozeRepository;
    @Mock
    private MedicationRepository medicationRepository;

    @InjectMocks
    private DoseService doseService;

    private static final Long USER_ID = 1L;
    private static final Long MEDICATION_ID = 10L;
    private static final LocalDate TODAY = LocalDate.of(2026, 7, 2);
    private static final LocalTime DOSE_TIME = LocalTime.of(8, 0);

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

    // ── Confirm ──────────────────────────────────────────────

    @Test
    void confirm_shouldCreateDoseLogAndMarkTaken() {
        ConfirmDoseRequest request = buildConfirmRequest();
        Medication med = Medication.builder().id(MEDICATION_ID).userId(USER_ID).build();
        when(medicationRepository.findByIdAndUserId(MEDICATION_ID, USER_ID))
                .thenReturn(Optional.of(med));
        when(doseLogRepository.findByMedicationIdAndDoseDateAndDoseTime(
                MEDICATION_ID, TODAY, DOSE_TIME)).thenReturn(Optional.empty());
        when(doseLogRepository.save(any(DoseLog.class))).thenAnswer(inv -> {
            DoseLog dl = inv.getArgument(0);
            dl.setId(100L);
            return dl;
        });

        DoseResponse result = doseService.confirm(request);

        assertThat(result.getStatus()).isEqualTo("taken");
        assertThat(result.getMedicationId()).isEqualTo(MEDICATION_ID);
        assertThat(result.getTakenAt()).isNotNull();
    }

    @Test
    void confirm_existingPendingDose_shouldUpdateToTaken() {
        ConfirmDoseRequest request = buildConfirmRequest();
        Medication med = Medication.builder().id(MEDICATION_ID).userId(USER_ID).build();
        DoseLog existing = DoseLog.builder()
                .id(100L).userId(USER_ID).medicationId(MEDICATION_ID)
                .doseDate(TODAY).doseTime(DOSE_TIME).status(DoseStatus.pending)
                .build();

        when(medicationRepository.findByIdAndUserId(MEDICATION_ID, USER_ID))
                .thenReturn(Optional.of(med));
        when(doseLogRepository.findByMedicationIdAndDoseDateAndDoseTime(
                MEDICATION_ID, TODAY, DOSE_TIME)).thenReturn(Optional.of(existing));
        when(doseLogRepository.save(any(DoseLog.class))).thenReturn(existing);

        DoseResponse result = doseService.confirm(request);

        assertThat(result.getStatus()).isEqualTo("taken");
        verify(doseLogRepository, times(1)).save(existing);
    }

    @Test
    void confirm_alreadyTaken_shouldThrowConflictException() {
        ConfirmDoseRequest request = buildConfirmRequest();
        Medication med = Medication.builder().id(MEDICATION_ID).userId(USER_ID).build();
        DoseLog taken = DoseLog.builder()
                .id(100L).userId(USER_ID).medicationId(MEDICATION_ID)
                .doseDate(TODAY).doseTime(DOSE_TIME).status(DoseStatus.taken)
                .build();

        when(medicationRepository.findByIdAndUserId(MEDICATION_ID, USER_ID))
                .thenReturn(Optional.of(med));
        when(doseLogRepository.findByMedicationIdAndDoseDateAndDoseTime(
                MEDICATION_ID, TODAY, DOSE_TIME)).thenReturn(Optional.of(taken));

        assertThatThrownBy(() -> doseService.confirm(request))
                .isInstanceOf(DoseService.DoseAlreadyConfirmedException.class);
    }

    @Test
    void confirm_medicationNotOwned_shouldThrowNotFoundException() {
        ConfirmDoseRequest request = buildConfirmRequest();
        when(medicationRepository.findByIdAndUserId(MEDICATION_ID, USER_ID))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> doseService.confirm(request))
                .isInstanceOf(DoseService.MedicationNotFoundException.class);
    }

    // ── Skip ─────────────────────────────────────────────────

    @Test
    void skip_shouldMarkDoseAsSkippedWithReason() {
        SkipDoseRequest request = SkipDoseRequest.builder()
                .medicationId(MEDICATION_ID).doseDate(TODAY).doseTime(DOSE_TIME)
                .reason("Se me olvidó").build();
        Medication med = Medication.builder().id(MEDICATION_ID).userId(USER_ID).build();

        when(medicationRepository.findByIdAndUserId(MEDICATION_ID, USER_ID))
                .thenReturn(Optional.of(med));
        when(doseLogRepository.findByMedicationIdAndDoseDateAndDoseTime(
                MEDICATION_ID, TODAY, DOSE_TIME)).thenReturn(Optional.empty());
        when(doseLogRepository.save(any(DoseLog.class))).thenAnswer(inv -> {
            DoseLog dl = inv.getArgument(0);
            dl.setId(101L);
            return dl;
        });

        DoseResponse result = doseService.skip(request);

        assertThat(result.getStatus()).isEqualTo("skipped");
        assertThat(result.getSkipReason()).isEqualTo("Se me olvidó");
    }

    @Test
    void skip_shouldOverrideTakingToSkipped() {
        SkipDoseRequest request = SkipDoseRequest.builder()
                .medicationId(MEDICATION_ID).doseDate(TODAY).doseTime(DOSE_TIME).build();
        Medication med = Medication.builder().id(MEDICATION_ID).userId(USER_ID).build();
        DoseLog existing = DoseLog.builder()
                .id(100L).userId(USER_ID).medicationId(MEDICATION_ID)
                .doseDate(TODAY).doseTime(DOSE_TIME).status(DoseStatus.taken)
                .build();

        when(medicationRepository.findByIdAndUserId(MEDICATION_ID, USER_ID))
                .thenReturn(Optional.of(med));
        when(doseLogRepository.findByMedicationIdAndDoseDateAndDoseTime(
                MEDICATION_ID, TODAY, DOSE_TIME)).thenReturn(Optional.of(existing));
        when(doseLogRepository.save(any())).thenReturn(existing);

        DoseResponse result = doseService.skip(request);

        assertThat(result.getStatus()).isEqualTo("skipped");
    }

    // ── Snooze ───────────────────────────────────────────────

    @Test
    void snooze_shouldCreateSnoozeRecord() {
        SnoozeDoseRequest request = SnoozeDoseRequest.builder()
                .medicationId(MEDICATION_ID).doseDate(TODAY).doseTime(DOSE_TIME)
                .minutes(15).build();
        Medication med = Medication.builder().id(MEDICATION_ID).userId(USER_ID).build();

        when(medicationRepository.findByIdAndUserId(MEDICATION_ID, USER_ID))
                .thenReturn(Optional.of(med));
        when(doseLogRepository.findByMedicationIdAndDoseDateAndDoseTime(
                MEDICATION_ID, TODAY, DOSE_TIME)).thenReturn(Optional.empty());

        DoseResponse result = doseService.snooze(request);

        assertThat(result.getStatus()).isEqualTo("snoozed");
        assertThat(result.getMinutes()).isEqualTo(15);
        assertThat(result.getNewReminderAt()).isNotNull();
        verify(doseSnoozeRepository).save(any());
    }

    @Test
    void snooze_medicationNotOwned_shouldThrowNotFoundException() {
        SnoozeDoseRequest request = SnoozeDoseRequest.builder()
                .medicationId(MEDICATION_ID).doseDate(TODAY).doseTime(DOSE_TIME)
                .minutes(30).build();
        when(medicationRepository.findByIdAndUserId(MEDICATION_ID, USER_ID))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> doseService.snooze(request))
                .isInstanceOf(DoseService.MedicationNotFoundException.class);
    }

    // ── helper ───────────────────────────────────────────────

    private ConfirmDoseRequest buildConfirmRequest() {
        return ConfirmDoseRequest.builder()
                .medicationId(MEDICATION_ID).doseDate(TODAY).doseTime(DOSE_TIME)
                .build();
    }
}
