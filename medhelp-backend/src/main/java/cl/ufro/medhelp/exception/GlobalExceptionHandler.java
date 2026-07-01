package cl.ufro.medhelp.exception;

import cl.ufro.medhelp.controller.AuthController;
import cl.ufro.medhelp.dto.ApiResponse;
import cl.ufro.medhelp.service.AuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String[]> errors = new HashMap<>();

        ex.getBindingResult().getFieldErrors().forEach(error -> {
            String field = error.getField();
            // Map Java camelCase fields to snake_case for API response
            if ("passwordConfirmation".equals(field)) {
                field = "password_confirmation";
            }
            // Keep only the first error per field
            errors.putIfAbsent(field, new String[]{error.getDefaultMessage()});
        });

        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ApiResponse.builder()
                        .success(false)
                        .errors(errors)
                        .build());
    }

    @ExceptionHandler(AuthService.EmailAlreadyExistsException.class)
    public ResponseEntity<ApiResponse> handleEmailAlreadyExists(AuthService.EmailAlreadyExistsException ex) {
        Map<String, String[]> errors = new HashMap<>();
        errors.put("email", new String[]{ex.getMessage()});

        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ApiResponse.builder()
                        .success(false)
                        .errors(errors)
                        .build());
    }

    @ExceptionHandler(AuthService.InvalidCredentialsException.class)
    public ResponseEntity<ApiResponse> handleInvalidCredentials(AuthService.InvalidCredentialsException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.builder()
                        .success(false)
                        .message(ex.getMessage())
                        .build());
    }

    @ExceptionHandler(AuthController.PasswordMismatchException.class)
    public ResponseEntity<ApiResponse> handlePasswordMismatch(AuthController.PasswordMismatchException ex) {
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ApiResponse.builder()
                        .success(false)
                        .errors(ex.getErrors())
                        .build());
    }
}
