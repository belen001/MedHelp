package cl.ufro.medhelp.controller;

import cl.ufro.medhelp.dto.ApiResponse;
import cl.ufro.medhelp.dto.ConfirmDoseRequest;
import cl.ufro.medhelp.dto.DoseResponse;
import cl.ufro.medhelp.dto.SkipDoseRequest;
import cl.ufro.medhelp.dto.SnoozeDoseRequest;
import cl.ufro.medhelp.service.DoseService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/doses")
@RequiredArgsConstructor
public class DoseController {

    private final DoseService doseService;

    // ── Confirm ────────────────────────────────────────────────

    @PostMapping("/confirm")
    public ResponseEntity<ApiResponse> confirm(@Valid @RequestBody ConfirmDoseRequest request) {
        DoseResponse data = doseService.confirm(request);
        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Dose confirmed")
                        .data(data)
                        .build());
    }

    // ── Skip ───────────────────────────────────────────────────

    @PostMapping("/skip")
    public ResponseEntity<ApiResponse> skip(@Valid @RequestBody SkipDoseRequest request) {
        DoseResponse data = doseService.skip(request);
        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Dose skipped")
                        .data(data)
                        .build());
    }

    // ── Snooze ─────────────────────────────────────────────────

    @PostMapping("/snooze")
    public ResponseEntity<ApiResponse> snooze(@Valid @RequestBody SnoozeDoseRequest request) {
        DoseResponse data = doseService.snooze(request);
        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Dose snoozed successfully")
                        .data(data)
                        .build());
    }
}
