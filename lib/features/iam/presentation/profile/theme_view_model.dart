import 'package:pozzo/core/network/api_exception.dart';
import 'package:pozzo/core/view_model.dart';
import 'package:pozzo/features/iam/application/auth_use_cases.dart';
import 'package:pozzo/features/iam/domain/profile.dart';

class ThemeState {
  const ThemeState({required this.theme, this.errorMessage});

  final ThemePreference theme;
  final String? errorMessage;
}

/// I2: the visual theme. The app repaints at once because the session keeps the chosen theme.
class ThemeViewModel extends ViewModel<ThemeState> {
  ThemeViewModel({required this.updateTheme, required ThemePreference current}) : super(ThemeState(theme: current));

  final UpdateThemeUseCase updateTheme;

  Future<void> choose(ThemePreference theme) async {
    final previous = state.theme;
    emit(ThemeState(theme: theme));
    try {
      await updateTheme.execute(theme);
    } catch (error) {
      emit(ThemeState(theme: previous, errorMessage: userMessageOf(error)));
    }
  }
}
