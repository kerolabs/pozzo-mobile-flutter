import 'package:flutter/material.dart';

/// A1: the first screen of the application, before signing in. It presents Pozzo and leads to the access
/// with the phone number or with an invitation code.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  dark ? 'assets/images/pozzo_logo_dark.png' : 'assets/images/pozzo_logo_light.png',
                  height: 48,
                  semanticLabel: 'Pozzo',
                ),
              ),
              const Spacer(),
              Text(
                'Tu junta, sin cuaderno ni capturas',
                style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: colors.onSurface),
              ),
              const SizedBox(height: 16),
              Text(
                'Pozzo valida los aportes con el comprobante y avisa a quien falta. No maneja tu dinero.',
                style: text.titleMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _comingSoon(context),
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Continuar con mi celular'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _comingSoon(context),
                child: const Text('Tengo un código de invitación'),
              ),
              const SizedBox(height: 8),
              Text(
                'Al continuar aceptas los Términos y Condiciones',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The access with the phone and with a code is the next part of the IAM context.
  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disponible en la siguiente versión.')),
    );
  }
}
