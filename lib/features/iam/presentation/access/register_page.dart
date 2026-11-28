import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/access/register_view_model.dart';

/// A4: "Casi listo".
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.registration});

  final RegistrationRequired registration;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final RegisterViewModel viewModel = getIt<RegisterViewModel>(param1: widget.registration);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = PozzoStatusColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tu perfil')),
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
                      title: 'Casi listo',
                      message: 'Solo necesitamos tu nombre para que tu grupo te reconozca.',
                    ),
                    InfoBanner(
                      text: 'Número verificado: ${PhoneNumbers.display(widget.registration.phoneNumber)}',
                      icon: Icons.check_circle_outline,
                      background: status.successContainer,
                      foreground: status.onSuccessContainer,
                    ),
                    const SizedBox(height: 24),
                    PozzoTextField(
                      label: 'Tu nombre',
                      value: state.displayName,
                      onChanged: viewModel.onNameChanged,
                      placeholder: 'Anna Weber',
                      textCapitalization: TextCapitalization.words,
                      errorText: state.errorMessage,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: state.termsAccepted,
                      onChanged: (value) => viewModel.onTermsChanged(value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Acepto los Términos y Condiciones y la Política de Privacidad de Pozzo.'),
                    ),
                  ],
                ),
              ),
              BottomActions(
                children: [
                  PozzoPrimaryButton(
                    text: 'Empezar',
                    onPressed: viewModel.submit,
                    enabled: state.canSubmit,
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
