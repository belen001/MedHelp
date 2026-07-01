package cl.ufro.medhelp.controller;

import cl.ufro.medhelp.dto.*;
import cl.ufro.medhelp.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        // Validate password confirmation
        if (!request.getPassword().equals(request.getPasswordConfirmation())) {
            Map<String, String[]> errors = new HashMap<>();
            errors.put("password", new String[]{"La confirmación de contraseña no coincide."});
            throw new PasswordMismatchException(errors);
        }

        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse> logout(@RequestHeader("Authorization") String authHeader) {
        String token = authHeader.replace("Bearer ", "");
        authService.logout(token);

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Successfully logged out")
                        .build()
        );
    }

    /**
     * Custom exception for password mismatch during registration.
     */
    public static class PasswordMismatchException extends RuntimeException {
        private final Map<String, String[]> errors;

        public PasswordMismatchException(Map<String, String[]> errors) {
            this.errors = errors;
        }

        public Map<String, String[]> getErrors() {
            return errors;
        }
    }
}
