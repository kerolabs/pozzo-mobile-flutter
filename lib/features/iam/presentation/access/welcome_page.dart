import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/iam/infrastructure/local/session_manager.dart';
import 'package:pozzo/features/iam/presentation/access/phone_page.dart';

/// A1: the first screen of the application, before signing in. It presents Pozzo and leads to the access
/// with the phone number or with an invitation code.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _continue(BuildContext context, {required bool joinAfterSignIn}) {
    getIt<SessionManager>().joinAfterSignIn = joinAfterSignIn;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PhonePage()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(alignment: Alignment.centerLeft, child: PozzoLogo()),
              const SizedBox(height: 24),
              // The circle takes the space left, so the texts and buttons always fit.
              const Expanded(child: Center(child: _GroupCircle())),
              const SizedBox(height: 32),
              Text('Tu junta, sin cuaderno ni capturas', style: text.headlineLarge),
              const SizedBox(height: 12),
              Text(
                'Pozzo valida los aportes con el comprobante y avisa a quien falta. No maneja tu dinero.',
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              PozzoPrimaryButton(
                text: 'Continuar con mi celular',
                icon: Icons.phone_outlined,
                onPressed: () => _continue(context, joinAfterSignIn: false),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _continue(context, joinAfterSignIn: true),
                child: const Text('Tengo un código de invitación'),
              ),
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
}

/// Eight members around the pot: the idea of a junta.
class _GroupCircle extends StatelessWidget {
  const _GroupCircle();

  static const _members = ['RM', 'JS', 'CV', 'SG', 'LP', 'MQ', 'DR', 'AW'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final palette = [
      (colors.secondaryContainer, colors.onSecondaryContainer),
      (colors.tertiary, colors.onTertiaryContainer),
      (colors.primaryContainer, colors.onPrimaryContainer),
      (status.successContainer, status.onSuccessContainer),
      (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    ];
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final radius = size * 0.4;
          final bubble = size * 0.13;
          return Stack(
            children: [
              Center(
                child: Container(
                  width: size * 0.8,
                  height: size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.outlineVariant, width: 1.5),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: size * 0.42,
                  height: size * 0.42,
                  decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
                  child: Icon(Icons.savings_outlined, size: size * 0.19, color: colors.surfaceContainer),
                ),
              ),
              for (var i = 0; i < _members.length; i++)
                Positioned(
                  left: size / 2 + radius * cos(-pi / 2 + i * 2 * pi / _members.length) - bubble / 2,
                  top: size / 2 + radius * sin(-pi / 2 + i * 2 * pi / _members.length) - bubble / 2,
                  child: Container(
                    width: bubble,
                    height: bubble,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: palette[i % palette.length].$1, shape: BoxShape.circle),
                    child: Text(
                      _members[i],
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: palette[i % palette.length].$2),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
