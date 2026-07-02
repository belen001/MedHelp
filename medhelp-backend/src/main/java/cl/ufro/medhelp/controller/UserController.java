package cl.ufro.medhelp.controller;

import cl.ufro.medhelp.dto.*;
import cl.ufro.medhelp.exception.PasswordMismatchException;
import cl.ufro.medhelp.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // ── Profile ─────────────────────────────────────────────────

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse> getProfile() {
        UserProfileResponse profile = userService.getProfile();
        return ResponseEntity.ok(
                ApiResponse.builder().success(true).data(profile).build()
        );
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse> updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        UserProfileResponse profile = userService.updateProfile(request);
        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Profile updated successfully")
                        .data(profile)
                        .build()
        );
    }

    // ── Preferences ─────────────────────────────────────────────

    @GetMapping("/preferences")
    public ResponseEntity<ApiResponse> getPreferences() {
        UserPreferencesResponse prefs = userService.getPreferences();
        return ResponseEntity.ok(
                ApiResponse.builder().success(true).data(prefs).build()
        );
    }

    @PutMapping("/preferences")
    public ResponseEntity<ApiResponse> updatePreferences(@Valid @RequestBody UpdatePreferencesRequest request) {
        UserPreferencesResponse prefs = userService.updatePreferences(request);
        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Preferences updated successfully")
                        .data(prefs)
                        .build()
        );
    }

    // ── Change Password ─────────────────────────────────────────

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        if (!request.getNewPassword().equals(request.getNewPasswordConfirmation())) {
            Map<String, String[]> errors = new HashMap<>();
            errors.put("new_password", new String[]{"La confirmación de la nueva contraseña no coincide."});
            throw new PasswordMismatchException(errors);
        }

        userService.changePassword(request);

        return ResponseEntity.ok(
                ApiResponse.builder()
                        .success(true)
                        .message("Password changed successfully")
                        .build()
        );
    }
}
