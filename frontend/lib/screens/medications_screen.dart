import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'add_medication_screen.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis Medicinas',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text(
                    '3 activas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // LISTA
              Expanded(
                child: ListView(
                  children: const [
                    _MedicationCard(
                      name: 'Lisinopril',
                      dosage: '10mg • 1 vez al día',
                      color: Color(0xFF75F6CA),
                    ),
                    _MedicationCard(
                      name: 'Aspirina',
                      dosage: '100mg • Con comida',
                      color: AppColors.primaryBlueDark,
                    ),
                    _MedicationCard(
                      name: 'Metformina',
                      dosage: '500mg • 2 veces al día',
                      color: Color(0xFF75F6CA),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // BOTÓN AGREGAR
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddMedicationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle),
                  label: const Text(
                    'Agregar Medicamento',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CARD DE MEDICAMENTO
class _MedicationCard extends StatelessWidget {
  final String name;
  final String dosage;
  final Color color;

  const _MedicationCard({
    required this.name,
    required this.dosage,
    required this.color,
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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: const Icon(
              Icons.medication,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  dosage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}