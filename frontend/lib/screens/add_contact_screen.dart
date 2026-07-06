import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/contact_service.dart';
import '../theme/app_theme.dart';

class AddContactScreen extends StatefulWidget {
  final ContactService contactService;

  const AddContactScreen({required this.contactService, super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  ContactRelationship? _relationship;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty || _relationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final contact = Contact(
      id: 0,
      name: name,
      phone: phone,
      relationship: _relationship!,
      status: ContactStatus.available,
    );

    final success = await widget.contactService.addContact(contact);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.contactService.errorMessage ??
              'No fue posible conectarse con el servidor. Intente nuevamente más tarde'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
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
              Text("Nuevo Contacto", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                "Añade a una persona a tu red de apoyo.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildInput(
                label: "Nombre del contacto",
                controller: _nameController,
                hint: "Ej. María García",
                icon: Icons.person,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildRelationshipDropdown(),
              const SizedBox(height: AppSpacing.md),
              _buildInput(
                label: "Número de teléfono",
                controller: _phoneController,
                hint: "+56 9 0000 0000",
                icon: Icons.phone,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveContact,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
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

  Widget _buildRelationshipDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Relación", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<ContactRelationship>(
          initialValue: _relationship,
          items: ContactRelationship.values
              .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
              .toList(),
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
