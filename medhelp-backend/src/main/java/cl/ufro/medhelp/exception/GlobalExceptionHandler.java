package cl.ufro.medhelp.exception;

import cl.ufro.medhelp.controller.AuthController;
import cl.ufro.medhelp.controller.UserController;
import cl.ufro.medhelp.dto.ApiResponse;
import cl.ufro.medhelp.service.AuthService;
import cl.ufro.medhelp.service.MedicationService;
import cl.ufro.medhelp.service.UserService;
import cl.ufro.medhelp.service.ContactService;
import cl.ufro.medhelp.service.DoseService;
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
            } else if ("newPasswordConfirmation".equals(field)) {
                field = "new_password_confirmation";
            } else if ("currentPassword".equals(field)) {
                field = "current_password";
            } else if ("newPassword".equals(field)) {
                field = "new_password";
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

    @ExceptionHandler(UserController.PasswordMismatchException.class)
    public ResponseEntity<ApiResponse> handleUserPasswordMismatch(UserController.PasswordMismatchException ex) {
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ApiResponse.builder()
                        .success(false)
                        .errors(ex.getErrors())
                        .build());
    }

    @ExceptionHandler(UserService.InvalidPasswordException.class)
    public ResponseEntity<ApiResponse> handleInvalidPassword(UserService.InvalidPasswordException ex) {
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ApiResponse.builder()
                        .success(false)
                        .message(ex.getMessage())
                        .build());
    }

    @ExceptionHandler(MedicationService.MedicationNotFoundException.class)
    public ResponseEntity<ApiResponse> handleMedicationNotFound(MedicationService.MedicationNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.builder()
                        .success(false)
                        .message(ex.getMessage())
                        .build());
    }

    @ExceptionHandler(MedicationService.PhotoUploadException.class)
    public ResponseEntity<ApiResponse> handlePhotoUpload(MedicationService.PhotoUploadException ex) {
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ApiResponse.builder()
                        .success(false)
                        .message(ex.getMessage())
                        .build());
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse> handleIllegalArgument(IllegalArgumentException ex) {
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ApiResponse.builder()
                        .success(false)
                        .message(ex.getMessage())
                        .build());
    }

    @ExceptionHandler(ContactValidationException.class)
    public ResponseEntity<ApiResponse> handleContactValidation(ContactValidationException ex) {
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(ApiResponse.builder()
                        .success(false)
                        .errors(ex.getErrors())
                        .build());
    }

    @ExceptionHandler(ContactService.ContactNotFoundException.class)
    public ResponseEntity<ApiResponse> handleContactNotFound(ContactService.ContactNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.builder()
                        .success(false)
                        .message(ex.getMessage())
                        .build());
    }

    @ExceptionHandler(DoseService.DoseAlreadyConfirmedException.class)
    public ResponseEntity<ApiResponse> handleDoseAlreadyConfirmed(DoseService.DoseAlreadyConfirmedException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.builder()
                        .success(false)
                        .message(ex.getMessage())
                        .build());
    }

    @ExceptionHandler(DoseService.MedicationNotFoundException.class)
    public ResponseEntity<ApiResponse> handleDoseMedicationNotFound(DoseService.MedicationNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.builder()
                        .success(false)
                        .message(ex.getMessage())
                        .build());
    }
}
