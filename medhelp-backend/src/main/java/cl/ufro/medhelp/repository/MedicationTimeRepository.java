package cl.ufro.medhelp.repository;

import cl.ufro.medhelp.entity.MedicationTime;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MedicationTimeRepository extends JpaRepository<MedicationTime, Long> {
}
