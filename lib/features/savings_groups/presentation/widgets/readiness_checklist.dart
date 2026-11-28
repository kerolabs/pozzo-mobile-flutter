import 'package:flutter/material.dart';
import 'package:pozzo/core/theme.dart';

class ChecklistItem {
  const ChecklistItem({required this.done, required this.title, required this.detail});

  final bool done;
  final String title;
  final String detail;
}

/// What is ready and what is missing, with a check or an empty circle.
class ReadinessChecklist extends StatelessWidget {
  const ReadinessChecklist({super.key, required this.items, this.title});

  final List<ChecklistItem> items;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[Text(title!, style: text.titleMedium), const SizedBox(height: 16)],
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.done ? Icons.check_circle : Icons.circle_outlined,
                      semanticLabel: item.done ? 'Cumplido' : 'Pendiente',
                      color: item.done ? PozzoStatusColors.of(context).success : colors.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: text.titleMedium),
                          Text(item.detail, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
