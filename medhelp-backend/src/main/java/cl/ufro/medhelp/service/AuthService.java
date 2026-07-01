package cl.ufro.medhelp.service;

import cl.ufro.medhelp.dto.AuthResponse;
import cl.ufro.medhelp.dto.LoginRequest;
import cl.ufro.medhelp.dto.RegisterRequest;
import cl.ufro.medhelp.entity.TokenBlacklist;
import cl.ufro.medhelp.entity.User;
import cl.ufro.medhelp.repository.TokenBlacklistRepository;
import cl.ufro.medhelp.repository.UserRepository;
import cl.ufro.medhelp.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final TokenBlacklistRepository tokenBlacklistRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyExistsException("El email ya está registrado.");
        }

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .consentDataProcessing(true)
                .consentGivenAt(LocalDateTime.now())
                .build();

        user = userRepository.save(user);

        String token = jwtUtil.generateToken(user.getId(), user.getEmail(), user.getRole().name());

        return buildAuthResponse(user, token);
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new InvalidCredentialsException("Invalid email or password");
        }

        String token = jwtUtil.generateToken(user.getId(), user.getEmail(), user.getRole().name());

        return buildAuthResponse(user, token);
    }

    public void logout(String token) {
        Date expiration = jwtUtil.getExpirationFromToken(token);
        LocalDateTime expiresAt = expiration.toInstant()
                .atZone(ZoneId.systemDefault())
                .toLocalDateTime();

        TokenBlacklist blacklist = TokenBlacklist.builder()
                .token(token)
                .expiresAt(expiresAt)
                .build();

        tokenBlacklistRepository.save(blacklist);

        // Clean up expired tokens
        tokenBlacklistRepository.deleteByExpiresAtBefore(LocalDateTime.now());
    }

    private AuthResponse buildAuthResponse(User user, String token) {
        AuthResponse.UserData userData = AuthResponse.UserData.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();

        return AuthResponse.builder()
                .success(true)
                .token(token)
                .user(userData)
                .build();
    }

    // Custom exceptions
    public static class EmailAlreadyExistsException extends RuntimeException {
        public EmailAlreadyExistsException(String message) {
            super(message);
        }
    }

    public static class InvalidCredentialsException extends RuntimeException {
        public InvalidCredentialsException(String message) {
            super(message);
        }
    }
}
