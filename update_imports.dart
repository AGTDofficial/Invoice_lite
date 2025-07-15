import 'dart:io';

void main() {
  final files = [
    'lib/main.dart',
    'lib/screens/company_create_screen.dart',
    'lib/providers/company_provider.dart',
    'lib/utils/company_context.dart',
    'lib/services/company_service.dart',
    'lib/screens/company_selector_screen.dart',
    'lib/screens/company_screen.dart',
    'lib/screens/company_form_screen_updated.dart',
    'lib/screens/company_form_screen.dart',
  ];

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    content = content.replaceAll(
      "import '../models/company_updated.dart';",
      "import '../models/company.dart';",
    );
    content = content.replaceAll(
      "import 'models/company_updated.dart';",
      "import 'models/company.dart';",
    );
    
    file.writeAsStringSync(content);
    print('Updated imports in $filePath');
  }
  
  // Update the part directive in company_updated.g.dart
  final generatedFile = File('lib/models/company_updated.g.dart');
  if (generatedFile.existsSync()) {
    var content = generatedFile.readAsStringSync();
    content = content.replaceAll(
      "part of 'company_updated.dart';",
      "part of 'company.dart';",
    );
    generatedFile.writeAsStringSync(content);
    print('Updated part directive in company_updated.g.dart');
  }
  
  print('\nAll imports updated successfully!');
}
