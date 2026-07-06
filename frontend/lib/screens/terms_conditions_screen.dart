import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Términos y Condiciones"),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                "Antes de utilizar MedHelp, lea cuidadosamente los siguientes términos y condiciones.",
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SingleChildScrollView(
                      child: Text(
                        '''
TÉRMINOS Y CONDICIONES DE USO

Bienvenido a MedHelp.

Antes de utilizar nuestra herramienta, es fundamental que lea y acepte los siguientes términos, los cuales garantizan el respeto a sus derechos de salud y la protección de su privacidad según la legislación chilena vigente.

1. CONSENTIMIENTO INFORMADO Y LICITUD

Al registrarse, usted otorga su consentimiento libre, específico e informado para el tratamiento de sus datos personales.

Dado que la información sobre sus medicamentos se considera un dato personal sensible relativo a la salud, su tratamiento se realiza bajo altos estándares de seguridad y con la única finalidad de prestar el servicio de recordatorio y apoyo en su atención de salud.

2. SUS DERECHOS COMO TITULAR DE DATOS (DERECHOS ARCO+)

De acuerdo con la Ley 21.719, usted tiene derecho a:

• Acceso:
Solicitar confirmación de si sus datos están siendo tratados y obtener una copia de ellos.

• Rectificación:
Modificar datos inexactos o desactualizados.

• Supresión:
Solicitar la eliminación de sus datos cuando ya no sean necesarios para los fines del servicio.

• Oposición:
Oponerse al tratamiento de sus datos por motivos legítimos.

• Portabilidad:
Recibir sus datos en un formato electrónico estructurado y de uso común para transmitirlos a otro responsable.

• Bloqueo:
Solicitar la suspensión temporal de cualquier operación de tratamiento mientras se resuelve una solicitud de rectificación o supresión.

3. SEGURIDAD Y CONFIDENCIALIDAD DE LA INFORMACIÓN

Nuestra aplicación implementa medidas técnicas y organizativas para garantizar la confidencialidad, integridad y disponibilidad de su información.

Como prestadores de un servicio de salud digital, cumplimos con los estándares de seguridad establecidos por el Ministerio de Salud para proteger sus datos contra accesos no autorizados o filtraciones.

El deber de secreto de nuestro equipo subsiste incluso después de finalizada la relación con el usuario.

4. CONTINUIDAD DEL CUIDADO E INTEROPERABILIDAD

Bajo el marco de la Ley 21.668, la información registrada en esta plataforma podrá ser configurada para permitir la interoperabilidad con otros prestadores de salud, con el objetivo de garantizar la continuidad de su cuidado médico.

Esto asegura que, si usted lo autoriza, los profesionales que participen directamente en su atención puedan acceder a los antecedentes esenciales de su tratamiento.

5. CALIDAD Y SEGURIDAD EN LA ATENCIÓN

Como parte de su derecho a una atención de salud segura, nos comprometemos a cumplir con los protocolos de seguridad para evitar errores en la gestión de sus recordatorios.

No obstante, el usuario es responsable de ingresar la información de sus medicamentos de manera exacta y actual, conforme al principio de calidad de datos.

6. RESPONSABILIDAD DEL PRESTADOR

MedHelp actúa como responsable del tratamiento de los registros generados.

En caso de cualquier vulneración a las medidas de seguridad que afecte sus derechos, la aplicación se compromete a reportar dicho incidente a la Agencia de Protección de Datos Personales y a usted como titular, sin dilaciones indebidas.

7. PROCEDIMIENTO DE RECLAMOS

Usted puede ejercer sus derechos directamente ante nosotros mediante el correo:

reclamos@medhelp.cl

Responderemos a sus solicitudes en un plazo máximo de 30 días corridos.

Si considera que su solicitud no ha sido atendida correctamente, tiene derecho a reclamar ante la Agencia de Protección de Datos Personales.

Al presionar "Acepto", usted declara haber leído y comprendido estos términos y condiciones y autoriza el tratamiento de sus datos conforme a la legislación chilena vigente.
''',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Rechazo"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(
                          color: AppColors.errorRed,
                          width: 2,
                        ),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Acepto"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}