/// A utility class for form field validations
class FormValidators {
  /// Validates that the [value] is not empty
  static String? required(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) {
      return errorText ?? 'This field is required';
    }
    return null;
  }

  /// Validates that the [value] is a valid email address
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

  /// Validates that the [value] meets a minimum length requirement
  static String? minLength(String? value, int minLength, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < minLength) {
      return errorText ?? 'Must be at least $minLength characters';
    }
    return null;
  }

  /// Validates that the [value] is a number
  static String? number(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) return null;
    
    if (double.tryParse(value) == null) {
      return errorText ?? 'Enter a valid number';
    }
    return null;
  }

  /// Validates that the [value] is a positive number
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
