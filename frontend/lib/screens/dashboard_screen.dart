import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/dose_service.dart';
import '../theme/app_theme.dart';
import '../widgets/index.dart';

/// Dashboard: "Tomas de Hoy" agrupadas por Mañana/Tarde/Noche
class DashboardScreen extends StatefulWidget {
  final DoseService doseService;

  const DashboardScreen({required this.doseService, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDoses();
  }

  Future<void> _loadDoses() async {
    await widget.doseService.loadTodaysDoses();
  }

  void _showConfirmDialog(Dose dose) {
    showDialog(
      context: context,
      builder: (context) => DoseNotificationModal(
        dose: dose,
        onConfirm: () async {
          Navigator.pop(context);
          final success = await widget.doseService.confirmDose(dose);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Toma registrada'),
                backgroundColor: AppColors.successGreen,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        onPostpone: () async {
          Navigator.pop(context);
          final success = await widget.doseService.postponeDose(dose);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏱ Toma pospuesta 15 minutos'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomas de Hoy'),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: widget.doseService,
        builder: (context, _) {
          if (widget.doseService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (widget.doseService.dosesForToday.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.primaryBlueLight,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '¡Felicitaciones!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No hay tomas programadas para hoy',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final dosesByTime = widget.doseService.getDosesByTimeOfDay();
          final timeOrder = ['Mañana', 'Tarde', 'Noche'];

          return RefreshIndicator(
            onRefresh: _loadDoses,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final timeLabel =
                            timeOrder[index % timeOrder.length];

                        if (!dosesByTime.containsKey(timeLabel)) {
                          return const SizedBox.shrink();
                        }

                        final doses = dosesByTime[timeLabel]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Encabezado del período del día
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  timeLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  '${doses.length} ${doses.length == 1 ? 'toma' : 'tomas'}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.md),

                            // Tomas del período
                            ...doses.map((dose) {
                              return GestureDetector(
                                onTap: dose.status == DoseStatus.pending
                                    ? () => _showConfirmDialog(dose)
                                    : null,
                                child: DoseCard(
                                  dose: dose,
                                  isLoading: widget.doseService.isLoading,
                                  onConfirm: () =>
                                      _showConfirmDialog(dose),
                                  onPostpone: () {
                                    _showConfirmDialog(dose);
                                  },
                                ),
                              );
                            }),

                            const SizedBox(height: AppSpacing.lg),
                          ],
                        );
                      },
                      childCount: timeOrder.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Modal a pantalla completa para notificación de toma
class DoseNotificationModal extends StatelessWidget {
  final Dose dose;
  final VoidCallback onConfirm;
  final VoidCallback onPostpone;

  const DoseNotificationModal({
    required this.dose,
    required this.onConfirm,
    required this.onPostpone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón cerrar
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Contenido principal
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Es hora de tomar tu medicamento',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dose.medicationName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Dosis: ${dose.dosage}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Botones de acción
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        onPressed: onConfirm,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 24),
                            SizedBox(width: AppSpacing.md),
                            Text(
                              'Confirmar Toma',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        onPressed: onPostpone,
                        child: const Text(
                          'Posponer 15 minutos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
