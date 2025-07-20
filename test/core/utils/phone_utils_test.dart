import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_lite/core/utils/phone_utils.dart';

void main() {
  group('PhoneUtils Tests', () {
    test('isValidPhoneNumber - Valid Indian number', () {
      expect(PhoneUtils.isValidPhoneNumber('+919876543210'), isTrue);
      expect(PhoneUtils.isValidPhoneNumber('+918123456789'), isTrue);
    });

    test('isValidPhoneNumber - Invalid numbers', () {
      expect(PhoneUtils.isValidPhoneNumber('12345'), isFalse);
      expect(PhoneUtils.isValidPhoneNumber('abcdefghij'), isFalse);
      expect(PhoneUtils.isValidPhoneNumber('+91987654321012345'), isFalse);
    });

    test('formatPhoneNumber - Formatting', () {
      expect(PhoneUtils.formatPhoneNumber('+919876543210'), '+91 98765 43210');
      expect(PhoneUtils.formatPhoneNumber('+15551234567'), '+1 555 123 4567');
    });

    test('extractCountryCode - Extraction', () {
      expect(PhoneUtils.extractCountryCode('+919876543210'), 'IN');
      expect(PhoneUtils.extractCountryCode('+15551234567'), 'US');
      expect(PhoneUtils.extractCountryCode('12345'), isNull);
    });

    test('normalizePhoneNumber - Normalization', () {
      expect(PhoneUtils.normalizePhoneNumber('+91 (987) 654-3210'), '+919876543210');
      expect(PhoneUtils.normalizePhoneNumber('98765 43210'), '9876543210');
      expect(PhoneUtils.normalizePhoneNumber('+1 (555) 123-4567'), '+15551234567');
    });

    test('isNumeric - Validation', () {
      expect(PhoneUtils.isNumeric('+91 98765 43210'), isTrue);
      expect(PhoneUtils.isNumeric('(555) 123-4567'), isTrue);
      expect(PhoneUtils.isNumeric('abc123'), isFalse);
      expect(PhoneUtils.isNumeric('123-456-7890'), isTrue);
    });
  });
}
