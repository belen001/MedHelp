import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/index.dart';

/// Pantalla de Bienvenida (Login/Registro)
/// Permite autenticación de usuarios con email/contraseña
class WelcomeScreen extends StatefulWidget {
  final AuthService authService;

  const WelcomeScreen({required this.authService, super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLogin = true; // Alterna entre login y registro
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Bloquear rotación (solo Portrait)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Ingrese un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre completo es obligatorio';
    }
    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    bool success;
    if (_isLogin) {
      success = await widget.authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await widget.authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Toma registrada'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      // Logo y título
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlueLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medication,
                              size: 40,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'MedHelp',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _isLogin
                                ? 'Accede a tu cuenta'
                                : 'Crea una nueva cuenta',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Formulario
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              MedHelpTextField(
                                label: 'Nombre Completo',
                                controller: _fullNameController,
                                prefixIcon: Icons.person,
                                validator: _validateFullName,
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            MedHelpTextField(
                              label: 'Correo Electrónico',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            MedHelpTextField(
                              label: 'Contraseña',
                              controller: _passwordController,
                              obscureText: true,
                              prefixIcon: Icons.lock,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            PrimaryButton(
                              label: _isLogin ? 'Ingresar' : 'Registrarse',
                              isLoading: widget.authService.isLoading,
                              onPressed: _handleAuth,
                              icon: _isLogin ? Icons.login : Icons.person_add,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Cambiar entre login y registro
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? '¿No tienes cuenta?'
                                  : '¿Ya tienes cuenta?',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            TextButton(
                              onPressed: () {
                                setState(() => _isLogin = !_isLogin);
                                _formKey.currentState?.reset();
                              },
                              child: Text(
                                _isLogin ? 'Regístrate' : 'Inicia Sesión',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
