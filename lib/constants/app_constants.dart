class AppConstants {
  // Standard GST Rates
  static const List<String> gstRates = ['0%', '5%', '12%', '18%', '28%', 'Item Wise', 'Exempt', 'Tax Incl.'];
  
  // GST Rate to double mapping for calculations
  static const Map<String, double> gstRateMap = {
    '0%': 0.0,
    '5%': 5.0,
    '12%': 12.0,
    '18%': 18.0,
    '28%': 28.0,
    'Item Wise': 0.0,  // Will be set per item
    'Exempt': 0.0,     // 0% GST
    'Tax Incl.': 0.0,  // GST already included in price
  };
  
  static const List<String> units = ['PCS', 'KG', 'L', 'BAG', 'BOX', 'MTR'];
  
  // Tax types for UI
  static const List<String> taxTypes = ['GST', 'IGST', 'Exempt', 'Tax Incl.'];
}