package cl.ufro.medhelp.controller;

import cl.ufro.medhelp.dto.*;
import cl.ufro.medhelp.service.MedicationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/medications")
@RequiredArgsConstructor
public class MedicationController {

    private final MedicationService medicationService;

    // ── List ────────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<ApiResponse> getMedications(
            @RequestParam(required = false) String status) {
        List<MedicationResponse> data = medicationService.getMedications(status);
        return ResponseEntity.ok(
                ApiResponse.builder().success(true).data(data).build()
        );
    }

    // ── Today Schedule ──────────────────────────────────────────

    @GetMapping("/today")
    public ResponseEntity<ApiResponse> getToday(
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {
        TodayScheduleResponse data = medicationService.getTodaySchedule(date);
        return ResponseEntity.ok(
                ApiResponse.builder().success(true).data(data).build()
        );
    }

    // ── Create ──────────────────────────────────────────────────

    @PostMapping
    public ResponseEntity<ApiResponse> create(@Valid @RequestBody CreateMedicationRequest request) {
        MedicationResponse data = medicationService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.builder()
                        .success(true)
                        .message("Medication registered successfully")
                        .data(data)
                        .build());
    }

    // ── Update ──────────────────────────────────────────────────

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody UpdateMedicationRequest request) {
        MedicationResponse data = medicationService.update(id, request);
        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Medication updated successfully")
                        .data(data)
                        .build());
    }

    // ── Delete ──────────────────────────────────────────────────

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> delete(@PathVariable Long id) {
        medicationService.delete(id);
        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Medication deleted successfully")
                        .build());
    }

    // ── Photo Upload ────────────────────────────────────────────

    @PostMapping("/{id}/photo")
    public ResponseEntity<Map<String, Object>> uploadPhoto(
            @PathVariable Long id,
            @RequestParam("photo") MultipartFile file) {
        String photoUrl = medicationService.uploadPhoto(id, file);
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("success", true);
        body.put("message", "Photo uploaded successfully");
        body.put("photo_url", photoUrl);
        return ResponseEntity.ok(body);
    }
}
