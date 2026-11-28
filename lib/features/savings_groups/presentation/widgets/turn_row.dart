import 'package:flutter/material.dart';
import 'package:pozzo/core/format/formats.dart';

/// A turn of the calendar: its number in a circle, who collects and when.
class TurnRow extends StatelessWidget {
  const TurnRow({
    super.key,
    required this.turnNumber,
    required this.name,
    this.cutoffDate,
    this.highlighted = false,
    this.subtitle,
    this.trailing,
  });

  final int turnNumber;
  final String name;
  final DateTime? cutoffDate;
  final bool highlighted;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final detail = subtitle ?? (cutoffDate == null ? null : Formats.mediumDate(cutoffDate!));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlighted ? colors.primary : colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$turnNumber',
              style: text.titleMedium?.copyWith(color: highlighted ? colors.onPrimary : colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.titleMedium),
                if (detail != null) Text(detail, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
