package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.HistoryResponse;
import cl.ufro.medhelp.dto.HistoryResponse.DailyRecord;
import cl.ufro.medhelp.dto.HistoryResponse.DailyRecord.DoseEntry;
import cl.ufro.medhelp.dto.HistoryStatsResponse;
import cl.ufro.medhelp.dto.HistoryStatsResponse.MedicationStats;
import cl.ufro.medhelp.entity.DoseLog;
import cl.ufro.medhelp.entity.Medication;
import cl.ufro.medhelp.repository.DoseLogRepository;
import cl.ufro.medhelp.repository.MedicationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HistoryService {

    private final DoseLogRepository doseLogRepository;
    private final MedicationRepository medicationRepository;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm");
    private static final DateTimeFormatter DT_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private Long getCurrentUserId() {
        return (Long) SecurityContextHolder.getContext()
                .getAuthentication().getCredentials();
    }

    // ── History ─────────────────────────────────────────────────

    public HistoryResponse getHistory(LocalDate startDate, LocalDate endDate) {
        Long userId = getCurrentUserId();

        if (startDate == null) startDate = LocalDate.now().minusDays(7);
        if (endDate == null) endDate = LocalDate.now();

        List<DoseLog> logs = doseLogRepository.findHistoryByDateRange(userId, startDate, endDate);

        // Build medication name cache
        Set<Long> medicationIds = logs.stream()
                .map(DoseLog::getMedicationId)
                .collect(Collectors.toSet());
        Map<Long, Medication> medicationMap = medicationRepository.findAllById(medicationIds).stream()
                .collect(Collectors.toMap(Medication::getId, m -> m));

        // Group by date
        Map<LocalDate, List<DoseLog>> groupedByDate = logs.stream()
                .collect(Collectors.groupingBy(DoseLog::getDoseDate,
                        TreeMap::new, Collectors.toList()));

        int totalTaken = 0;
        int totalSkipped = 0;
        int totalMissed = 0;

        List<DailyRecord> dailyRecords = new ArrayList<>();

        for (Map.Entry<LocalDate, List<DoseLog>> entry : groupedByDate.entrySet()) {
            LocalDate date = entry.getKey();
            List<DoseLog> dayLogs = entry.getValue();

            int dayTotal = dayLogs.size();
            int dayTaken = 0;
            int daySkipped = 0;
            int dayMissed = 0;

            List<DoseEntry> entries = new ArrayList<>();

            for (DoseLog log : dayLogs) {
                Medication med = medicationMap.get(log.getMedicationId());
                String medName = med != null ? med.getName() : "Unknown";
                String dosage = med != null ? med.getDosage() : "";
                String quantity = med != null ? med.getQuantity() : "";

                entries.add(DoseEntry.builder()
                        .medicationId(log.getMedicationId())
                        .medicationName(medName)
                        .dosage(dosage)
                        .quantity(quantity)
                        .doseTime(log.getDoseTime().format(TIME_FMT))
                        .status(log.getStatus().name())
                        .takenAt(log.getTakenAt() != null ? log.getTakenAt().format(DT_FMT) : null)
                        .skipReason(log.getSkipReason())
                        .build());

                switch (log.getStatus()) {
                    case taken -> dayTaken++;
                    case skipped -> daySkipped++;
                    case missed -> dayMissed++;
                }
            }

            totalTaken += dayTaken;
            totalSkipped += daySkipped;
            totalMissed += dayMissed;

            dailyRecords.add(DailyRecord.builder()
                    .date(date.format(DATE_FMT))
                    .total(dayTotal)
                    .taken(dayTaken)
                    .skipped(daySkipped)
                    .missed(dayMissed)
                    .doses(entries)
                    .build());
        }

        int totalDoses = totalTaken + totalSkipped + totalMissed;
        double adherenceRate = totalDoses > 0
                ? BigDecimal.valueOf((double) totalTaken / totalDoses * 100)
                    .setScale(1, RoundingMode.HALF_UP).doubleValue()
                : 0.0;

        return HistoryResponse.builder()
                .period("custom")
                .startDate(startDate.format(DATE_FMT))
                .endDate(endDate.format(DATE_FMT))
                .totalDoses(totalDoses)
                .takenDoses(totalTaken)
                .skippedDoses(totalSkipped)
                .missedDoses(totalMissed)
                .adherenceRate(adherenceRate)
                .dailyRecords(dailyRecords)
                .build();
    }

    // ── Stats ───────────────────────────────────────────────────

    public HistoryStatsResponse getStats(int periodDays) {
        Long userId = getCurrentUserId();

        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(periodDays);

        // Overall stats
        List<Object[]> overallStats = doseLogRepository
                .findStatsByDateRange(userId, startDate, endDate);

        int totalDoses = 0;
        int totalTaken = 0;
        int totalSkipped = 0;
        int totalMissed = 0;

        if (!overallStats.isEmpty()) {
            Object[] row = overallStats.get(0);
            totalDoses = ((Number) row[0]).intValue();
            totalTaken = ((Number) row[1]).intValue();
            totalSkipped = ((Number) row[2]).intValue();
            totalMissed = ((Number) row[3]).intValue();
        }

        double adherenceRate = totalDoses > 0
                ? BigDecimal.valueOf((double) totalTaken / totalDoses * 100)
                    .setScale(1, RoundingMode.HALF_UP).doubleValue()
                : 0.0;

        // By medication stats
        List<Object[]> medStats = doseLogRepository
                .findStatsByMedication(userId, startDate, endDate);

        List<MedicationStats> byMedication = medStats.stream().map(row -> {
            Long medId = ((Number) row[0]).longValue();
            String medName = (String) row[1];
            int total = ((Number) row[2]).intValue();
            int taken = ((Number) row[3]).intValue();
            int skipped = ((Number) row[4]).intValue();
            int missed = ((Number) row[5]).intValue();

            double medAdherence = total > 0
                    ? BigDecimal.valueOf((double) taken / total * 100)
                        .setScale(1, RoundingMode.HALF_UP).doubleValue()
                    : 0.0;

            return MedicationStats.builder()
                    .medicationId(medId)
                    .medicationName(medName)
                    .total(total)
                    .taken(taken)
                    .skipped(skipped)
                    .missed(missed)
                    .adherenceRate(medAdherence)
                    .build();
        }).toList();

        return HistoryStatsResponse.builder()
                .period(periodDays + " days")
                .startDate(startDate.format(DATE_FMT))
                .endDate(endDate.format(DATE_FMT))
                .totalDoses(totalDoses)
                .takenDoses(totalTaken)
                .skippedDoses(totalSkipped)
                .missedDoses(totalMissed)
                .adherenceRate(adherenceRate)
                .byMedication(byMedication)
                .build();
    }
}
