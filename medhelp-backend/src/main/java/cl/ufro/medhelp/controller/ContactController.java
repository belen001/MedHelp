package cl.ufro.medhelp.controller;

import cl.ufro.medhelp.dto.ApiResponse;
import cl.ufro.medhelp.dto.ContactResponse;
import cl.ufro.medhelp.dto.CreateContactRequest;
import cl.ufro.medhelp.dto.UpdateContactRequest;
import cl.ufro.medhelp.service.ContactService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contacts")
@RequiredArgsConstructor
public class ContactController {

    private final ContactService contactService;

    @GetMapping
    public ResponseEntity<ApiResponse> getContacts(
            @RequestParam(required = false) String relationship) {
        List<ContactResponse> data = contactService.getContacts(relationship);
        return ResponseEntity.ok(
                ApiResponse.builder().success(true).data(data).build()
        );
    }

    @PostMapping
    public ResponseEntity<ApiResponse> create(@Valid @RequestBody CreateContactRequest request) {
        ContactResponse data = contactService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.builder()
                        .success(true)
                        .message("Contact registered successfully")
                        .data(data)
                        .build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody UpdateContactRequest request) {
        ContactResponse data = contactService.update(id, request);
        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Contact updated successfully")
                        .data(data)
                        .build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> delete(@PathVariable Long id) {
        contactService.delete(id);
        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Contact deleted successfully")
                        .build());
    }
}
