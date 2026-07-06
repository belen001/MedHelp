import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final AuthService authService;

  const SettingsScreen({required this.authService, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // MyApp escucha authService con ListenableBuilder — al hacer
      // logout, isAuthenticated pasa a false y vuelve a WelcomeScreen
      // automáticamente, sin necesidad de navegar manualmente.
      await widget.authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {},
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
              Text('Ajustes', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Gestiona tus preferencias de la aplicación',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(title: "Cuenta"),
              const SizedBox(height: AppSpacing.sm),
              _SettingsCard(
                icon: Icons.lock,
                title: "Privacidad",
                subtitle: "Controla quién ve tu información",
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(title: "Preferencias"),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primaryBlueLight,
                      child: Icon(
                        Icons.notifications_active,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Notificaciones Push",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Recordatorios de medicación",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: notificationsEnabled,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (value) {
                        setState(() => notificationsEnabled = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsCard(
                icon: Icons.volume_up,
                title: "Sonido de Alerta",
                subtitle: "Campana suave",
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              _SettingsCard(
                icon: Icons.text_increase,
                title: "Tamaño de Fuente",
                subtitle: "Grande",
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ListenableBuilder(
                  listenable: widget.authService,
                  builder: (context, _) {
                    return OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                      ),
                      onPressed:
                          widget.authService.isLoading ? null : _handleLogout,
                      icon: widget.authService.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout),
                      label: const Text("Cerrar Sesión"),
                    );
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryBlueLight,
                  child: Icon(icon, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
