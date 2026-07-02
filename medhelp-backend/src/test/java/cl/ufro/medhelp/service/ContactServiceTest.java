package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.ContactResponse;
import cl.ufro.medhelp.dto.CreateContactRequest;
import cl.ufro.medhelp.dto.UpdateContactRequest;
import cl.ufro.medhelp.entity.Contact;
import cl.ufro.medhelp.entity.ContactRelationship;
import cl.ufro.medhelp.entity.ContactStatus;
import cl.ufro.medhelp.exception.ContactValidationException;
import cl.ufro.medhelp.repository.ContactRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ContactServiceTest {

    @Mock
    private ContactRepository contactRepository;

    @InjectMocks
    private ContactService contactService;

    private static final Long USER_ID = 1L;

    @BeforeEach
    void setUp() {
        var auth = new UsernamePasswordAuthenticationToken(
                "user@test.com", USER_ID,
                List.of(new SimpleGrantedAuthority("ROLE_USER")));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    // ── getContacts ──────────────────────────────────────────

    @Test
    void getContacts_shouldReturnAllContactsForUser() {
        Contact contact = buildContact(1L, "Maria", ContactRelationship.caregiver);
        when(contactRepository.findByUserId(USER_ID)).thenReturn(List.of(contact));

        List<ContactResponse> result = contactService.getContacts(null);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("Maria");
        assertThat(result.get(0).getRelationship()).isEqualTo("caregiver");
    }

    @Test
    void getContacts_withRelationshipFilter_shouldFilterCorrectly() {
        Contact contact = buildContact(1L, "Doctor", ContactRelationship.monitor);
        when(contactRepository.findByUserIdAndRelationship(USER_ID, ContactRelationship.monitor))
                .thenReturn(List.of(contact));

        List<ContactResponse> result = contactService.getContacts("monitor");

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getRelationship()).isEqualTo("monitor");
    }

    @Test
    void getContacts_withCaseInsensitiveFilter_shouldWork() {
        when(contactRepository.findByUserIdAndRelationship(USER_ID, ContactRelationship.caregiver))
                .thenReturn(List.of());

        List<ContactResponse> result = contactService.getContacts("CAREGIVER");

        assertThat(result).isEmpty();
        verify(contactRepository).findByUserIdAndRelationship(USER_ID, ContactRelationship.caregiver);
    }

    @Test
    void getContacts_withInvalidRelationship_shouldThrowValidationException() {
        assertThatThrownBy(() -> contactService.getContacts("invalid_role"))
                .isInstanceOf(ContactValidationException.class)
                .extracting("errors")
                .satisfies(errors -> {
                    @SuppressWarnings("unchecked")
                    var map = (java.util.Map<String, String[]>) errors;
                    assertThat(map).containsKey("relationship");
                });
    }

    // ── create ───────────────────────────────────────────────

    @Test
    void create_shouldPersistAndReturnContact() {
        CreateContactRequest request = CreateContactRequest.builder()
                .name("Juan").phone("+56 9 1234 5678")
                .relationship("family").status("available")
                .build();

        Contact saved = buildContact(10L, "Juan", ContactRelationship.family);
        when(contactRepository.save(any(Contact.class))).thenReturn(saved);

        ContactResponse result = contactService.create(request);

        assertThat(result.getId()).isEqualTo(10L);
        assertThat(result.getName()).isEqualTo("Juan");
        assertThat(result.getRelationship()).isEqualTo("family");
        assertThat(result.getStatus()).isEqualTo("available");

        ArgumentCaptor<Contact> captor = ArgumentCaptor.forClass(Contact.class);
        verify(contactRepository).save(captor.capture());
        assertThat(captor.getValue().getUserId()).isEqualTo(USER_ID);
    }

    @Test
    void create_withoutPhoneOrEmail_shouldThrowValidationException() {
        CreateContactRequest request = CreateContactRequest.builder()
                .name("Juan").build();

        assertThatThrownBy(() -> contactService.create(request))
                .isInstanceOf(ContactValidationException.class);
    }

    @Test
    void create_withOnlyEmail_shouldSucceed() {
        CreateContactRequest request = CreateContactRequest.builder()
                .name("Juan").email("juan@test.com").build();
        when(contactRepository.save(any(Contact.class))).thenAnswer(inv -> {
            Contact c = inv.getArgument(0);
            c.setId(10L);
            return c;
        });

        ContactResponse result = contactService.create(request);

        assertThat(result.getEmail()).isEqualTo("juan@test.com");
    }

    @Test
    void create_withInvalidRelationship_shouldThrowValidationException() {
        CreateContactRequest request = CreateContactRequest.builder()
                .name("Juan").phone("+56 9 1234 5678")
                .relationship("nonexistent").build();

        assertThatThrownBy(() -> contactService.create(request))
                .isInstanceOf(ContactValidationException.class);
    }

    // ── update ───────────────────────────────────────────────

    @Test
    void update_shouldModifyAndReturnContact() {
        UpdateContactRequest request = UpdateContactRequest.builder()
                .name("Maria Updated").phone("+56 9 9999 9999")
                .relationship("family").build();

        Contact existing = buildContact(5L, "Maria", ContactRelationship.caregiver);
        when(contactRepository.findByIdAndUserId(5L, USER_ID)).thenReturn(Optional.of(existing));
        when(contactRepository.save(any(Contact.class))).thenReturn(existing);

        ContactResponse result = contactService.update(5L, request);

        assertThat(result.getName()).isEqualTo("Maria Updated");
        assertThat(result.getRelationship()).isEqualTo("family");
        verify(contactRepository).save(existing);
    }

    @Test
    void update_nonExistentContact_shouldThrowNotFoundException() {
        UpdateContactRequest request = UpdateContactRequest.builder()
                .name("N/A").phone("+56 9 0000 0000").build();
        when(contactRepository.findByIdAndUserId(999L, USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> contactService.update(999L, request))
                .isInstanceOf(ContactService.ContactNotFoundException.class);
    }

    @Test
    void update_clearingBothChannels_shouldThrowValidationException() {
        // Contact only has phone; update clears phone without providing email
        UpdateContactRequest request = UpdateContactRequest.builder()
                .name("Maria").phone("").email(null).build();

        Contact existing = Contact.builder()
                .id(5L).userId(USER_ID).name("Maria")
                .phone("+56 9 6000 0000").email(null)  // no email, only phone
                .relationship(ContactRelationship.caregiver)
                .status(ContactStatus.available)
                .build();
        when(contactRepository.findByIdAndUserId(5L, USER_ID)).thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> contactService.update(5L, request))
                .isInstanceOf(ContactValidationException.class);
    }

    // ── delete ───────────────────────────────────────────────

    @Test
    void delete_shouldHardDeleteContact() {
        Contact existing = buildContact(5L, "Maria", ContactRelationship.caregiver);
        when(contactRepository.findByIdAndUserId(5L, USER_ID)).thenReturn(Optional.of(existing));

        contactService.delete(5L);

        verify(contactRepository).delete(existing);
    }

    @Test
    void delete_nonExistentContact_shouldThrowNotFoundException() {
        when(contactRepository.findByIdAndUserId(999L, USER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> contactService.delete(999L))
                .isInstanceOf(ContactService.ContactNotFoundException.class);
    }

    // ── helpers ──────────────────────────────────────────────

    private Contact buildContact(Long id, String name, ContactRelationship relationship) {
        return Contact.builder()
                .id(id).userId(USER_ID).name(name)
                .phone("+56 9 6000 0000").email("test@test.com")
                .relationship(relationship).status(ContactStatus.available)
                .build();
    }
}
