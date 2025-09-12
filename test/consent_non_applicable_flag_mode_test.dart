import 'package:flutter_test/flutter_test.dart';
import 'package:janus_sdk_flutter/consent_non_applicable_flag_mode.dart';

void main() {
  group('ConsentNonApplicableFlagMode', () {
    test('should have correct string values', () {
      expect(ConsentNonApplicableFlagMode.omit.value, 'omit');
      expect(ConsentNonApplicableFlagMode.include.value, 'include');
    });

    test('toString should return the string value', () {
      expect(ConsentNonApplicableFlagMode.omit.toString(), 'omit');
      expect(ConsentNonApplicableFlagMode.include.toString(), 'include');
    });

    group('fromString', () {
      test('should parse valid lowercase values', () {
        expect(
          ConsentNonApplicableFlagMode.fromString('omit'),
          ConsentNonApplicableFlagMode.omit,
        );
        expect(
          ConsentNonApplicableFlagMode.fromString('include'),
          ConsentNonApplicableFlagMode.include,
        );
      });

      test('should parse valid uppercase values', () {
        expect(
          ConsentNonApplicableFlagMode.fromString('OMIT'),
          ConsentNonApplicableFlagMode.omit,
        );
        expect(
          ConsentNonApplicableFlagMode.fromString('INCLUDE'),
          ConsentNonApplicableFlagMode.include,
        );
      });

      test('should parse valid mixed case values', () {
        expect(
          ConsentNonApplicableFlagMode.fromString('Omit'),
          ConsentNonApplicableFlagMode.omit,
        );
        expect(
          ConsentNonApplicableFlagMode.fromString('Include'),
          ConsentNonApplicableFlagMode.include,
        );
      });

      test('should default to omit for invalid values', () {
        expect(
          ConsentNonApplicableFlagMode.fromString('invalid'),
          ConsentNonApplicableFlagMode.omit,
        );
        expect(
          ConsentNonApplicableFlagMode.fromString(''),
          ConsentNonApplicableFlagMode.omit,
        );
        expect(
          ConsentNonApplicableFlagMode.fromString('null'),
          ConsentNonApplicableFlagMode.omit,
        );
      });
    });
  });
}
