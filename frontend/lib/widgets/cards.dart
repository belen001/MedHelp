import 'package:flutter/material.dart';
import '../models/index.dart';
import '../theme/app_theme.dart';

/// Card de toma de medicamento (para Dashboard "Tomas de Hoy")
class DoseCard extends StatelessWidget {
  final Dose dose;
  final VoidCallback onConfirm;
  final VoidCallback onPostpone;
  final bool isLoading;

  const DoseCard({
    required this.dose,
    required this.onConfirm,
    required this.onPostpone,
    this.isLoading = false,
    super.key,
  });

  Color _getStatusColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return DoseStatusColors.completed;
      case DoseStatus.pending:
        return DoseStatusColors.pending;
      case DoseStatus.skipped:
        return AppColors.warningOrange;
      case DoseStatus.missed:
        return DoseStatusColors.overdue;
    }
  }

  Color _getStatusBgColor(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return DoseStatusColors.completedBg;
      case DoseStatus.pending:
        return Colors.transparent;
      case DoseStatus.skipped:
        return Colors.transparent;
      case DoseStatus.missed:
        return DoseStatusColors.overdueBg;
    }
  }

  IconData _getStatusIcon(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return Icons.check_circle;
      case DoseStatus.pending:
        return Icons.schedule;
      case DoseStatus.skipped:
        return Icons.block;
      case DoseStatus.missed:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(dose.status);
    final statusBgColor = _getStatusBgColor(dose.status);

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: 0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: nombre + estado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dose.medicationName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${dose.dosage} · ${dose.quantity}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(dose.status),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dose.status.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Hora programada
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  dose.doseTimeStr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            if (dose.specialInstructions != null &&
                dose.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                dose.specialInstructions!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Botones de acción (solo si sigue pendiente)
            if (dose.status == DoseStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      onPressed: isLoading ? null : onConfirm,
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 18),
                                SizedBox(width: 8),
                                Text('Confirmar'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: isLoading ? null : onPostpone,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 18),
                            SizedBox(width: 8),
                            Text('Posponer 15m'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (dose.status == DoseStatus.taken)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      dose.takenAt != null
                          ? 'Completado ${_formatTime(dose.takenAt!)}'
                          : 'Completado',
                      style: const TextStyle(
                        color: AppColors.successGreen,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Tarjeta de medicamento (para lista "Mis Medicinas")
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicationCard({
    required this.medication,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${medication.dosage} · ${medication.quantity}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: onEdit,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20, color: AppColors.errorRed),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _InfoChip(icon: Icons.repeat, label: medication.frequency),
                _InfoChip(
                  icon: Icons.calendar_today,
                  label:
                      '${medication.startDate.day}/${medication.startDate.month}',
                ),
                for (final time in medication.times)
                  _InfoChip(icon: Icons.access_time, label: time),
              ],
            ),
            if (medication.specialInstructions != null &&
                medication.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Instrucciones: ${medication.specialInstructions}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip pequeño para información
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueLight,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryBlueDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primaryBlueDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
