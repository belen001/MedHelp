import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/dose_service.dart';
import 'services/medication_service.dart';
import 'services/contact_service.dart';
import 'screens/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bloquear orientación solo a Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inicializar servicios y restaurar sesión antes de arrancar la UI
  final apiService = ApiService();
  final authService = AuthService(apiService);
  await authService.restoreSession();

  runApp(MyApp(apiService: apiService, authService: authService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final AuthService authService;
  const MyApp({required this.apiService, required this.authService, super.key});

  @override
  Widget build(BuildContext context) {
    // Servicios provistos desde main
    final apiService = this.apiService;
    final authService = this.authService;
    final doseService = DoseService(apiService);
    final medicationService = MedicationService(apiService);
    final contactService = ContactService(apiService);

    return MaterialApp(
      title: 'MedHelp',
      theme: AppTheme.lightTheme,
      home: ListenableBuilder(
        listenable: authService,
        builder: (context, _) {
          // Si el usuario está autenticado, mostrar HomeShell
          // Si no, mostrar pantalla de bienvenida
          if (authService.isAuthenticated) {
            return HomeShell(
              authService: authService,
              doseService: doseService,
              medicationService: medicationService,
              contactService: contactService,
            );
          } else {
            return WelcomeScreen(authService: authService);
          }
        },
      ),
    );
  }
}

/// Shell principal con Bottom Navigation Bar
class HomeShell extends StatefulWidget {
  final AuthService authService;
  final DoseService doseService;
  final MedicationService medicationService;
  final ContactService contactService;

  const HomeShell({
    required this.authService,
    required this.doseService,
    required this.medicationService,
    required this.contactService,
    super.key,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  // Placeholder screens para las otras pantallas
  // Implementar con las funcionalidades específicas del usuario
  Widget _buildPlaceholder(String title, IconData icon, {bool showLogout = false}) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.primaryBlueLight),
            const SizedBox(height: AppSpacing.md),
            Text(title),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pantalla en desarrollo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showLogout) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => widget.authService.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(doseService: widget.doseService),
      const MedicationScreen(),
      const ContactsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicinas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contactos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}
