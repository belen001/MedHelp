package cl.ufro.medhelp.repository;

import cl.ufro.medhelp.entity.Contact;
import cl.ufro.medhelp.entity.ContactRelationship;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ContactRepository extends JpaRepository<Contact, Long> {
    List<Contact> findByUserId(Long userId);
    List<Contact> findByUserIdAndRelationship(Long userId, ContactRelationship relationship);
    Optional<Contact> findByIdAndUserId(Long id, Long userId);
}
