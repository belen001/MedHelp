import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/medication_service.dart';
import '../theme/app_theme.dart';
import 'add_medication_screen.dart';

class MedicationScreen extends StatefulWidget {
  final MedicationService medicationService;

  const MedicationScreen({required this.medicationService, super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  @override
  void initState() {
    super.initState();
    widget.medicationService.loadMedications(status: 'active');
  }

  Future<void> _confirmDelete(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: Text('¿Seguro que quieres eliminar "${medication.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await widget.medicationService.deleteMedication(medication.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✓ Medicamento eliminado'
            : (widget.medicationService.errorMessage ?? 'Error al eliminar')),
        backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {},
        ),
        title: Row(
          children: const [
            Icon(Icons.medication, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text(
              'MedHelp',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryBlueLight,
              child: Icon(Icons.person, color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListenableBuilder(
            listenable: widget.medicationService,
            builder: (context, _) {
              final medications = widget.medicationService.medications;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mis Medicinas',
                          style: Theme.of(context).textTheme.headlineLarge),
                      Text(
                        '${medications.length} activas',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: widget.medicationService.isLoading && medications.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : medications.isEmpty
                            ? Center(
                                child: Text(
                                  'Aún no tienes medicamentos registrados',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => widget.medicationService
                                    .loadMedications(status: 'active'),
                                child: ListView.builder(
                                  itemCount: medications.length,
                                  itemBuilder: (context, index) {
                                    final med = medications[index];
                                    return _MedicationCard(
                                      medication: med,
                                      onEdit: () async {
                                        final result =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddMedicationScreen(
                                              medicationService:
                                                  widget.medicationService,
                                              existing: med,
                                            ),
                                          ),
                                        );
                                        if (result == true && mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text('✓ Medicamento actualizado'),
                                            backgroundColor:
                                                AppColors.successGreen,
                                          ));
                                        }
                                      },
                                      onDelete: () => _confirmDelete(med),
                                    );
                                  },
                                ),
                              ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddMedicationScreen(
                              medicationService: widget.medicationService,
                            ),
                          ),
                        );
                        if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Medicamento agregado'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_circle),
                      label: const Text(
                        'Agregar Medicamento',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.medication,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryBlueDark,
            child: Icon(Icons.medication, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${medication.dosage} · ${medication.frequency}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}
