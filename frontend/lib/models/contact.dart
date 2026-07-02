enum ContactType {
  doctor('Médico'),
  caregiver('Cuidador'),
  emergency('Emergencia');

  final String label;
  const ContactType(this.label);
}

/// Modelo de contacto de emergencia (médicos, cuidadores, etc.)
class Contact {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? specialty; // ej. "Cardiólogo"
  final ContactType type;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.email,
    this.specialty,
    required this.createdAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      specialty: json['specialty'] as String?,
      type: ContactType.values.firstWhere(
        (e) => e.name == (json['type'] as String).toLowerCase(),
        orElse: () => ContactType.caregiver,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'specialty': specialty,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? specialty,
    ContactType? type,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
