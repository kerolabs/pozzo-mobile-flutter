import 'package:flutter/material.dart';

/// A field of the style guide: the label above, the box with rounded corners and a help or error text
/// below.
///
/// The value lives in the view model, as in the Kotlin screens: the field shows [value] and reports
/// every change with [onChanged]; when the view model cleans the text (only digits, a maximum length)
/// the field shows the cleaned value.
class PozzoTextField extends StatefulWidget {
  const PozzoTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.prefix,
    this.supportingText,
    this.errorText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.maxLines = 1,
    this.autofocus = false,
    this.onSubmitted,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final String? prefix;
  final String? supportingText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PozzoTextField> createState() => _PozzoTextFieldState();
}

class _PozzoTextFieldState extends State<PozzoTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(PozzoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final help = widget.errorText ?? widget.supportingText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: text.titleSmall?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          maxLines: widget.maxLines,
          style: text.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            prefixText: widget.prefix == null ? null : '${widget.prefix}  ',
            errorText: widget.errorText == null ? null : '',
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        ),
        if (help != null) ...[
          const SizedBox(height: 6),
          Text(
            help,
            style: text.bodySmall?.copyWith(color: widget.errorText != null ? colors.error : colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
