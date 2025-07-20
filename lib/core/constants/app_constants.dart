/// A utility class that holds app-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'Invoice Lite';
  static const String appVersion = '1.0.0';
  
  // API and Backend
  static const String apiBaseUrl = 'https://api.invoicelite.example.com';
  static const int apiTimeoutSeconds = 30;
  
  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String themeModeKey = 'theme_mode';
  static const String localeKey = 'locale';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Date & Time Formats
  static const String dateFormat = 'MMM d, yyyy';
  static const String timeFormat = 'h:mm a';
  static const String dateTimeFormat = 'MMM d, yyyy h:mm a';
  
  // Currency
  static const String defaultCurrency = 'INR';
  static const String defaultCurrencySymbol = '₹';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int maxEmailLength = 100;
  static const int maxNameLength = 100;
  
  // File Sizes (in bytes)
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10MB
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Default Margins and Paddings
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  // Border Radius
  static const double smallRadius = 4.0;
  static const double mediumRadius = 8.0;
  static const double largeRadius = 12.0;
  static const double extraLargeRadius = 16.0;
  
  // Icons
  static const double defaultIconSize = 24.0;
  
  // Button Sizes
  static const double buttonHeight = 48.0;
  static const double smallButtonHeight = 36.0;
  static const double largeButtonHeight = 56.0;
  
  // Input Field Sizes
  static const double inputFieldHeight = 48.0;
  static const double textFieldMinLines = 1;
  static const int textFieldMaxLines = 5;
  
  // App Bar
  static const double appBarHeight = 56.0;
  
  // Bottom Navigation Bar
  static const double bottomNavBarHeight = 64.0;
  
  // Dialog Sizes
  static const double dialogWidth = 400.0;
  static const double dialogMaxWidth = 500.0;
  
  // Snackbar
  static const Duration snackBarDuration = Duration(seconds: 4);
  
  // Debounce Time
  static const Duration debounceTime = Duration(milliseconds: 500);
  
  // Throttle Time
  static const Duration throttleTime = Duration(milliseconds: 300);
  
  // Default Avatar
  static const String defaultAvatarUrl = 'https://ui-avatars.com/api/?name=User&background=4F46E5&color=fff';
  
  // Placeholder Image
  static const String placeholderImageUrl = 'https://via.placeholder.com/150';
  
  // Default Country
  static const String defaultCountry = 'IN';
  
  // Default Locale
  static const String defaultLocale = 'en';
  
  // Supported Locales
  static const List<String> supportedLocales = ['en', 'hi'];
  
  // Default Theme Mode
  static const String defaultThemeMode = 'system';
  
  // App Links
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';
  static const String supportEmail = 'support@invoicelite.example.com';
  
  // Social Media
  static const String twitterUrl = 'https://twitter.com/invoicelite';
  static const String facebookUrl = 'https://facebook.com/invoicelite';
  static const String instagramUrl = 'https://instagram.com/invoicelite';
  static const String linkedinUrl = 'https://linkedin.com/company/invoicelite';
  
  // App Store Links
  static const String appStoreUrl = 'https://apps.apple.com/app/invoice-lite/id1234567890';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.invoicelite.app';
  
  // In-App Purchase IDs
  static const String monthlySubscriptionId = 'com.invoicelite.subscription.monthly';
  static const String yearlySubscriptionId = 'com.invoicelite.subscription.yearly';
  
  // Feature Flags
  static const bool isSubscriptionEnabled = false;
  static const bool isMultiCurrencyEnabled = false;
  static const bool isOfflineModeEnabled = true;
  
  // Debug Settings
  static const bool enableLogging = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
}
