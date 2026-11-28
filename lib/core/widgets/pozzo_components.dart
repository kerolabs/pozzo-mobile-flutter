import 'package:flutter/material.dart';
import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';

/// The logo of Pozzo with its name, or only the mark, in the version of the current theme.
class PozzoLogo extends StatelessWidget {
  const PozzoLogo({super.key, this.size = 40, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final variant = dark ? 'dark' : 'light';
    if (showName) {
      return Image.asset('assets/images/pozzo_logo_$variant.png', height: size, semanticLabel: 'Pozzo');
    }
    return Image.asset('assets/images/pozzo_mark_$variant.png', width: size, height: size, semanticLabel: 'Pozzo');
  }
}

/// "Anna Weber" as "AW".
String initialsOf(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();

/// A person as a circle with their initials, or their photo when they have one. Without explicit
/// colors each person keeps the same color everywhere, picked from their name.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.background,
    this.foreground,
    this.photoUrl,
  });

  final String name;
  final double size;
  final Color? background;
  final Color? foreground;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = PozzoStatusColors.of(context);
    final palette = [
      (colors.primaryContainer, colors.onPrimaryContainer),
      (colors.secondaryContainer, colors.onSecondaryContainer),
      (colors.tertiaryContainer, colors.onTertiaryContainer),
      (status.successContainer, status.onSuccessContainer),
      (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    ];
    final (bg, fg) = background != null && foreground != null
        ? (background!, foreground!)
        : palette[name.trim().toLowerCase().hashCode % palette.length];
    final style = Theme.of(context).textTheme.titleMedium;
    final initials = Text(
      initialsOf(name),
      style: size > 64 ? style?.copyWith(fontSize: size * 0.36, color: fg) : style?.copyWith(color: fg),
    );
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: ColoredBox(
          color: bg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(child: initials),
              if (photoUrl != null)
                Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  semanticLabel: 'Foto de $name',
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small pill with the state of something: "Validado", "Pendiente", "Organizas".
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.text, required this.background, required this.foreground, this.icon});

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

/// A message with an icon on a soft background.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Icons.info_outline, this.background, this.foreground});

  final String text;
  final IconData icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background ?? colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground ?? colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: foreground ?? colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rows of label and value inside a rounded card, as the summaries before confirming.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(rows[i].$1, style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(rows[i].$2, style: text.titleMedium, textAlign: TextAlign.end)),
                  ],
                ),
              ),
              if (i < rows.length - 1) Divider(height: 1, color: colors.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }
}

/// The steps of a form: "Paso 2 de 4 · Monto".
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.current, required this.total, required this.label});

  final int current;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < current ? colors.primary : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Paso $current de $total · $label',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// One choice among a few: "Semanal", "Quincenal", "Mensual".
class OptionChip extends StatelessWidget {
  const OptionChip({super.key, required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.secondaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? colors.secondaryContainer : colors.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 16, color: colors.onSecondaryContainer),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selected ? colors.onSecondaryContainer : colors.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A number changed with a minus and a plus, as the seats of a group.
class NumberStepper extends StatelessWidget {
  const NumberStepper({super.key, required this.value, required this.onChanged, required this.min, required this.max});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = IconButton.styleFrom(
      backgroundColor: colors.secondaryContainer,
      foregroundColor: colors.onSecondaryContainer,
      fixedSize: const Size(48, 48),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          style: style,
          tooltip: 'Menos',
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 96,
          child: Text(value.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
        ),
        IconButton.filled(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          style: style,
          tooltip: 'Más',
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// The big round icon of a screen that confirms something went well.
class ResultBadge extends StatelessWidget {
  const ResultBadge({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final status = PozzoStatusColors.of(context);
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(color: status.successContainer, shape: BoxShape.circle),
      child: Icon(icon, size: 48, color: status.onSuccessContainer),
    );
  }
}

/// A small title above a group of fields.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.onSurfaceVariant));
  }
}

/// The title of a section inside a screen.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
          ?trailing,
        ],
      ),
    );
  }
}

/// What a screen shows while it loads, or when it could not load: the message and a retry.
class LoadingOrError extends StatelessWidget {
  const LoadingOrError({super.key, required this.loading, this.error, this.onRetry});

  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              error ?? 'No pudimos cargar la información.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              PozzoOutlinedButton(text: 'Reintentar', onPressed: onRetry!),
            ],
          ],
        ),
      ),
    );
  }
}

/// An empty list: an icon, a title and what to do next.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 56, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Shows the result of an action at the bottom of the screen.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Shows the message of a failure.
void showError(BuildContext context, Object error) => showMessage(context, userMessageOf(error));

/// Asks before an action that cannot be undone. Returns true when the member confirms.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: destructive ? TextButton.styleFrom(foregroundColor: colors.error) : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// The actions at the bottom of a form, above the keyboard.
class BottomActions extends StatelessWidget {
  const BottomActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// The title and the explanation at the top of a form.
class FormHeader extends StatelessWidget {
  const FormHeader({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: text.headlineMedium),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message!, style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// An error under a field or a form.
class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
