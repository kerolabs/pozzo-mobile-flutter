import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/iam/presentation/access/code_page.dart';
import 'package:pozzo/features/iam/presentation/access/phone_view_model.dart';
import 'package:pozzo/features/iam/presentation/access/recovery_page.dart';

/// A2: "¿Cuál es tu número de celular?".
class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final PhoneViewModel viewModel = getIt<PhoneViewModel>();

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final request = await viewModel.sendCode();
    if (request == null || !mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => CodePage(request: request)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar a Pozzo')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final state = viewModel.state;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    const FormHeader(
                      title: '¿Cuál es tu número de celular?',
                      message: 'Te enviaremos un código por SMS para confirmar que el número es tuyo. '
                          'No necesitas contraseña.',
                    ),
                    PozzoTextField(
                      label: 'Número de celular',
                      value: state.phone,
                      onChanged: viewModel.onPhoneChanged,
                      prefix: '+51',
                      placeholder: '999 000 123',
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      supportingText:
                          'Los 9 dígitos de tu celular, empezando por 9. Solo lo usamos para verificar tu identidad.',
                      errorText: state.errorMessage,
                      onSubmitted: (_) => _sendCode(),
                    ),
                  ],
                ),
              ),
              BottomActions(
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecoveryPage()),
                    ),
                    child: const Text('¿Perdiste tu número? Recupera tu cuenta'),
                  ),
                  PozzoPrimaryButton(
                    text: 'Enviar código',
                    onPressed: _sendCode,
                    enabled: state.canSend,
                    loading: state.isLoading,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
