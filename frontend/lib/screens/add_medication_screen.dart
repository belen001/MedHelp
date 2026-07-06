import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/medication_service.dart';
import '../theme/app_theme.dart';

class AddMedicationScreen extends StatefulWidget {
  final MedicationService medicationService;
  final Medication? existing;

  const AddMedicationScreen({
    required this.medicationService,
    this.existing,
    super.key,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController doseController;
  late final TextEditingController quantityController;
  late List<String> _times;
  bool _isSaving = false;

  String frequency = "1 vez al día";

  final List<String> frequencies = [
    "1 vez al día",
    "2 veces al día",
    "Cada 8 horas",
    "Solo cuando sea necesario",
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    nameController = TextEditingController(text: e?.name ?? '');
    doseController = TextEditingController(text: e?.dosage ?? '');
    quantityController = TextEditingController(text: e?.quantity ?? '1 pastilla');
    frequency = e?.frequency ?? frequencies.first;
    _times = List<String>.from(e?.times ?? ['08:00']);
  }

  @override
  void dispose() {
    nameController.dispose();
    doseController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (!_times.contains(formatted)) {
      setState(() {
        _times.add(formatted);
        _times.sort();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un horario')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final medication = Medication(
      id: widget.existing?.id ?? 0,
      name: nameController.text.trim(),
      dosage: doseController.text.trim(),
      frequency: frequency,
      quantity: quantityController.text.trim(),
      times: _times,
      startDate: widget.existing?.startDate ?? DateTime.now(),
      specialInstructions: widget.existing?.specialInstructions,
      photoUrl: widget.existing?.photoUrl,
      status: widget.existing?.status ?? 'active',
    );

    final success = widget.existing == null
        ? await widget.medicationService.addMedication(medication)
        : await widget.medicationService
            .updateMedication(widget.existing!.id, medication);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.medicationService.errorMessage ??
              'No fue posible conectarse con el servidor. Intente nuevamente más tarde'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Medicamento" : "Agregar Medicamento"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? "Editar medicamento" : "Nuevo medicamento",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre del medicamento",
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: doseController,
                decoration: const InputDecoration(
                  labelText: "Dosis (ej: 500mg)",
                  prefixIcon: Icon(Icons.science),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: "Cantidad (ej: 1 pastilla)",
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: frequency,
                items: frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (value) => setState(() => frequency = value!),
                decoration: const InputDecoration(
                  labelText: "Frecuencia",
                  prefixIcon: Icon(Icons.schedule),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Horarios', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final time in _times)
                    Chip(
                      label: Text(time),
                      onDeleted: () => setState(() => _times.remove(time)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar horario'),
                    onPressed: _addTime,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(isEditing ? "Guardar Cambios" : "Guardar Medicamento"),
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
