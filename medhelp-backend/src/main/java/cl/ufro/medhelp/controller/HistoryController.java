package cl.ufro.medhelp.controller;

import cl.ufro.medhelp.dto.ApiResponse;
import cl.ufro.medhelp.dto.HistoryResponse;
import cl.ufro.medhelp.dto.HistoryStatsResponse;
import cl.ufro.medhelp.service.HistoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/history")
@RequiredArgsConstructor
public class HistoryController {

    private final HistoryService historyService;

    // ── History ────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<ApiResponse> getHistory(
            @RequestParam(required = false)
            @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam(required = false)
            @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate) {
        HistoryResponse data = historyService.getHistory(startDate, endDate);
        return ResponseEntity.ok(
                ApiResponse.builder().success(true).data(data).build());
    }

    // ── Stats ──────────────────────────────────────────────────

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse> getStats(
            @RequestParam(defaultValue = "30") int period) {
        HistoryStatsResponse data = historyService.getStats(period);
        return ResponseEntity.ok(
                ApiResponse.builder().success(true).data(data).build());
    }
}
