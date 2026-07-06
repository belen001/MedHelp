import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores MedHelp
/// Azul: color principal (botones, encabezados, navegación)
/// Verde: acciones exitosas
/// Neutros: fondo blanco/gris claro, texto gris oscuro/medio
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF15C68F);
  static const Color primaryBlueDark = Color(0xFF15C68F);
  static const Color primaryBlueLight = Color(0xFFDBEAFE);

  static const Color successGreen = Color(0xFF16A34A);
  static const Color successGreenLight = Color(0xFFDCFCE7);

  static const Color errorRed = Color(0xFFDC2626);
  static const Color warningOrange = Color(0xFFF59E0B);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1E293B); // gris oscuro
  static const Color textSecondary = Color(0xFF64748B); // gris medio
  static const Color divider = Color(0xFFE2E8F0);
}

/// Radios y espaciados estándar (Flat Design 2.0: tarjetas redondeadas + sombra sutil)
class AppRadius {
  AppRadius._();
  static const double card = 16.0;
  static const double button = 12.0;
  static const double input = 12.0;
  static const double chip = 24.0;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// Tipografía nativa por plataforma:
/// Roboto en Android, San Francisco (system default, vía Cupertino) en iOS.
/// google_fonts se usa para Roboto; en iOS dejamos que el sistema
/// resuelva a San Francisco usando el fontFamily por defecto (null).
TextTheme _buildTextTheme() {
  final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

  if (isIOS) {
    // San Francisco es la fuente nativa de iOS; Flutter la usa por defecto
    // en Cupertino, así que no forzamos fontFamily y ajustamos solo pesos/tamaños.
    return const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
    );
  }

  // Android -> Roboto vía google_fonts
  return TextTheme(
    headlineLarge: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    headlineMedium: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    titleLarge: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
    bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
    labelLarge: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.light,
        primary: AppColors.primaryBlue,
        secondary: AppColors.successGreen,
        error: AppColors.errorRed,
        surface: AppColors.surface,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
      ),

      // Tarjetas con bordes redondeados y sombra sutil (Flat Design 2.0)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),

      // Botones: mínimo 48x48 dp de área táctil (requisito de interactividad)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
        ),
      ),

      // Botón de éxito (ej. "Confirmar Toma") — usar Theme.of(context).extension o
      // envolver con color: AppColors.successGreen donde se requiera explícitamente.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize: const Size(48, 48),
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),

      // Inputs de formulario con validación en tiempo real (borde de error visible)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        errorStyle: const TextStyle(color: AppColors.errorRed, fontSize: 12),
      ),

      // Bottom navigation: Inicio, Medicamentos, Contactos, Configuración/Historial
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),

      // Snackbars/Toasts para confirmar acciones completadas
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryBlueLight,
        labelStyle: const TextStyle(color: AppColors.primaryBlueDark, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}

/// Colores semánticos de estado (toma completada / pendiente / vencida)
/// para usar directamente en widgets como el Dashboard "Tomas de Hoy".
class DoseStatusColors {
  DoseStatusColors._();
  static const Color completed = AppColors.successGreen;
  static const Color completedBg = AppColors.successGreenLight;
  static const Color pending = AppColors.textSecondary;
  static const Color overdue = AppColors.errorRed;
  static const Color overdueBg = Color(0xFFFEE2E2);
}
