package cl.ufro.medhelp.repository;

import cl.ufro.medhelp.entity.DoseLog;
import cl.ufro.medhelp.entity.DoseStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface DoseLogRepository extends JpaRepository<DoseLog, Long> {

    Optional<DoseLog> findByMedicationIdAndDoseDateAndDoseTime(
            Long medicationId, LocalDate doseDate, LocalTime doseTime);

    List<DoseLog> findByUserIdAndMedicationIdAndDoseDate(
            Long userId, Long medicationId, LocalDate doseDate);

    List<DoseLog> findByUserIdAndDoseDateBetween(
            Long userId, LocalDate startDate, LocalDate endDate);

    @Query(value = """
        SELECT dl.* FROM dose_logs dl
        WHERE dl.user_id = :userId
          AND dl.dose_date BETWEEN :startDate AND :endDate
        ORDER BY dl.dose_date DESC, dl.dose_time ASC
        """, nativeQuery = true)
    List<DoseLog> findHistoryByDateRange(@Param("userId") Long userId,
                                         @Param("startDate") LocalDate startDate,
                                         @Param("endDate") LocalDate endDate);

    @Query(value = """
        SELECT
            COUNT(*) AS total,
            SUM(CASE WHEN dl.status = 'taken' THEN 1 ELSE 0 END) AS taken,
            SUM(CASE WHEN dl.status = 'skipped' THEN 1 ELSE 0 END) AS skipped,
            SUM(CASE WHEN dl.status = 'missed' THEN 1 ELSE 0 END) AS missed,
            SUM(CASE WHEN dl.status = 'pending' THEN 1 ELSE 0 END) AS pending
        FROM dose_logs dl
        WHERE dl.user_id = :userId
          AND dl.dose_date BETWEEN :startDate AND :endDate
        """, nativeQuery = true)
    List<Object[]> findStatsByDateRange(@Param("userId") Long userId,
                                        @Param("startDate") LocalDate startDate,
                                        @Param("endDate") LocalDate endDate);

    @Query(value = """
        SELECT
            dl.medication_id,
            m.name,
            COUNT(*) AS total,
            SUM(CASE WHEN dl.status = 'taken' THEN 1 ELSE 0 END) AS taken,
            SUM(CASE WHEN dl.status = 'skipped' THEN 1 ELSE 0 END) AS skipped,
            SUM(CASE WHEN dl.status = 'missed' THEN 1 ELSE 0 END) AS missed
        FROM dose_logs dl
        INNER JOIN medications m ON m.id = dl.medication_id
        WHERE dl.user_id = :userId
          AND dl.dose_date BETWEEN :startDate AND :endDate
        GROUP BY dl.medication_id, m.name
        ORDER BY m.name
        """, nativeQuery = true)
    List<Object[]> findStatsByMedication(@Param("userId") Long userId,
                                         @Param("startDate") LocalDate startDate,
                                         @Param("endDate") LocalDate endDate);
}
