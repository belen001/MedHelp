enum DoseStatus {
  completed('Completado'),
  pending('Pendiente'),
  postponed('Pospuesto'),
  overdue('Vencido');

  final String label;
  const DoseStatus(this.label);
}

/// Modelo de toma de medicamento (dosis)
class Dose {
  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final DateTime scheduledTime;
  final DateTime? completedTime;
  final DoseStatus status;
  final String? notes;

  Dose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTime,
    required this.status,
    this.completedTime,
    this.notes,
  });

  factory Dose.fromJson(Map<String, dynamic> json) {
    return Dose(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      dosage: json['dosage'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      completedTime: json['completedTime'] != null ? DateTime.parse(json['completedTime'] as String) : null,
      status: DoseStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String).toLowerCase(),
        orElse: () => DoseStatus.pending,
      ),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'dosage': dosage,
      'scheduledTime': scheduledTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'status': status.name,
      'notes': notes,
    };
  }

  Dose copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    String? dosage,
    DateTime? scheduledTime,
    DateTime? completedTime,
    DoseStatus? status,
    String? notes,
  }) {
    return Dose(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      completedTime: completedTime ?? this.completedTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  /// Agrupa dosis por período del día
  static String getTimeOfDayLabel(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 5 && hour < 12) {
      return 'Mañana';
    } else if (hour >= 12 && hour < 17) {
      return 'Tarde';
    } else {
      return 'Noche';
    }
  }
}
