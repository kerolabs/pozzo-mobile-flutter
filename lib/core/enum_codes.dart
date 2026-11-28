/// The backend sends enumerations in UPPER_SNAKE_CASE ("PENDING_REVIEW") and Dart names them in
/// lowerCamelCase (pendingReview). These two functions translate between both.
extension EnumCode on Enum {
  /// pendingReview as "PENDING_REVIEW".
  String get code => name.replaceAllMapped(RegExp('[A-Z]'), (match) => '_${match[0]}').toUpperCase();
}

/// The value of [values] whose code is [code], or [fallback] when the backend sends one the app does not know.
T parseEnum<T extends Enum>(List<T> values, String? code, {T? fallback}) {
  for (final value in values) {
    if (value.code == code) return value;
  }
  if (fallback != null) return fallback;
  throw FormatException('Unknown value $code');
}
