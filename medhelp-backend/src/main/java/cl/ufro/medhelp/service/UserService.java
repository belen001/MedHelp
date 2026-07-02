package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.*;
import cl.ufro.medhelp.entity.FontSizeOption;
import cl.ufro.medhelp.entity.User;
import cl.ufro.medhelp.entity.UserPreferences;
import cl.ufro.medhelp.repository.UserPreferencesRepository;
import cl.ufro.medhelp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserPreferencesRepository userPreferencesRepository;
    private final PasswordEncoder passwordEncoder;

    // ── Helper: obtener userId del token JWT ─────────────────────
    private Long getCurrentUserId() {
        return (Long) SecurityContextHolder.getContext()
                .getAuthentication().getCredentials();
    }

    // ── Profile ─────────────────────────────────────────────────

    public UserProfileResponse getProfile() {
        User user = userRepository.findById(getCurrentUserId())
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        return mapToProfileResponse(user);
    }

    @Transactional
    public UserProfileResponse updateProfile(UpdateProfileRequest request) {
        User user = userRepository.findById(getCurrentUserId())
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (request.getName() != null) user.setName(request.getName());
        if (request.getPhone() != null) user.setPhone(request.getPhone());
        if (request.getBirthDate() != null) user.setBirthDate(request.getBirthDate());
        if (request.getBloodType() != null) user.setBloodType(request.getBloodType());
        if (request.getAllergies() != null) user.setAllergies(request.getAllergies());
        if (request.getMedicalConditions() != null) user.setMedicalConditions(request.getMedicalConditions());

        user = userRepository.save(user);
        return mapToProfileResponse(user);
    }

    // ── Preferences ─────────────────────────────────────────────

    public UserPreferencesResponse getPreferences() {
        Long userId = getCurrentUserId();
        UserPreferences prefs = userPreferencesRepository.findByUserId(userId)
                .orElseGet(() -> createDefaultPreferences(userId));

        return mapToPreferencesResponse(prefs);
    }

    @Transactional
    public UserPreferencesResponse updatePreferences(UpdatePreferencesRequest request) {
        Long userId = getCurrentUserId();
        UserPreferences prefs = userPreferencesRepository.findByUserId(userId)
                .orElseGet(() -> createDefaultPreferences(userId));

        if (request.getPushNotifications() != null) prefs.setPushNotifications(request.getPushNotifications());
        if (request.getAlertSound() != null) prefs.setAlertSound(request.getAlertSound());
        if (request.getFontSize() != null) prefs.setFontSize(FontSizeOption.valueOf(request.getFontSize()));
        if (request.getLanguage() != null) prefs.setLanguage(request.getLanguage());

        prefs = userPreferencesRepository.save(prefs);
        return mapToPreferencesResponse(prefs);
    }

    private UserPreferences createDefaultPreferences(Long userId) {
        UserPreferences defaults = UserPreferences.builder().userId(userId).build();
        return userPreferencesRepository.save(defaults);
    }

    // ── Change Password ─────────────────────────────────────────

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        User user = userRepository.findById(getCurrentUserId())
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new InvalidPasswordException("La contraseña actual es incorrecta.");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    // ── Mappers ─────────────────────────────────────────────────

    private UserProfileResponse mapToProfileResponse(User user) {
        return UserProfileResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .birthDate(user.getBirthDate())
                .bloodType(user.getBloodType())
                .allergies(user.getAllergies())
                .medicalConditions(user.getMedicalConditions())
                .build();
    }

    private UserPreferencesResponse mapToPreferencesResponse(UserPreferences prefs) {
        return UserPreferencesResponse.builder()
                .pushNotifications(prefs.getPushNotifications())
                .alertSound(prefs.getAlertSound())
                .fontSize(prefs.getFontSize().name())
                .language(prefs.getLanguage())
                .build();
    }

    // ── Custom exceptions ───────────────────────────────────────

    public static class UserNotFoundException extends RuntimeException {
        public UserNotFoundException(String message) { super(message); }
    }

    public static class InvalidPasswordException extends RuntimeException {
        public InvalidPasswordException(String message) {
            super(message);
        }
    }
}
