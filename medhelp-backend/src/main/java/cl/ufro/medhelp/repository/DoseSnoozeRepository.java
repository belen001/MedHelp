package cl.ufro.medhelp.repository;

import cl.ufro.medhelp.entity.DoseSnooze;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DoseSnoozeRepository extends JpaRepository<DoseSnooze, Long> {

    List<DoseSnooze> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<DoseSnooze> findByUserIdAndMedicationId(Long userId, Long medicationId);
}
