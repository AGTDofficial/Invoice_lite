/// A utility class for form field validations
class FormValidators {
  // Required field validation
  static String? required(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) {
      return errorText ?? 'This field is required';
    }
    return null;
  }

  // Email validation
  static String? email(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return errorText ?? 'Enter a valid email address';
    }
    return null;
  }

  // Minimum length validation
  static String? minLength(String? value, int minLength, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    if (value.length < minLength) {
      return errorText ?? 'Must be at least $minLength characters';
    }
    return null;
  }

  // Maximum length validation
  static String? maxLength(String? value, int maxLength, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    if (value.length > maxLength) {
      return errorText ?? 'Maximum $maxLength characters allowed';
    }
    return null;
  }

  // Number validation
  static String? number(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) {
      return errorText ?? 'Enter a valid number';
    }
    return null;
  }

  // Positive number validation
  static String? positiveNumber(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    final number = double.tryParse(value);
    if (number == null) {
      return errorText ?? 'Enter a valid number';
    }
    
    if (number <= 0) {
      return errorText ?? 'Must be greater than zero';
    }
    return null;
  }

  // Phone number validation (basic)
  static String? phoneNumber(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
    if (!phoneRegex.hasMatch(value)) {
      return errorText ?? 'Enter a valid phone number';
    }
    return null;
  }

  // URL validation
  static String? url(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    final urlRegex = RegExp(
      r'^(https?:\/\/)?' // protocol
      r'((([a-z\d]([a-z\d-]*[a-z\d])*)\.)+[a-z]{2,}|' // domain name
      r'((\d{1,3}\.){3}\d{1,3}))' // OR ip (v4) address
      r'(\:\d+)?(\/[-a-z\d%_.~+]*)*' // port and path
      r'(\?[;&a-z\d%_.~+=-]*)?' // query string
      r'(\#[-a-z\d_]*)?\$', // fragment locator
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value)) {
      return errorText ?? 'Enter a valid URL';
    }
    return null;
  }

  // Alphanumeric validation
  static String? alphanumeric(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumericRegex.hasMatch(value)) {
      return errorText ?? 'Only alphanumeric characters are allowed';
    }
    return null;
  }

  // Compose multiple validators
  static String? compose(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) return error;
    }
    return null;
  }

  /// Combines multiple validators into a single validator function
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
