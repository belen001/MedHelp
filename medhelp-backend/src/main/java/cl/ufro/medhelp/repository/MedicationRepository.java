package cl.ufro.medhelp.repository;

import cl.ufro.medhelp.entity.Medication;
import cl.ufro.medhelp.entity.MedicationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MedicationRepository extends JpaRepository<Medication, Long> {

    List<Medication> findByUserIdAndStatus(Long userId, MedicationStatus status);

    List<Medication> findByUserId(Long userId);

    Optional<Medication> findByIdAndUserId(Long id, Long userId);

    @Query(value = """
        SELECT m.* FROM medications m
        INNER JOIN medication_times mt ON mt.medication_id = m.id
        WHERE m.user_id = :userId AND m.status = 'active'
        ORDER BY mt.dose_time
        """, nativeQuery = true)
    List<Medication> findTodaySchedule(@Param("userId") Long userId);
}
