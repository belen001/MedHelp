package cl.ufro.medhelp.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "dose_snoozes")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class DoseSnooze {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "dose_log_id")
    private Long doseLogId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "medication_id", nullable = false)
    private Long medicationId;

    @Column(name = "dose_date", nullable = false)
    private LocalDate doseDate;

    @Column(name = "dose_time", nullable = false)
    private LocalTime doseTime;

    @Column(nullable = false)
    private Integer minutes;

    @Column(name = "new_reminder_at", nullable = false)
    private LocalDateTime newReminderAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
