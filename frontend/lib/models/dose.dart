
enum DoseStatus {
  pending('Pendiente'),
  taken('Completado'),
  skipped('Omitido'),
  missed('Perdido');

  final String label;
  const DoseStatus(this.label);
}

/// Modelo de toma de medicamento, construido a partir de
/// GET /api/medications/today (TodayScheduleResponse).
///
class Dose {

  final String id;
  final int medicationId;
  final String medicationName;
  final String dosage;
  final String quantity;
  final String? specialInstructions;
  final DateTime scheduledTime;
  final DateTime? takenAt;
  final DoseStatus status;

  Dose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.quantity,
    required this.scheduledTime,
    required this.status,
    this.specialInstructions,
    this.takenAt,
  });

  factory Dose.fromScheduleItem({
    required DateTime date,
    required String timeKey,
    required Map<String, dynamic> json,
  }) {
    final parts = timeKey.split(':');
    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final medicationId = json['medication_id'] as int;

    return Dose(
      id: '$medicationId|${formatDate(date)}|$timeKey',
      medicationId: medicationId,
      medicationName: json['name'] as String,
      dosage: json['dosage'] as String,
      quantity: json['quantity'] as String? ?? '',
      specialInstructions: json['special_instructions'] as String?,
      scheduledTime: scheduled,
      takenAt: json['taken_at'] != null
          ? parseBackendDateTime(json['taken_at'] as String)
          : null,
      status: DoseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DoseStatus.pending,
      ),
    );
  }

  /// Fecha en formato yyyy-MM-dd (para enviar a confirm/skip/snooze)
  String get doseDateStr => formatDate(scheduledTime);

  /// Hora en formato HH:mm (para enviar a confirm/skip/snooze)
  String get doseTimeStr =>
      '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parseBackendDateTime(String s) =>
      DateTime.parse(s.replaceFirst(' ', 'T'));

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
