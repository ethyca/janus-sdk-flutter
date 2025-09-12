import 'package:flutter_test/flutter_test.dart';
import 'package:janus_sdk_flutter/consent_flag_type.dart';

void main() {
  group('ConsentFlagType', () {
    test('enum values have correct string representations', () {
      expect(ConsentFlagType.boolean.value, 'boolean');
      expect(ConsentFlagType.consentMechanism.value, 'consentMechanism');
    });

    test('toString returns the value', () {
      expect(ConsentFlagType.boolean.toString(), 'boolean');
      expect(ConsentFlagType.consentMechanism.toString(), 'consentMechanism');
    });

    test('fromString creates correct enum values', () {
      expect(ConsentFlagType.fromString('boolean'), ConsentFlagType.boolean);
      expect(
        ConsentFlagType.fromString('consentMechanism'),
        ConsentFlagType.consentMechanism,
      );
    });

    test('fromString is case insensitive', () {
      expect(ConsentFlagType.fromString('BOOLEAN'), ConsentFlagType.boolean);
      expect(ConsentFlagType.fromString('Boolean'), ConsentFlagType.boolean);
      expect(
        ConsentFlagType.fromString('CONSENTMECHANISM'),
        ConsentFlagType.consentMechanism,
      );
      expect(
        ConsentFlagType.fromString('ConsentMechanism'),
        ConsentFlagType.consentMechanism,
      );
    });

    test('fromString defaults to boolean for invalid input', () {
      expect(ConsentFlagType.fromString('invalid'), ConsentFlagType.boolean);
      expect(ConsentFlagType.fromString(''), ConsentFlagType.boolean);
      expect(ConsentFlagType.fromString('null'), ConsentFlagType.boolean);
      expect(ConsentFlagType.fromString('undefined'), ConsentFlagType.boolean);
    });

    test('enum comparison works correctly', () {
      expect(ConsentFlagType.boolean == ConsentFlagType.boolean, true);
      expect(
        ConsentFlagType.boolean == ConsentFlagType.consentMechanism,
        false,
      );
      expect(
        ConsentFlagType.consentMechanism == ConsentFlagType.consentMechanism,
        true,
      );
    });
  });
}
