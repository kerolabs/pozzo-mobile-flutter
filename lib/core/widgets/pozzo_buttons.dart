import 'package:flutter/material.dart';

/// The main action of a screen: full width, pill shaped, with a spinner while it works.
class PozzoPrimaryButton extends StatelessWidget {
  const PozzoPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
          )
        : Text(text);
    // While loading the button keeps its color so the spinner is visible.
    final VoidCallback? onTap = enabled || loading
        ? () {
            if (!loading) onPressed();
          }
        : null;
    if (icon != null && !loading) {
      return FilledButton.icon(onPressed: onTap, icon: Icon(icon, size: 20), label: child);
    }
    return FilledButton(onPressed: onTap, child: child);
  }
}

/// A secondary action: outlined and pill shaped.
class PozzoOutlinedButton extends StatelessWidget {
  const PozzoOutlinedButton({super.key, required this.text, required this.onPressed, this.enabled = true, this.icon});

  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final onTap = enabled ? onPressed : null;
    if (icon != null) {
      return OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 20), label: Text(text));
    }
    return OutlinedButton(onPressed: onTap, child: Text(text));
  }
}

/// A destructive action, such as deleting a group.
class PozzoDangerButton extends StatelessWidget {
  const PozzoDangerButton({super.key, required this.text, required this.onPressed, this.icon});

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = OutlinedButton.styleFrom(
      foregroundColor: colors.error,
      side: BorderSide(color: colors.error),
    );
    if (icon != null) {
      return OutlinedButton.icon(onPressed: onPressed, style: style, icon: Icon(icon, size: 20), label: Text(text));
    }
    return OutlinedButton(onPressed: onPressed, style: style, child: Text(text));
  }
}
