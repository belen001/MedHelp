package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.*;
import cl.ufro.medhelp.entity.Medication;
import cl.ufro.medhelp.entity.MedicationStatus;
import cl.ufro.medhelp.entity.MedicationTime;
import cl.ufro.medhelp.repository.MedicationRepository;
import cl.ufro.medhelp.repository.MedicationTimeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@RequiredArgsConstructor
public class MedicationService {

    private final MedicationRepository medicationRepository;
    private final MedicationTimeRepository medicationTimeRepository;

    private static final String PHOTO_STORAGE_DIR = "storage/medications";

    private Long getCurrentUserId() {
        return (Long) SecurityContextHolder.getContext()
                .getAuthentication().getCredentials();
    }

    // ── List ────────────────────────────────────────────────────

    public List<MedicationResponse> getMedications(String statusFilter) {
        Long userId = getCurrentUserId();
        List<Medication> medications;

        if (statusFilter != null && !statusFilter.isBlank()) {
            MedicationStatus status;
            try {
                status = MedicationStatus.valueOf(statusFilter.toLowerCase());
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Estado no válido: " + statusFilter);
            }
            medications = medicationRepository.findByUserIdAndStatus(userId, status);
        } else {
            medications = medicationRepository.findByUserId(userId);
        }

        return medications.stream().map(this::mapToResponse).toList();
    }

    // ── Today Schedule ──────────────────────────────────────────

    public TodayScheduleResponse getTodaySchedule(LocalDate date) {
        Long userId = getCurrentUserId();
        if (date == null) date = LocalDate.now();

        List<Medication> medications = medicationRepository.findTodaySchedule(userId);

        Map<String, List<TodayScheduleResponse.DoseItem>> schedule = new LinkedHashMap<>();
        int total = 0;
        int completed = 0;

        for (Medication med : medications) {
            for (MedicationTime mt : med.getTimes()) {
                String timeKey = mt.getDoseTime().format(DateTimeFormatter.ofPattern("HH:mm"));
                total++;

                // Status is determined later when dose_logs exist; for now: pending
                TodayScheduleResponse.DoseItem item = TodayScheduleResponse.DoseItem.builder()
                        .medicationId(med.getId())
                        .name(med.getName())
                        .dosage(med.getDosage())
                        .quantity(med.getQuantity())
                        .specialInstructions(med.getSpecialInstructions())
                        .status("pending")
                        .takenAt(null)
                        .build();

                schedule.computeIfAbsent(timeKey, k -> new ArrayList<>()).add(item);
            }
        }

        return TodayScheduleResponse.builder()
                .date(date.format(DateTimeFormatter.ISO_LOCAL_DATE))
                .total(total)
                .completed(completed)
                .schedule(schedule)
                .build();
    }

    // ── Create ──────────────────────────────────────────────────

    @Transactional
    public MedicationResponse create(CreateMedicationRequest request) {
        Long userId = getCurrentUserId();

        Medication medication = Medication.builder()
                .userId(userId)
                .name(request.getName())
                .dosage(request.getDosage())
                .frequency(request.getFrequency())
                .quantity(request.getQuantity())
                .startDate(request.getStartDate())
                .specialInstructions(request.getSpecialInstructions())
                .build();

        // Set times
        List<MedicationTime> times = request.getTimes().stream()
                .map(t -> MedicationTime.builder()
                        .doseTime(LocalTime.parse(t))
                        .medication(medication)
                        .build())
                .toList();
        medication.setTimes(times);

        Medication saved = medicationRepository.save(medication);
        return mapToResponse(saved);
    }

    // ── Update ──────────────────────────────────────────────────

    @Transactional
    public MedicationResponse update(Long medicationId, UpdateMedicationRequest request) {
        Long userId = getCurrentUserId();
        Medication medication = medicationRepository.findByIdAndUserId(medicationId, userId)
                .orElseThrow(() -> new MedicationNotFoundException("Medication not found"));

        medication.setName(request.getName());
        medication.setDosage(request.getDosage());
        medication.setFrequency(request.getFrequency());
        medication.setQuantity(request.getQuantity());
        medication.setStartDate(request.getStartDate());
        medication.setSpecialInstructions(request.getSpecialInstructions());

        // Replace times
        List<MedicationTime> times = request.getTimes().stream()
                .map(t -> MedicationTime.builder()
                        .doseTime(LocalTime.parse(t))
                        .medication(medication)
                        .build())
                .toList();
        medication.setTimes(times);

        Medication saved = medicationRepository.save(medication);
        return mapToResponse(saved);
    }

    // ── Delete (soft) ───────────────────────────────────────────

    @Transactional
    public void delete(Long medicationId) {
        Long userId = getCurrentUserId();
        Medication medication = medicationRepository.findByIdAndUserId(medicationId, userId)
                .orElseThrow(() -> new MedicationNotFoundException("Medication not found"));

        medication.setStatus(MedicationStatus.deleted);
        medicationRepository.save(medication);
    }

    // ── Photo Upload ────────────────────────────────────────────

    public String uploadPhoto(Long medicationId, MultipartFile file) {
        Long userId = getCurrentUserId();
        Medication medication = medicationRepository.findByIdAndUserId(medicationId, userId)
                .orElseThrow(() -> new MedicationNotFoundException("Medication not found"));

        try {
            Path storagePath = Paths.get(PHOTO_STORAGE_DIR);
            Files.createDirectories(storagePath);

            String filename = "photo_" + medicationId + "_" + System.currentTimeMillis()
                    + getExtension(file.getOriginalFilename());
            Path filePath = storagePath.resolve(filename);
            Files.write(filePath, file.getBytes());

            String photoUrl = "/" + PHOTO_STORAGE_DIR + "/" + filename;
            medication.setPhotoUrl(photoUrl);
            medicationRepository.save(medication);

            return photoUrl;
        } catch (IOException e) {
            throw new PhotoUploadException("Error al subir la foto: " + e.getMessage());
        }
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return ".jpg";
        return filename.substring(filename.lastIndexOf("."));
    }

    // ── Mapper ──────────────────────────────────────────────────

    private MedicationResponse mapToResponse(Medication med) {
        List<String> timeList = med.getTimes().stream()
                .map(t -> t.getDoseTime().format(DateTimeFormatter.ofPattern("HH:mm")))
                .sorted()
                .toList();

        return MedicationResponse.builder()
                .id(med.getId())
                .name(med.getName())
                .dosage(med.getDosage())
                .frequency(med.getFrequency())
                .quantity(med.getQuantity())
                .times(timeList)
                .startDate(med.getStartDate())
                .specialInstructions(med.getSpecialInstructions())
                .photoUrl(med.getPhotoUrl())
                .status(med.getStatus().name())
                .build();
    }

    // ── Custom exceptions ───────────────────────────────────────

    public static class MedicationNotFoundException extends RuntimeException {
        public MedicationNotFoundException(String message) { super(message); }
    }

    public static class PhotoUploadException extends RuntimeException {
        public PhotoUploadException(String message) { super(message); }
    }
}
