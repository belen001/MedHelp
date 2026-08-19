enum Frequency {
  daily('Diariamente'),
  everyTwoDays('Cada 2 días'),
  threeTimesADay('3 veces al día'),
  twiceADay('2 veces al día'),
  oncePerWeek('Una vez por semana'),
  custom('Personalizado');

  final String label;
  const Frequency(this.label);
}

enum TimeOfDay {
  morning('Mañana', '08:00'),
  afternoon('Tarde', '14:00'),
  night('Noche', '21:00'),
  custom('Personalizado', '');

  final String label;
  final String defaultTime;
  const TimeOfDay(this.label, this.defaultTime);
}

/// Modelo de medicamento
class Medication {
  final String id;
  final String name;
  final String dosage;
  final Frequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final TimeOfDay timeOfDay;
  final String? customTime; // HH:mm formato si timeOfDay = custom
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.timeOfDay,
    this.endDate,
    this.instructions,
    this.customTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: Frequency.values.firstWhere(
        (e) => e.name == (json['frequency'] as String).toLowerCase(),
        orElse: () => Frequency.daily,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      instructions: json['instructions'] as String?,
      timeOfDay: TimeOfDay.values.firstWhere(
        (e) => e.name == (json['timeOfDay'] as String).toLowerCase(),
        orElse: () => TimeOfDay.morning,
      ),
      customTime: json['customTime'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'instructions': instructions,
      'timeOfDay': timeOfDay.name,
      'customTime': customTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    Frequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    TimeOfDay? timeOfDay,
    String? customTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      customTime: customTime ?? this.customTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
