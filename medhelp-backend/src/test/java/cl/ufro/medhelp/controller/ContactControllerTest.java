package cl.ufro.medhelp.controller;

import cl.ufro.medhelp.dto.ContactResponse;
import cl.ufro.medhelp.exception.ContactValidationException;
import cl.ufro.medhelp.exception.GlobalExceptionHandler;
import cl.ufro.medhelp.service.ContactService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class ContactControllerTest {

    @Mock
    private ContactService contactService;

    @InjectMocks
    private ContactController contactController;

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .standaloneSetup(contactController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    // ── GET /api/contacts ────────────────────────────────────

    @Test
    void getContacts_shouldReturn200WithList() throws Exception {
        ContactResponse contact = ContactResponse.builder()
                .id(1L).name("Maria").phone("+56 9 1234 5678")
                .relationship("caregiver").status("available").build();
        when(contactService.getContacts(null)).thenReturn(List.of(contact));

        mockMvc.perform(get("/api/contacts"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].name").value("Maria"));
    }

    @Test
    void getContacts_emptyList_shouldReturn200() throws Exception {
        when(contactService.getContacts(null)).thenReturn(List.of());

        mockMvc.perform(get("/api/contacts"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    // ── POST /api/contacts ───────────────────────────────────

    @Test
    void createContact_shouldReturn201() throws Exception {
        ContactResponse response = ContactResponse.builder()
                .id(10L).name("Juan").phone("+56 9 9999 9999")
                .relationship("family").status("available").build();
        when(contactService.create(any())).thenReturn(response);

        String body = objectMapper.writeValueAsString(Map.of(
                "name", "Juan", "phone", "+56 9 9999 9999", "relationship", "family"));

        mockMvc.perform(post("/api/contacts")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(10));
    }

    @Test
    void createContact_missingName_shouldReturn422() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of("phone", "+56 9 9999 9999"));

        mockMvc.perform(post("/api/contacts")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void createContact_noContactChannel_shouldReturn422() throws Exception {
        Map<String, String[]> errors = Map.of(
                "phone", new String[]{"Se requiere teléfono o email."},
                "email", new String[]{"Se requiere teléfono o email."});
        when(contactService.create(any())).thenThrow(new ContactValidationException(errors));

        String body = objectMapper.writeValueAsString(Map.of("name", "Juan"));

        mockMvc.perform(post("/api/contacts")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.errors.phone").exists());
    }

    // ── PUT /api/contacts/{id} ───────────────────────────────

    @Test
    void updateContact_shouldReturn200() throws Exception {
        ContactResponse response = ContactResponse.builder()
                .id(5L).name("Updated").phone("+56 9 1111 1111")
                .relationship("caregiver").status("available").build();
        when(contactService.update(eq(5L), any())).thenReturn(response);

        String body = objectMapper.writeValueAsString(Map.of("name", "Updated", "phone", "+56 9 1111 1111"));

        mockMvc.perform(put("/api/contacts/5")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Contact updated successfully"));
    }

    @Test
    void updateContact_notFound_shouldReturn404() throws Exception {
        when(contactService.update(eq(999L), any()))
                .thenThrow(new ContactService.ContactNotFoundException("Contact not found"));

        String body = objectMapper.writeValueAsString(Map.of("name", "X", "phone", "+56 9 0000 0000"));

        mockMvc.perform(put("/api/contacts/999")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isNotFound());
    }

    // ── DELETE /api/contacts/{id} ────────────────────────────

    @Test
    void deleteContact_shouldReturn200() throws Exception {
        doNothing().when(contactService).delete(5L);

        mockMvc.perform(delete("/api/contacts/5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Contact deleted successfully"));
    }

    @Test
    void deleteContact_notFound_shouldReturn404() throws Exception {
        doThrow(new ContactService.ContactNotFoundException("Contact not found"))
                .when(contactService).delete(999L);

        mockMvc.perform(delete("/api/contacts/999"))
                .andExpect(status().isNotFound());
    }
}
