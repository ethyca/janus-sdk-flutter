/// Enum representing the different methods by which consent can be collected.
/// Mirrors ConsentMethod on iOS and Android.
enum ConsentMethod {
  /// User clicked save button or explicitly saved preferences
  save('save'),

  /// User clicked accept/opt-in button
  accept('accept'),

  /// User clicked reject/opt-out button
  reject('reject'),

  /// User acknowledged a notice (typically for informational notices)
  acknowledge('acknowledge'),

  /// User dismissed the privacy experience without making explicit choices
  dismiss('dismiss'),

  /// Consent was set programmatically by FidesJS (e.g. from a FidesUpdated web event)
  fidesJsUpdate('fides_js_update'),

  /// Default/fallback value when method is not specified or not known
  unknown('unknown'),

  /// Error state when consent method could not be determined
  error('error'),

  /// Consent was pre-populated to opt-out because Apple ATT permission was denied
  attDenied('att_denied');

  const ConsentMethod(this.value);

  /// The string value sent across the method channel bridge
  final String value;

  /// Create a ConsentMethod from a string value, defaulting to [unknown] if not found
  static ConsentMethod fromString(String? value) {
    if (value == null) return ConsentMethod.unknown;
    return ConsentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ConsentMethod.unknown,
    );
  }

  @override
  String toString() => value;
}
