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
  final _passwordConfirmController = TextEditingController();
  final _nameController = TextEditingController();
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
    _passwordConfirmController.dispose();
    _nameController.dispose();
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

  String? _validateName(String? value) {
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
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
      );
    }

    if (!mounted) return;

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autenticación exitosa'),
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
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
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
                                controller: _nameController,
                                prefixIcon: Icons.person,
                                validator: _validateName,
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
                            const SizedBox(height: AppSpacing.md),
                            if (!_isLogin) ...[
                              MedHelpTextField(
                                label: 'Confirmar Contraseña',
                                controller: _passwordConfirmController,
                                obscureText: true,
                                prefixIcon: Icons.lock,
                                validator: (value) {
                                  if (!_isLogin) {
                                    if (value == null || value.isEmpty) return 'La confirmación de contraseña es obligatoria';
                                    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
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
