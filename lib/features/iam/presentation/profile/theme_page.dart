import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/infrastructure/local/session_manager.dart';
import 'package:pozzo/features/iam/presentation/profile/theme_view_model.dart';

/// I2: "Tema visual".
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  final ThemeViewModel viewModel = getIt<ThemeViewModel>(param1: getIt<SessionManager>().theme);

  static const _icons = {
    ThemePreference.system: Icons.brightness_auto_outlined,
    ThemePreference.light: Icons.light_mode_outlined,
    ThemePreference.dark: Icons.dark_mode_outlined,
  };

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tema visual')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Text(
              'Elige cómo quieres ver Pozzo. El cambio se aplica al instante.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            for (final theme in ThemePreference.values) ...[
              const SizedBox(height: 12),
              _ThemeOption(
                icon: _icons[theme]!,
                label: theme.label,
                selected: theme == viewModel.state.theme,
                onTap: () => viewModel.choose(theme),
              ),
            ],
            ErrorText(viewModel.state.errorMessage),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(width: selected ? 2 : 1, color: selected ? colors.primary : colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
