import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/contact_service.dart';
import '../theme/app_theme.dart';
import 'add_contact_screen.dart';

/// Pantalla "Contactos" (Red de Cuidado) de MedHelp — conectada a
/// ContactService en vez de datos mockeados.
class ContactsScreen extends StatefulWidget {
  final ContactService contactService;

  const ContactsScreen({required this.contactService, super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    widget.contactService.loadContacts();
  }

  Future<void> _confirmDelete(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: Text('¿Seguro que quieres eliminar a "${contact.name}"?'),
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

    final success = await widget.contactService.deleteContact(contact.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✓ Contacto eliminado'
            : (widget.contactService.errorMessage ?? 'Error al eliminar')),
        backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.contactService,
          builder: (context, _) {
            final contacts = widget.contactService.contacts;

            return RefreshIndicator(
              onRefresh: () => widget.contactService.loadContacts(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                children: [
                  const _SectionHeader(
                    icon: Icons.groups_rounded,
                    label: 'Mi Red de Contactos',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (widget.contactService.isLoading && contacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Aún no tienes contactos registrados',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    for (final contact in contacts)
                      _ContactCard(
                        contact: contact,
                        onDelete: () => _confirmDelete(contact),
                      ),
                  const SizedBox(height: AppSpacing.lg),
                  _AddContactButton(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddContactScreen(
                            contactService: widget.contactService,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Contacto agregado'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () {},
        tooltip: 'Menú',
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.medication_rounded, size: 18, color: AppColors.primaryBlue),
                SizedBox(width: 6),
                Icon(Icons.notifications_rounded, size: 16, color: AppColors.primaryBlueDark),
              ],
            ),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.md),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryBlueLight,
            child: Icon(Icons.person, color: AppColors.primaryBlue, size: 20),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}

/// Tarjeta de contacto — usa directamente el ContactStatus del modelo
/// real (available / doNotDisturb / inactive), sin duplicar el enum.
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, this.onDelete});

  final Contact contact;
  final VoidCallback? onDelete;

  bool get _isAvailable => contact.status == ContactStatus.available;

  Color get _statusColor =>
      _isAvailable ? AppColors.successGreen : AppColors.textSecondary;

  Color get _statusBg =>
      _isAvailable ? AppColors.successGreenLight : AppColors.divider;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryBlueLight,
              child: const Icon(Icons.person, color: AppColors.textSecondary, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(contact.relationship.label, style: textTheme.bodySmall),
                  if (contact.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(contact.phone!, style: textTheme.bodyMedium),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBg,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          contact.status.label,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.errorRed),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddContactButton extends StatelessWidget {
  const _AddContactButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Agregar Nuevo Contacto'),
      ),
    );
  }
}
