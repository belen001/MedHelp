package cl.ufro.medhelp.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "dose_logs",
       uniqueConstraints = @UniqueConstraint(columnNames = {"medication_id", "dose_date", "dose_time"}))
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class DoseLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "medication_id", nullable = false)
    private Long medicationId;

    @Column(name = "dose_date", nullable = false)
    private LocalDate doseDate;

    @Column(name = "dose_time", nullable = false)
    private LocalTime doseTime;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private DoseStatus status = DoseStatus.pending;

    @Column(name = "taken_at")
    private LocalDateTime takenAt;

    @Column(name = "skip_reason", columnDefinition = "TEXT")
    private String skipReason;

    @Column(name = "missed_at")
    private LocalDateTime missedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
