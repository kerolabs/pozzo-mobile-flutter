import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/access/recovery_state.dart';
import 'package:pozzo/features/iam/presentation/access/recovery_view_model.dart';
import 'package:pozzo/features/iam/presentation/widgets/code_input.dart';

/// A5: "¿Perdiste tu número?". Back goes to the previous step before closing the page.
class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final RecoveryViewModel viewModel = getIt<RecoveryViewModel>();

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  void _back() {
    if (!viewModel.back()) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        final atStart = state.step == RecoveryStep.email || state.step == RecoveryStep.phone;
        return PopScope(
          canPop: atStart,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) viewModel.back();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Recuperar mi cuenta'),
              leading: BackButton(onPressed: _back),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: _content(state),
                  ),
                ),
                BottomActions(children: [_action(state)]),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _content(RecoveryState state) {
    switch (state.step) {
      case RecoveryStep.email:
        return [
          const FormHeader(
            title: '¿Perdiste tu número?',
            message: 'Ingresa el correo de respaldo de tu perfil. Te enviaremos un código para confirmar que la '
                'cuenta es tuya y luego asociarás tu número nuevo. Tus juntas y tu historial se mantienen.',
          ),
          PozzoTextField(
            label: 'Correo de respaldo',
            value: state.email,
            onChanged: viewModel.onEmailChanged,
            placeholder: 'anna@ejemplo.pe',
            keyboardType: TextInputType.emailAddress,
            errorText: state.errorMessage,
          ),
        ];
      case RecoveryStep.phone:
        return [
          const FormHeader(
            title: 'Tu número nuevo',
            message: 'Confirmamos que la cuenta es tuya. Ingresa el celular que usarás desde ahora; te enviaremos '
                'un código por SMS.',
          ),
          PozzoTextField(
            label: 'Número de celular',
            value: state.phone,
            onChanged: viewModel.onPhoneChanged,
            prefix: '+51',
            placeholder: '999 000 123',
            keyboardType: TextInputType.phone,
            errorText: state.errorMessage,
          ),
          const SizedBox(height: 16),
          const InfoBanner(text: 'Al terminar se cerrará la sesión en el celular que perdiste.'),
        ];
      case RecoveryStep.emailCode:
      case RecoveryStep.phoneCode:
        final email = state.step == RecoveryStep.emailCode;
        return [
          FormHeader(
            title: email ? 'Revisa tu correo' : 'Ingresa el código',
            message: email
                ? 'Si ${state.email} es el correo de respaldo de una cuenta, te enviamos un código de 6 dígitos. '
                    'Revisa también la carpeta de spam.'
                : 'Enviamos un código de 6 dígitos por SMS al ${PhoneNumbers.display(state.phone)}.',
          ),
          CodeInput(code: state.code, onChanged: viewModel.onCodeChanged, isError: state.errorMessage != null),
          ErrorText(state.errorMessage),
          const SizedBox(height: 20),
          ResendCode(secondsToResend: state.secondsToResend, enabled: state.canResend, onResend: viewModel.resend),
        ];
    }
  }

  Widget _action(RecoveryState state) {
    switch (state.step) {
      case RecoveryStep.email:
        return PozzoPrimaryButton(
          text: 'Enviar código',
          onPressed: viewModel.sendEmailCode,
          enabled: state.canSendEmail,
          loading: state.isLoading,
        );
      case RecoveryStep.phone:
        return PozzoPrimaryButton(
          text: 'Enviar código',
          onPressed: viewModel.sendPhoneCode,
          enabled: state.canSendPhone,
          loading: state.isLoading,
        );
      case RecoveryStep.emailCode:
      case RecoveryStep.phoneCode:
        return PozzoPrimaryButton(
          text: 'Verificar',
          onPressed: viewModel.verify,
          enabled: state.canVerify,
          loading: state.isLoading,
        );
    }
  }
}
