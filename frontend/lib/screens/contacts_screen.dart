import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'add_contact_screen.dart';

/// Pantalla "Contactos" (Red de Cuidado) de MedHelp.
///
/// Reutiliza íntegramente el sistema visual definido en `app_theme.dart`
/// (AppColors, AppSpacing, AppRadius, cardTheme, elevatedButtonTheme, etc.)
/// para garantizar consistencia con el resto de la app.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
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
              label: 'Cuidadores',
            ),
            const SizedBox(height: AppSpacing.sm),
            const ContactCard(
              name: 'María Gómez',
              phone: '+34 600 123 456',
              status: ContactStatus.available,
              avatarBackground: AppColors.primaryBlueLight,
              avatarIcon: Icons.person,
            ),
            const ContactCard(
              name: 'Carlos Ruiz',
              phone: '+34 611 987 654',
              status: ContactStatus.doNotDisturb,
              avatarBackground: AppColors.divider,
              avatarIcon: Icons.person,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionHeader(
              icon: Icons.favorite_rounded,
              label: 'Personas que cuido',
            ),
            const SizedBox(height: AppSpacing.sm),
            const ContactCard(
              name: 'Juan Pérez',
              phone: '+34 622 333 444',
              status: ContactStatus.available,
              avatarBackground: AppColors.successGreenLight,
              avatarIcon: Icons.person,
            ),
            const SizedBox(height: AppSpacing.lg),
            _AddContactButton(onPressed: () {
              // TODO: Navegar al flujo de "Agregar Nuevo Contacto".
            }),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.medication_rounded,
                    size: 18, color: AppColors.primaryBlue),
                SizedBox(width: 6),
                Icon(Icons.notifications_rounded,
                    size: 16, color: AppColors.primaryBlueDark),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryBlueLight,
            child: Icon(Icons.person, color: AppColors.primaryBlue, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_rounded),
          label: 'Hoy',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medication_outlined),
          label: 'Medicinas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.contacts_rounded),
          label: 'Contactos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Ajustes',
        ),
      ],
    );
  }
}

/// Encabezado de sección con icono + etiqueta (ej. "Cuidadores").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: textTheme.headlineMedium),
      ],
    );
  }
}

enum ContactStatus { available, doNotDisturb }

/// Tarjeta reutilizable para un contacto de la red de cuidado.
///
/// Usada tanto para "Cuidadores" como para "Personas que cuido" con el
/// fin de mantener consistencia cognitiva, tal como especifica el diseño.
class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.name,
    required this.phone,
    required this.status,
    required this.avatarBackground,
    required this.avatarIcon,
    this.onCall,
  });

  final String name;
  final String phone;
  final ContactStatus status;
  final Color avatarBackground;
  final IconData avatarIcon;
  final VoidCallback? onCall;

  bool get _isAvailable => status == ContactStatus.available;

  Color get _statusColor =>
      _isAvailable ? AppColors.successGreen : AppColors.textSecondary;

  Color get _statusBg =>
      _isAvailable ? AppColors.successGreenLight : AppColors.divider;

  String get _statusLabel => _isAvailable ? 'Disponible' : 'No molestar';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: avatarBackground,
              child: Icon(avatarIcon, color: AppColors.textSecondary, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(phone, style: textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatusChip(color: _statusColor, background: _statusBg, label: _statusLabel),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _CallButton(enabled: _isAvailable, onPressed: onCall ?? () {}),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.color,
    required this.background,
    required this.label,
  });

  final Color color;
  final Color background;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular de llamada: touch target grande (48x48 dp mínimo)
/// para facilitar la pulsación, según el requisito de affordance.
class _CallButton extends StatelessWidget {
  const _CallButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.successGreen : AppColors.textSecondary;
    return Material(
      color: enabled ? AppColors.successGreen : AppColors.divider,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.phone_rounded,
            color: enabled ? Colors.white : color,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// CTA principal de ancho completo para agregar un nuevo contacto.
class _AddContactButton extends StatelessWidget {
  const _AddContactButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddContactScreen(),
            ),
          );
        },
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
