import 'package:flutter_test/flutter_test.dart';
import 'package:janus_sdk_flutter/consent_method.dart';

void main() {
  group('ConsentMethod', () {
    test('enum values have correct string representations', () {
      expect(ConsentMethod.save.value, 'save');
      expect(ConsentMethod.accept.value, 'accept');
      expect(ConsentMethod.reject.value, 'reject');
      expect(ConsentMethod.acknowledge.value, 'acknowledge');
      expect(ConsentMethod.dismiss.value, 'dismiss');
      expect(ConsentMethod.fidesJsUpdate.value, 'fides_js_update');
      expect(ConsentMethod.unknown.value, 'unknown');
      expect(ConsentMethod.error.value, 'error');
      expect(ConsentMethod.attDenied.value, 'att_denied');
    });

    test('toString returns the value', () {
      expect(ConsentMethod.save.toString(), 'save');
      expect(ConsentMethod.fidesJsUpdate.toString(), 'fides_js_update');
      expect(ConsentMethod.unknown.toString(), 'unknown');
    });

    test('fromString creates correct enum values', () {
      expect(ConsentMethod.fromString('save'), ConsentMethod.save);
      expect(ConsentMethod.fromString('accept'), ConsentMethod.accept);
      expect(ConsentMethod.fromString('reject'), ConsentMethod.reject);
      expect(ConsentMethod.fromString('acknowledge'), ConsentMethod.acknowledge);
      expect(ConsentMethod.fromString('dismiss'), ConsentMethod.dismiss);
      expect(ConsentMethod.fromString('fides_js_update'), ConsentMethod.fidesJsUpdate);
      expect(ConsentMethod.fromString('unknown'), ConsentMethod.unknown);
      expect(ConsentMethod.fromString('error'), ConsentMethod.error);
      expect(ConsentMethod.fromString('att_denied'), ConsentMethod.attDenied);
    });

    test('fromString defaults to unknown for null or invalid input', () {
      expect(ConsentMethod.fromString(null), ConsentMethod.unknown);
      expect(ConsentMethod.fromString('invalid'), ConsentMethod.unknown);
      expect(ConsentMethod.fromString(''), ConsentMethod.unknown);
      expect(ConsentMethod.fromString('SAVE'), ConsentMethod.unknown);
    });

    test('fidesJsUpdate serialises to fides_js_update', () {
      expect(ConsentMethod.fidesJsUpdate.value, 'fides_js_update');
      expect(ConsentMethod.fromString('fides_js_update'), ConsentMethod.fidesJsUpdate);
    });

    test('enum comparison works correctly', () {
      expect(ConsentMethod.save == ConsentMethod.save, true);
      expect(ConsentMethod.save == ConsentMethod.accept, false);
      expect(ConsentMethod.fidesJsUpdate == ConsentMethod.fidesJsUpdate, true);
    });
  });
}
