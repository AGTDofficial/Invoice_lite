import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:url_launcher/url_launcher.dart';

/// A utility class for phone number related operations
class PhoneUtils {
  /// Validates a phone number
  static bool isValidPhoneNumber(String phoneNumber, {String? countryCode}) {
    try {
      final phone = PhoneNumber.parse(phoneNumber);
      return phone.validate();
    } catch (e) {
      return false;
    }
  }

  /// Formats a phone number for display
  static String formatPhoneNumber(String phoneNumber, {String? countryCode}) {
    try {
      final phone = PhoneNumber.parse(phoneNumber);
      return phone.international;
    } catch (e) {
      return phoneNumber; // Return original if parsing fails
    }
  }

  /// Extracts the country code from a phone number
  static String? extractCountryCode(String phoneNumber) {
    try {
      final phone = PhoneNumber.parse(phoneNumber);
      return phone.countryCode;
    } catch (e) {
      return null;
    }
  }

  /// Launches the phone's default dialer with the given phone number
  static Future<bool> launchPhoneDialer(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      return await launchUrl(Uri.parse(url));
    }
    return false;
  }

  /// Launches WhatsApp with a pre-filled message
  static Future<bool> launchWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    // Remove any non-digit characters from the phone number
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Format the message for URL encoding
    final encodedMessage = message != null ? '?text=${Uri.encodeComponent(message)}' : '';
    
    // Try both URL formats (with and without +)
    final urls = [
      'whatsapp://send?phone=$cleanNumber$encodedMessage',
      'https://wa.me/$cleanNumber$encodedMessage',
    ];

    for (final url in urls) {
      if (await canLaunchUrl(Uri.parse(url))) {
        return await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    }
    
    return false;
  }

  /// Gets the country code for the current locale
  static String getDefaultCountryCode() {
    // Default to India (IN) as the country code
    return 'IN';
  }

  /// Validates if a string contains only digits and allowed special characters
  static bool isNumeric(String value) {
    return RegExp(r'^[0-9+\-()\s]+$').hasMatch(value);
  }

  /// Normalizes a phone number by removing all non-digit characters except +
  static String normalizePhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    final normalized = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // If the number starts with a country code but no +, add it
    if (normalized.startsWith('91') && !normalized.startsWith('+')) {
      return '+$normalized';
    }
    
    return normalized;
  }
}
