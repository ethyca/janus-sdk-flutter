/// The user's age bracket. Mirrors AgeBracket on iOS and Android.
enum AgeBracket {
  under13('under13'),
  age13To15('age13To15'),
  age16To17('age16To17'),
  adult('adult'),
  unknown('unknown');

  const AgeBracket(this.value);

  /// The string value sent across the method channel bridge
  final String value;

  @override
  String toString() => value;
}
