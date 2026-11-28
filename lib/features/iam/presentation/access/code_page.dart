import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/access/code_view_model.dart';
import 'package:pozzo/features/iam/presentation/access/register_page.dart';
import 'package:pozzo/features/iam/presentation/widgets/code_input.dart';

/// A3: "Ingresa el código". A registered number opens the session (the root of the app takes the
/// member to their groups); a new one goes on to complete the profile.
class CodePage extends StatefulWidget {
  const CodePage({super.key, required this.request});

  final CodeRequest request;

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  late final CodeViewModel viewModel = getIt<CodeViewModel>(param1: widget.request)..onVerified = _onVerified;

  void _onVerified(Verification verification) {
    if (!mounted) return;
    if (verification is RegistrationRequired) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegisterPage(registration: verification)),
      );
    }
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar número')),
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
                    FormHeader(
                      title: 'Ingresa el código',
                      message: 'Enviamos un código de 6 dígitos por SMS al ${PhoneNumbers.display(state.phone)}.',
                    ),
                    CodeInput(code: state.code, onChanged: viewModel.onCodeChanged, isError: state.errorMessage != null),
                    ErrorText(state.errorMessage),
                    const SizedBox(height: 20),
                    ResendCode(
                      secondsToResend: state.secondsToResend,
                      enabled: state.canResend,
                      onResend: viewModel.resend,
                    ),
                    Center(
                      child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cambiar número')),
                    ),
                  ],
                ),
              ),
              BottomActions(
                children: [
                  PozzoPrimaryButton(
                    text: 'Verificar',
                    onPressed: viewModel.verify,
                    enabled: state.canVerify,
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
