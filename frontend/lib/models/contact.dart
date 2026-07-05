/// Tipo de relación del contacto, alineado con contact_relationship
enum ContactRelationship {
  caregiver('Cuidador'),
  family('Familiar'),
  monitor('Monitor'),
  patient('Paciente'),
  other('Otro');

  final String label;
  const ContactRelationship(this.label);
}

/// Estado de disponibilidad del contacto, alineado con contact_status.
enum ContactStatus {
  available('Disponible'),
  doNotDisturb('No molestar'),
  inactive('Inactivo');

  final String label;
  const ContactStatus(this.label);

  static ContactStatus fromBackend(String value) {
    switch (value) {
      case 'do_not_disturb':
        return ContactStatus.doNotDisturb;
      case 'inactive':
        return ContactStatus.inactive;
      default:
        return ContactStatus.available;
    }
  }

  String get backendValue {
    switch (this) {
      case ContactStatus.doNotDisturb:
        return 'do_not_disturb';
      case ContactStatus.inactive:
        return 'inactive';
      case ContactStatus.available:
        return 'available';
    }
  }
}

class Contact {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final ContactRelationship relationship;
  final ContactStatus status;

  Contact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.status,
    this.phone,
    this.email,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      relationship: ContactRelationship.values.firstWhere(
        (e) => e.name == json['relationship'],
        orElse: () => ContactRelationship.caregiver,
      ),
      status: ContactStatus.fromBackend(json['status'] as String? ?? 'available'),
    );
  }

  /// Body para POST /api/contacts y PUT /api/contacts/{id}
  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'relationship': relationship.name,
      'status': status.backendValue,
    };
  }

  Contact copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    ContactRelationship? relationship,
    ContactStatus? status,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      status: status ?? this.status,
    );
  }
}
