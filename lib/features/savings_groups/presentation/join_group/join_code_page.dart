import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/presentation/join_group/join_preview_page.dart';
import 'package:pozzo/features/savings_groups/presentation/join_group/join_view_models.dart';

/// G4: "Unirme a una junta".
class JoinCodePage extends StatefulWidget {
  const JoinCodePage({super.key});

  @override
  State<JoinCodePage> createState() => _JoinCodePageState();
}

class _JoinCodePageState extends State<JoinCodePage> {
  final JoinCodeViewModel viewModel = getIt<JoinCodeViewModel>();

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = await viewModel.search();
    if (code == null || !mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => JoinPreviewPage(code: code)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unirme a una junta')),
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
                      title: 'Ingresa el código de invitación',
                      message: 'Lo encuentras en el mensaje que te compartió tu cabeza de junta. También puedes abrir '
                          'el enlace directamente.',
                    ),
                    PozzoTextField(
                      label: 'Código de invitación',
                      value: state.code,
                      onChanged: viewModel.onCodeChanged,
                      placeholder: 'JB7K4M',
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      keyboardType: TextInputType.visiblePassword,
                      supportingText: 'Son ${InvitationCodes.length} caracteres.',
                      errorText: state.errorMessage,
                      onSubmitted: (_) => _search(),
                    ),
                  ],
                ),
              ),
              BottomActions(
                children: [
                  PozzoPrimaryButton(
                    text: 'Buscar junta',
                    onPressed: _search,
                    enabled: state.canSearch,
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
