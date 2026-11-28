import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/profile/change_phone_view_model.dart';
import 'package:pozzo/features/iam/presentation/widgets/code_input.dart';

/// I3: "Cambiar número".
class ChangePhonePage extends StatefulWidget {
  const ChangePhonePage({super.key});

  @override
  State<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends State<ChangePhonePage> {
  late final ChangePhoneViewModel viewModel = getIt<ChangePhoneViewModel>()..onChanged = _onChanged;

  void _onChanged() {
    if (!mounted) return;
    showMessage(context, 'Tu número cambió.');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        return PopScope(
          canPop: !state.codeSent,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) viewModel.back();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Cambiar número'),
              leading: BackButton(
                onPressed: () {
                  if (!viewModel.back()) Navigator.pop(context);
                },
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: state.codeSent
                        ? [
                            FormHeader(
                              title: 'Ingresa el código',
                              message:
                                  'Enviamos un código de 6 dígitos por SMS al ${PhoneNumbers.display(state.phone)}.',
                            ),
                            CodeInput(
                              code: state.code,
                              onChanged: viewModel.onCodeChanged,
                              isError: state.errorMessage != null,
                            ),
                            ErrorText(state.errorMessage),
                            const SizedBox(height: 20),
                            ResendCode(
                              secondsToResend: state.secondsToResend,
                              enabled: state.canResend,
                              onResend: viewModel.sendCode,
                            ),
                          ]
                        : [
                            const FormHeader(
                              title: 'Tu número nuevo',
                              message: 'Te enviaremos un código por SMS al número nuevo. Tus juntas, aportes e '
                                  'historial se mantienen.',
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
                          ],
                  ),
                ),
                BottomActions(
                  children: [
                    if (state.codeSent)
                      PozzoPrimaryButton(
                        text: 'Cambiar número',
                        onPressed: viewModel.verify,
                        enabled: state.canVerify,
                        loading: state.isLoading,
                      )
                    else
                      PozzoPrimaryButton(
                        text: 'Enviar código',
                        onPressed: viewModel.sendCode,
                        enabled: state.canSend,
                        loading: state.isLoading,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
