import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class AdverseReactionScreen extends StatefulWidget {
  const AdverseReactionScreen({super.key});

  @override
  State<AdverseReactionScreen> createState() =>
      _AdverseReactionScreenState();
}

class _AdverseReactionScreenState
    extends State<AdverseReactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _medicationController = TextEditingController();
  final _doseController = TextEditingController();
  final _reactionController = TextEditingController();

  DateTime? _startDate;

  @override
  void dispose() {
    _medicationController.dispose();
    _doseController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  void _saveReport() {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione la fecha de inicio'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reporte guardado correctamente'),
        backgroundColor: AppColors.successGreen,
      ),
    );

    Navigator.pop(context);
  }

  InputDecoration _inputDecoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppColors.primaryBlue,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.primaryBlue,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Reportar Reacción Adversa"),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Nuevo Reporte",
                  style:
                  Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  "Completa la siguiente información sobre la reacción adversa presentada.",
                  style:
                  Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: AppSpacing.xl),

                /// Medicamento
                TextFormField(
                  controller: _medicationController,
                  decoration: _inputDecoration(
                    "Medicamento",
                    Icons.medication,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Ingrese el medicamento";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                /// Dosis
                TextFormField(
                  controller: _doseController,
                  decoration: _inputDecoration(
                    "Dosis",
                    Icons.vaccines,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Ingrese la dosis";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                /// Fecha
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: _inputDecoration(
                      "Fecha de inicio",
                      Icons.calendar_today,
                    ),
                    child: Text(
                      _startDate == null
                          ? "Seleccionar fecha"
                          : DateFormat(
                        "dd/MM/yyyy",
                      ).format(_startDate!),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                /// Reacciones
                TextFormField(
                  controller: _reactionController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: _inputDecoration(
                    "Describe la reacción presentada",
                    Icons.report_problem,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Describa la reacción";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                      AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _saveReport,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      "Guardar Reporte",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}