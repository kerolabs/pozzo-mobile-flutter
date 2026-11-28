import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';
import 'package:pozzo/features/contributions/presentation/my_contributions/my_contributions_page.dart';
import 'package:pozzo/features/contributions/presentation/register/register_contribution_view_model.dart';
import 'package:pozzo/features/contributions/presentation/widgets/contribution_widgets.dart';
import 'package:pozzo/features/iam/domain/profile.dart';

/// C2: "Aportar al pozo": where to transfer, the photo of the receipt, its data and the result.
class RegisterContributionPage extends StatefulWidget {
  const RegisterContributionPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<RegisterContributionPage> createState() => _RegisterContributionPageState();
}

class _RegisterContributionPageState extends State<RegisterContributionPage> {
  late final RegisterContributionViewModel viewModel =
      getIt<RegisterContributionViewModel>(param1: widget.groupId);

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  void _back() {
    if (!viewModel.back()) Navigator.pop(context);
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    viewModel.onImageChosen(await picked.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final state = viewModel.state;
        final title = switch (state.step) {
          RegisterStep.instructions => 'Aportar al pozo',
          RegisterStep.capture => 'Subir comprobante',
          RegisterStep.review => 'Revisa los datos',
          RegisterStep.result => '',
        };
        return PopScope(
          canPop: state.step == RegisterStep.instructions || state.step == RegisterStep.result,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) viewModel.back();
          },
          child: Scaffold(
            appBar: state.step == RegisterStep.result
                ? null
                : AppBar(title: Text(title), leading: BackButton(onPressed: _back)),
            body: SafeArea(
              child: switch (state.step) {
                RegisterStep.instructions => _instructions(state),
                RegisterStep.capture => _capture(),
                RegisterStep.review => _review(state),
                RegisterStep.result => _result(state),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _instructions(RegisterContributionState state) {
    final cycle = state.cycle;
    final period = state.period;
    if (cycle == null || period == null) {
      return LoadingOrError(loading: state.errorMessage == null, error: state.errorMessage, onRetry: viewModel.load);
    }
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final method = cycle.destinationMethod.isEmpty
        ? ''
        : '${cycle.destinationMethod[0]}${cycle.destinationMethod.substring(1).toLowerCase()}';
    const steps = [
      'Haz la transferencia desde tu billetera',
      'Guarda el comprobante o tómale una foto',
      'Súbelo aquí y Pozzo lo valida por ti',
    ];
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfiere ${Formats.soles(period.myAmount)} a',
                        style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          InitialsAvatar(name: cycle.payeeName),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cycle.payeeName, style: text.titleMedium),
                                Text(
                                  'Cabeza de junta · $method',
                                  style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 32, color: colors.outlineVariant),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Número de destino',
                                  style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
                                ),
                                Text(PhoneNumbers.grouped(cycle.destinationPhone), style: text.headlineSmall),
                              ],
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.content_copy_outlined, size: 16),
                            label: const Text('Copiar'),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: cycle.destinationPhone));
                              if (mounted) showMessage(context, 'Número copiado');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.surfaceContainerHighest,
                        child: Text('${i + 1}', style: text.labelLarge),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(steps[i], style: text.bodyLarge)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              InfoBanner(
                text: 'Pozzo no recibe ni retiene tu dinero. La transferencia va directo a '
                    '${cycle.payeeName.split(' ').first}.',
              ),
            ],
          ),
        ),
        BottomActions(
          children: [
            PozzoPrimaryButton(
              text: 'Ya transferí, subir comprobante',
              icon: Icons.upload_outlined,
              onPressed: () => viewModel.goTo(RegisterStep.capture),
            ),
          ],
        ),
      ],
    );
  }

  Widget _capture() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 320,
                decoration: BoxDecoration(color: colors.inverseSurface, borderRadius: BorderRadius.circular(28)),
                child: Icon(Icons.receipt_long_outlined, size: 96, color: colors.onInverseSurface),
              ),
              const SizedBox(height: 16),
              Text(
                'Encuadra el comprobante completo: monto, fecha, destinatario y número de operación. Pozzo guarda la '
                'imagen para que tú y la cabeza puedan verla después.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        BottomActions(
          children: [
            PozzoPrimaryButton(
              text: 'Tomar foto',
              icon: Icons.photo_camera_outlined,
              onPressed: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 8),
            PozzoOutlinedButton(
              text: 'Elegir de la galería',
              icon: Icons.image_outlined,
              onPressed: () => _pick(ImageSource.gallery),
            ),
            TextButton(onPressed: viewModel.enterManually, child: const Text('Ingresar los datos a mano')),
          ],
        ),
      ],
    );
  }

  Widget _review(RegisterContributionState state) {
    final status = PozzoStatusColors.of(context);
    final form = state.form;
    final period = state.period;
    final cycle = state.cycle;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Completa los datos tal como aparecen en tu comprobante.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (state.image != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(state.image!, height: 160, fit: BoxFit.cover),
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => viewModel.goTo(RegisterStep.capture),
                  child: Text(state.image != null ? 'Tomar otra foto' : 'Subir una foto del comprobante'),
                ),
              ),
              if (period != null && cycle != null && form.amountValue != null) ...[
                if (state.matchesExpected)
                  InfoBanner(
                    icon: Icons.check_circle_outline,
                    background: status.successContainer,
                    foreground: status.onSuccessContainer,
                    text: 'Coincide con lo esperado: ${Formats.soles(period.myAmount)} a ${cycle.payeeName}',
                  )
                else
                  InfoBanner(
                    icon: Icons.warning_amber,
                    background: status.warningContainer,
                    foreground: status.onWarningContainer,
                    text: 'No coincide con lo esperado (${Formats.soles(period.myAmount)} a ${cycle.payeeName} hasta '
                        'el ${Formats.mediumDate(period.cutoffDate)}). Si lo registras así, la cabeza lo revisará.',
                  ),
                const SizedBox(height: 16),
              ],
              PozzoTextField(
                label: 'Monto',
                value: form.amount,
                onChanged: viewModel.onAmountChanged,
                prefix: 'S/',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DateField(label: 'Fecha del pago', value: form.paidAt, onChanged: viewModel.onPaidAtChanged),
              const SizedBox(height: 16),
              PozzoTextField(label: 'Destinatario', value: form.payeeName, onChanged: viewModel.onPayeeChanged),
              const SizedBox(height: 16),
              PozzoTextField(
                label: 'N.º de operación',
                value: form.operationNumber,
                onChanged: viewModel.onOperationChanged,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const FieldLabel('Aplicación'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final source in ReceiptSource.values) ...[
                    if (source != ReceiptSource.values.first) const SizedBox(width: 8),
                    Expanded(
                      child: OptionChip(
                        text: source == ReceiptSource.bank ? 'Banco' : source.label,
                        selected: form.source == source,
                        onTap: () => viewModel.onSourceChanged(source),
                      ),
                    ),
                  ],
                ],
              ),
              ErrorText(state.errorMessage),
            ],
          ),
        ),
        BottomActions(
          children: [
            PozzoPrimaryButton(
              text: 'Confirmar aporte',
              onPressed: viewModel.confirm,
              enabled: form.isComplete,
              loading: state.isSaving,
            ),
          ],
        ),
      ],
    );
  }

  Widget _result(RegisterContributionState state) {
    final contribution = state.result!;
    final status = PozzoStatusColors.of(context);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final validated =
        contribution.status == ContributionStatus.validated || contribution.status == ContributionStatus.approved;
    final period = state.period;
    final receipt = contribution.receipt;
    final payee = state.cycle?.payeeName.split(' ').first ?? 'La cabeza';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: validated ? status.successContainer : status.warningContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    validated ? Icons.check_circle : Icons.hourglass_top,
                    size: 48,
                    color: validated ? status.onSuccessContainer : status.onWarningContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                validated ? '¡Aporte validado!' : 'Tu aporte está en revisión',
                textAlign: TextAlign.center,
                style: text.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                validated
                    ? 'Tu aporte de ${Formats.soles(contribution.amount)} del período ${period?.turnNumber ?? ''} '
                        'quedó registrado al instante.'
                    : 'El comprobante no coincide con lo esperado. $payee lo revisará y te avisaremos.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              if (state.imageNotKept) ...[
                const SizedBox(height: 16),
                const InfoBanner(
                  text: 'Tu aporte quedó registrado, pero no pudimos guardar la imagen del comprobante.',
                ),
              ],
              const SizedBox(height: 16),
              if (validated)
                SummaryCard(
                  rows: [
                    ('Período', '${period?.turnNumber} de ${period?.totalTurns}'),
                    ('Monto', Formats.soles(contribution.amount)),
                    if (receipt != null) ('Fecha', Formats.mediumDate(receipt.paidAt)),
                    if (receipt != null) ('N.º de operación', receipt.operationNumber),
                  ],
                )
              else if (contribution.inconsistencies.isNotEmpty)
                SummaryCard(
                  rows: [
                    for (final item in contribution.inconsistencies) ...[
                      ('Resultado', item.label),
                      item.field.startsWith('EDITED_')
                          ? ('Leído en el comprobante', item.expected)
                          : ('Esperado · ${item.fieldLabel}', item.expected),
                      (item.field.startsWith('EDITED_') ? 'Corregido a' : 'Leído en el comprobante', item.found),
                    ],
                  ],
                ),
            ],
          ),
        ),
        BottomActions(
          children: [
            PozzoPrimaryButton(
              text: validated ? 'Ver el estado del pozo' : 'Entendido',
              onPressed: () => Navigator.pop(context),
            ),
            if (validated)
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyContributionsPage(groupId: widget.groupId)),
                ),
                child: const Text('Ver mis aportes'),
              ),
          ],
        ),
      ],
    );
  }
}
