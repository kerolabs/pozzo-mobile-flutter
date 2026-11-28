import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pozzo/core/format/formats.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/contributions/application/contribution_use_cases.dart';
import 'package:pozzo/features/contributions/domain/contributions.dart';

/// The state of a contribution as a colored chip: "Validado", "En revisión", "Pendiente"...
class ContributionStateChip extends StatelessWidget {
  const ContributionStateChip({super.key, required this.state, this.isMine = false});

  final ContributionState state;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final (text, bg, fg, icon) = switch (state) {
      ContributionState.validated => ('Validado', status.successContainer, status.onSuccessContainer, Icons.check),
      ContributionState.inReview => (
          'En revisión',
          status.warningContainer,
          status.onWarningContainer,
          Icons.hourglass_top,
        ),
      ContributionState.pending => isMine
          ? ('Pendiente', status.warningContainer, status.onWarningContainer, Icons.schedule)
          : ('Pendiente', colors.surfaceContainerHighest, colors.onSurfaceVariant, Icons.schedule),
      ContributionState.late => ('Atrasado', colors.errorContainer, colors.onErrorContainer, Icons.warning_amber),
      ContributionState.covered => (
          'Cubierto',
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
          Icons.volunteer_activism_outlined,
        ),
    };
    return StatusChip(text: text, background: bg, foreground: fg, icon: icon);
  }
}

/// A member to choose, with a radio on the right.
class MemberOption extends StatelessWidget {
  const MemberOption({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.isMe = false,
    this.enabled = true,
    this.photoUrl,
  });

  final String name;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool isMe;
  final bool enabled;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      onTap: onTap,
      leading: InitialsAvatar(name: name, size: 40, photoUrl: photoUrl),
      title: Text(isMe ? '$name (tú)' : name),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? colors.primary : colors.onSurfaceVariant,
      ),
    );
  }
}

/// A date chosen with the calendar, up to today: the day a payment was made or received.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pick(BuildContext context) async {
    final today = Formats.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: value.isAfter(today) ? today : value,
      firstDate: DateTime(today.year - 1),
      lastDate: today,
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_month_outlined)),
            child: Text(Formats.longDate(value), style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}

/// Shows an image of the backend (a receipt or the transfer of the pot) over a black background. The
/// URL is requested when it opens, because it is signed and expires.
Future<void> showRemoteImage(
  BuildContext context, {
  required Future<String> Function() loadUrl,
  required String missingMessage,
  required String description,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: _RemoteImage(loadUrl: loadUrl, missingMessage: missingMessage, description: description),
    ),
  );
}

/// The image of the receipt of a contribution.
Future<void> showReceiptImage(BuildContext context, String contributionId) => showRemoteImage(
      context,
      loadUrl: () => getIt<GetReceiptImageUseCase>().execute(contributionId),
      missingMessage: 'Este aporte no tiene la imagen del comprobante guardada.',
      description: 'Comprobante',
    );

/// The transfer with which the organizer delivered the pot of a period.
Future<void> showPayoutProof(BuildContext context, String periodId) => showRemoteImage(
      context,
      loadUrl: () => getIt<GetPayoutProofUseCase>().execute(periodId),
      missingMessage: 'Este período no tiene la transferencia adjunta.',
      description: 'Transferencia del pozo',
    );

class _RemoteImage extends StatefulWidget {
  const _RemoteImage({required this.loadUrl, required this.missingMessage, required this.description});

  final Future<String> Function() loadUrl;
  final String missingMessage;
  final String description;

  @override
  State<_RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<_RemoteImage> {
  String? url;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      url = null;
      error = null;
    });
    try {
      final loaded = await widget.loadUrl();
      if (mounted) setState(() => url = loaded);
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        error = failure is ApiException && failure.status == 404 ? widget.missingMessage : userMessageOf(failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (url != null) {
      content = InteractiveViewer(
        child: Center(child: Image.network(url!, fit: BoxFit.contain, semanticLabel: widget.description)),
      );
    } else if (error != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(160, 48)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    } else {
      content = const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// The organizer attaches the transfer with which they delivered the pot, so the members can see it.
class AttachPayoutProofButton extends StatefulWidget {
  const AttachPayoutProofButton({super.key, required this.periodId});

  final String periodId;

  @override
  State<AttachPayoutProofButton> createState() => _AttachPayoutProofButtonState();
}

class _AttachPayoutProofButtonState extends State<AttachPayoutProofButton> {
  bool uploading = false;
  bool attached = false;
  String? error;

  Future<void> _attach() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      uploading = true;
      error = null;
    });
    try {
      await getIt<AttachPayoutProofUseCase>().execute(widget.periodId, await picked.readAsBytes());
      if (mounted) setState(() => attached = true);
    } catch (failure) {
      if (mounted) setState(() => error = userMessageOf(failure));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (attached)
          const InfoBanner(
            text: 'Adjuntaste la transferencia. Los integrantes ya pueden verla.',
            icon: Icons.task_alt,
          )
        else
          PozzoOutlinedButton(
            text: uploading ? 'Subiendo la transferencia…' : 'Adjuntar la transferencia',
            icon: Icons.add_photo_alternate_outlined,
            enabled: !uploading,
            onPressed: _attach,
          ),
        ErrorText(error),
      ],
    );
  }
}
