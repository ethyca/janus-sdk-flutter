/// Enum representing how non-applicable privacy notices are handled in consent objects.
/// This mirrors the ConsentNonApplicableFlagMode enum from FidesJS and native SDKs.
enum ConsentNonApplicableFlagMode {
  /// Non-applicable notices are omitted from the consent object (default)
  omit('omit'),

  /// Non-applicable notices are included in the consent object with appropriate values
  include('include');

  const ConsentNonApplicableFlagMode(this.value);

  /// The string value of the consent non-applicable flag mode
  final String value;

  /// Create a ConsentNonApplicableFlagMode from a string value
  /// Returns [omit] as the default if the value is not recognized
  static ConsentNonApplicableFlagMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'omit':
        return ConsentNonApplicableFlagMode.omit;
      case 'include':
        return ConsentNonApplicableFlagMode.include;
      default:
        return ConsentNonApplicableFlagMode.omit; // Default fallback
    }
  }

  @override
  String toString() => value;
}
