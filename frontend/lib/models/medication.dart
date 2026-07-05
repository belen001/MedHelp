class Medication {
  final int id;
  final String name;
  final String dosage;
  final String frequency;
  final String quantity;
  final List<String> times; // ej. ["08:00", "16:00"]
  final DateTime startDate;
  final String? specialInstructions;
  final String? photoUrl;
  final String status; // active | inactive | deleted

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.quantity,
    required this.times,
    required this.startDate,
    this.specialInstructions,
    this.photoUrl,
    this.status = 'active',
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as int,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      quantity: json['quantity'] as String,
      times: (json['times'] as List<dynamic>)
          .map((t) => t as String)
          .toList(),
      startDate: DateTime.parse(json['start_date'] as String),
      specialInstructions: json['special_instructions'] as String?,
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  /// Body para POST /api/medications y PUT /api/medications/{id}
  /// (ambos endpoints esperan exactamente los mismos campos).
  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'quantity': quantity,
      'times': times,
      'start_date':
          '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'special_instructions': specialInstructions,
    };
  }

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? frequency,
    String? quantity,
    List<String>? times,
    DateTime? startDate,
    String? specialInstructions,
    String? photoUrl,
    String? status,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      quantity: quantity ?? this.quantity,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
    );
  }
}
