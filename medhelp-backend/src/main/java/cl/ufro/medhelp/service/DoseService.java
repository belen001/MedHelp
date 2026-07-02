package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.ConfirmDoseRequest;
import cl.ufro.medhelp.dto.DoseResponse;
import cl.ufro.medhelp.dto.SkipDoseRequest;
import cl.ufro.medhelp.dto.SnoozeDoseRequest;
import cl.ufro.medhelp.entity.DoseLog;
import cl.ufro.medhelp.entity.DoseSnooze;
import cl.ufro.medhelp.entity.DoseStatus;
import cl.ufro.medhelp.repository.DoseLogRepository;
import cl.ufro.medhelp.repository.DoseSnoozeRepository;
import cl.ufro.medhelp.repository.MedicationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class DoseService {

    private final DoseLogRepository doseLogRepository;
    private final DoseSnoozeRepository doseSnoozeRepository;
    private final MedicationRepository medicationRepository;

    // ── Helpers ──────────────────────────────────────────────────

    private Long getCurrentUserId() {
        return (Long) SecurityContextHolder.getContext()
                .getAuthentication().getCredentials();
    }

    private void verifyMedicationOwnership(Long medicationId, Long userId) {
        medicationRepository.findByIdAndUserId(medicationId, userId)
                .orElseThrow(() -> new MedicationNotFoundException(
                        "Medication not found or does not belong to the user"));
    }

    // ── Confirm ─────────────────────────────────────────────────

    @Transactional
    public DoseResponse confirm(ConfirmDoseRequest request) {
        Long userId = getCurrentUserId();
        verifyMedicationOwnership(request.getMedicationId(), userId);

        Optional<DoseLog> existing = doseLogRepository
                .findByMedicationIdAndDoseDateAndDoseTime(
                        request.getMedicationId(), request.getDoseDate(), request.getDoseTime());

        if (existing.isPresent() && existing.get().getStatus() == DoseStatus.taken) {
            throw new DoseAlreadyConfirmedException(
                    "Dose already confirmed for this date and time");
        }

        DoseLog doseLog = existing.orElseGet(() -> DoseLog.builder()
                .userId(userId)
                .medicationId(request.getMedicationId())
                .doseDate(request.getDoseDate())
                .doseTime(request.getDoseTime())
                .status(DoseStatus.pending)
                .build());

        doseLog.setStatus(DoseStatus.taken);
        doseLog.setTakenAt(LocalDateTime.now());
        doseLog.setSkipReason(null);

        DoseLog saved = doseLogRepository.save(doseLog);
        return mapToResponse(saved);
    }

    // ── Skip ────────────────────────────────────────────────────

    @Transactional
    public DoseResponse skip(SkipDoseRequest request) {
        Long userId = getCurrentUserId();
        verifyMedicationOwnership(request.getMedicationId(), userId);

        Optional<DoseLog> existing = doseLogRepository
                .findByMedicationIdAndDoseDateAndDoseTime(
                        request.getMedicationId(), request.getDoseDate(), request.getDoseTime());

        DoseLog doseLog = existing.orElseGet(() -> DoseLog.builder()
                .userId(userId)
                .medicationId(request.getMedicationId())
                .doseDate(request.getDoseDate())
                .doseTime(request.getDoseTime())
                .status(DoseStatus.pending)
                .build());

        doseLog.setStatus(DoseStatus.skipped);
        doseLog.setSkipReason(request.getReason());
        doseLog.setTakenAt(null);

        DoseLog saved = doseLogRepository.save(doseLog);
        return mapToResponse(saved);
    }

    // ── Snooze ──────────────────────────────────────────────────

    @Transactional
    public DoseResponse snooze(SnoozeDoseRequest request) {
        Long userId = getCurrentUserId();
        verifyMedicationOwnership(request.getMedicationId(), userId);

        Long doseLogId = doseLogRepository
                .findByMedicationIdAndDoseDateAndDoseTime(
                        request.getMedicationId(), request.getDoseDate(), request.getDoseTime())
                .map(DoseLog::getId)
                .orElse(null);

        LocalDateTime newReminderAt = LocalDateTime.now().plusMinutes(request.getMinutes());

        DoseSnooze snooze = DoseSnooze.builder()
                .doseLogId(doseLogId)
                .userId(userId)
                .medicationId(request.getMedicationId())
                .doseDate(request.getDoseDate())
                .doseTime(request.getDoseTime())
                .minutes(request.getMinutes())
                .newReminderAt(newReminderAt)
                .build();

        doseSnoozeRepository.save(snooze);

        DateTimeFormatter dateFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        DateTimeFormatter timeFmt = DateTimeFormatter.ofPattern("HH:mm");
        DateTimeFormatter dtFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        return DoseResponse.builder()
                .medicationId(request.getMedicationId())
                .doseDate(request.getDoseDate().format(dateFmt))
                .doseTime(request.getDoseTime().format(timeFmt))
                .minutes(request.getMinutes())
                .newReminderAt(newReminderAt.format(dtFmt))
                .status("snoozed")
                .build();
    }

    // ── Mapper ──────────────────────────────────────────────────

    private DoseResponse mapToResponse(DoseLog log) {
        DateTimeFormatter dateFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        DateTimeFormatter timeFmt = DateTimeFormatter.ofPattern("HH:mm");
        DateTimeFormatter dtFmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        return DoseResponse.builder()
                .medicationId(log.getMedicationId())
                .doseDate(log.getDoseDate().format(dateFmt))
                .doseTime(log.getDoseTime().format(timeFmt))
                .status(log.getStatus().name())
                .takenAt(log.getTakenAt() != null ? log.getTakenAt().format(dtFmt) : null)
                .skipReason(log.getSkipReason())
                .build();
    }

    // ── Custom exceptions ───────────────────────────────────────

    public static class DoseAlreadyConfirmedException extends RuntimeException {
        public DoseAlreadyConfirmedException(String message) { super(message); }
    }

    public static class MedicationNotFoundException extends RuntimeException {
        public MedicationNotFoundException(String message) { super(message); }
    }
}
