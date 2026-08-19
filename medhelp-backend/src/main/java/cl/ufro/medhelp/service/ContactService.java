package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.ContactResponse;
import cl.ufro.medhelp.dto.CreateContactRequest;
import cl.ufro.medhelp.dto.UpdateContactRequest;
import cl.ufro.medhelp.entity.Contact;
import cl.ufro.medhelp.entity.ContactRelationship;
import cl.ufro.medhelp.entity.ContactStatus;
import cl.ufro.medhelp.exception.ContactValidationException;
import cl.ufro.medhelp.repository.ContactRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ContactService {

    private final ContactRepository contactRepository;

    private Long getCurrentUserId() {
        return (Long) SecurityContextHolder.getContext()
                .getAuthentication().getCredentials();
    }

    public List<ContactResponse> getContacts(String relationshipFilter) {
        Long userId = getCurrentUserId();
        List<Contact> contacts;

        if (relationshipFilter != null && !relationshipFilter.isBlank()) {
            ContactRelationship rel = parseRelationship(relationshipFilter);
            contacts = contactRepository.findByUserIdAndRelationship(userId, rel);
        } else {
            contacts = contactRepository.findByUserId(userId);
        }

        return contacts.stream().map(this::mapToResponse).toList();
    }

    @Transactional
    public ContactResponse create(CreateContactRequest request) {
        validateContactChannels(request.getPhone(), request.getEmail());

        Long userId = getCurrentUserId();

        ContactRelationship rel = ContactRelationship.caregiver;
        if (request.getRelationship() != null && !request.getRelationship().isBlank()) {
            rel = parseRelationship(request.getRelationship());
        }

        ContactStatus statusObj = ContactStatus.available;
        if (request.getStatus() != null && !request.getStatus().isBlank()) {
            statusObj = parseStatus(request.getStatus());
        }

        Contact contact = Contact.builder()
                .userId(userId)
                .name(request.getName())
                .phone(request.getPhone())
                .email(request.getEmail())
                .relationship(rel)
                .status(statusObj)
                .build();

        Contact saved = contactRepository.save(contact);
        return mapToResponse(saved);
    }

    @Transactional
    public ContactResponse update(Long contactId, UpdateContactRequest request) {
        Long userId = getCurrentUserId();
        Contact contact = contactRepository.findByIdAndUserId(contactId, userId)
                .orElseThrow(() -> new ContactNotFoundException("Contact not found"));

        contact.setName(request.getName());
        if (request.getPhone() != null) {
            contact.setPhone(request.getPhone().isBlank() ? null : request.getPhone());
        }
        if (request.getEmail() != null) {
            contact.setEmail(request.getEmail().isBlank() ? null : request.getEmail());
        }

        // Validate that the resulting contact has at least one contact channel
        validateContactChannels(contact.getPhone(), contact.getEmail());

        if (request.getRelationship() != null && !request.getRelationship().isBlank()) {
            contact.setRelationship(parseRelationship(request.getRelationship()));
        }

        if (request.getStatus() != null && !request.getStatus().isBlank()) {
            contact.setStatus(parseStatus(request.getStatus()));
        }

        Contact saved = contactRepository.save(contact);
        return mapToResponse(saved);
    }

    @Transactional
    public void delete(Long contactId) {
        Long userId = getCurrentUserId();
        Contact contact = contactRepository.findByIdAndUserId(contactId, userId)
                .orElseThrow(() -> new ContactNotFoundException("Contact not found"));

        contactRepository.delete(contact);
    }

    private ContactRelationship parseRelationship(String value) {
        try {
            return ContactRelationship.valueOf(value.toLowerCase());
        } catch (IllegalArgumentException e) {
            Map<String, String[]> errors = new HashMap<>();
            errors.put("relationship", new String[]{"Relación no válida: " + value});
            throw new ContactValidationException(errors);
        }
    }

    private ContactStatus parseStatus(String value) {
        try {
            return ContactStatus.valueOf(value.toLowerCase());
        } catch (IllegalArgumentException e) {
            Map<String, String[]> errors = new HashMap<>();
            errors.put("status", new String[]{"Estado no válido: " + value});
            throw new ContactValidationException(errors);
        }
    }

    private void validateContactChannels(String phone, String email) {
        boolean hasPhone = phone != null && !phone.isBlank();
        boolean hasEmail = email != null && !email.isBlank();
        if (!hasPhone && !hasEmail) {
            Map<String, String[]> errors = new HashMap<>();
            errors.put("phone", new String[]{"Debe proporcionar al menos un canal de contacto (teléfono o email)."});
            errors.put("email", new String[]{"Debe proporcionar al menos un canal de contacto (teléfono o email)."});
            throw new ContactValidationException(errors);
        }
    }

    private ContactResponse mapToResponse(Contact contact) {
        return ContactResponse.builder()
                .id(contact.getId())
                .name(contact.getName())
                .phone(contact.getPhone())
                .email(contact.getEmail())
                .relationship(contact.getRelationship().name())
                .status(contact.getStatus().name())
                .build();
    }

    public static class ContactNotFoundException extends RuntimeException {
        public ContactNotFoundException(String message) {
            super(message);
        }
    }
}
