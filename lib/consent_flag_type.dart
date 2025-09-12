/// Enum representing different types of consent flags that can be used
/// to determine the format of consent values returned by external interfaces.
enum ConsentFlagType {
  /// Consent values are represented as boolean (true/false)
  boolean('boolean'),

  /// Consent values are represented as consent mechanism strings
  consentMechanism('consentMechanism');

  const ConsentFlagType(this.value);

  /// The string value of the consent flag type
  final String value;

  /// Create a ConsentFlagType from a string value
  static ConsentFlagType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'boolean':
        return ConsentFlagType.boolean;
      case 'consentmechanism':
        return ConsentFlagType.consentMechanism;
      default:
        return ConsentFlagType.boolean; // Default fallback
    }
  }

  @override
  String toString() => value;
}
