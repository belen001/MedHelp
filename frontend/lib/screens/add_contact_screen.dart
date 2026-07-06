import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _relationship;
  bool _shareProgress = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty || _relationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    // TODO: conectar con ContactService
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('MedHelp'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryBlueLight,
              child: Icon(Icons.person, color: AppColors.primaryBlue),
            ),
          )
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nuevo Contacto",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Añade a una persona a tu red de apoyo.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Nombre
              _buildInput(
                label: "Nombre del contacto",
                controller: _nameController,
                hint: "Ej. María García",
                icon: Icons.person,
              ),

              const SizedBox(height: AppSpacing.md),

              // Relación
              _buildDropdown(),

              const SizedBox(height: AppSpacing.md),

              // Teléfono
              _buildInput(
                label: "Número de teléfono",
                controller: _phoneController,
                hint: "+56 9 0000 0000",
                icon: Icons.phone,
                keyboard: TextInputType.phone,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Switch compartir progreso
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.share, color: AppColors.primaryBlue),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Compartir mi progreso médico",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "Permite que vea tu cumplimiento",
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _shareProgress,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (v) => setState(() => _shareProgress = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Upload foto (UI mock)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.add_a_photo, size: 48, color: AppColors.primaryBlue),
                    SizedBox(height: 12),
                    Text(
                      "Subir foto del contacto",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Ayuda a identificarlo rápidamente",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // Botón inferior fijo
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saveContact,
              icon: const Icon(Icons.save),
              label: const Text("Guardar Contacto"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Relación", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _relationship,
          items: const [
            DropdownMenuItem(value: "familiar", child: Text("Familiar")),
            DropdownMenuItem(value: "cuidador", child: Text("Cuidador")),
            DropdownMenuItem(value: "medico", child: Text("Médico")),
          ],
          onChanged: (v) => setState(() => _relationship = v),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
          ),
        ),
      ],
    );
  }
}