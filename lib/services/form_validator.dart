class FormValidator {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateGstin(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length != 15) return 'GSTIN must be 15 characters';
    return null;
  }

  static String? validatePan(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length != 10) return 'PAN must be 10 characters';
    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length != 6) return 'Pincode must be 6 digits';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Invalid email format';
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length != 10) return 'Mobile number must be 10 digits';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Must contain at least one special character';
    }
    return null;
  }
}
