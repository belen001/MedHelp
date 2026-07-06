import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController doseController = TextEditingController();

  String frequency = "1 vez al día";

  final List<String> frequencies = [
    "1 vez al día",
    "2 veces al día",
    "Cada 8 horas",
    "Solo cuando sea necesario",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar Medicamento"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nuevo medicamento",
                style: Theme.of(context).textTheme.headlineLarge,
              ),

              const SizedBox(height: AppSpacing.lg),

              // =====================
              // NOMBRE
              // =====================
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

              // =====================
              // DOSIS
              // =====================
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

              // =====================
              // FRECUENCIA
              // =====================
              DropdownButtonFormField<String>(
                value: frequency,
                items: frequencies
                    .map(
                      (f) => DropdownMenuItem(
                    value: f,
                    child: Text(f),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() => frequency = value!);
                },
                decoration: const InputDecoration(
                  labelText: "Frecuencia",
                  prefixIcon: Icon(Icons.schedule),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // =====================
              // BOTÓN GUARDAR
              // =====================
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Guardar Medicamento"),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}