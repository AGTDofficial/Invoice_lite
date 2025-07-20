import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

void main(List<String> args) async {
  print('📦 Dependency Updater');
  print('===================');
  
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('❌ Error: pubspec.yaml not found');
    return;
  }

  final pubspecContent = await pubspecFile.readAsString();
  final pubspecYaml = loadYaml(pubspecContent) as YamlMap;
  
  // Define target versions (1-2 years old, well-tested)
  final targetVersions = {
    // Core Flutter
    'sdk': '>=3.3.0 <4.0.0',
    
    // State Management
    'provider': '^6.1.1',  // Latest stable
    'flutter_riverpod': '^2.4.9',  // Latest stable
    'hooks_riverpod': '^2.4.9',  // Latest stable
    
    // UI Components
    'dropdown_search': '^6.0.2',  // Latest stable
    'flutter_typeahead': '^5.1.0',  // Latest stable
    'flutter_hooks': '^0.20.5',  // Latest stable before 0.21.x
    'flutter_slidable': '^3.1.2',  // Latest stable before 4.0.0
    
    // Form Handling
    'email_validator': '^3.0.0',  // Latest stable
    'form_validator': '^2.1.1',  // Latest stable
    'phone_number': '^2.1.0',  // Latest stable
    
    // Data Storage
    'hive': '^2.2.3',  // Latest stable 2.x
    'hive_flutter': '^1.1.0',  // Latest stable
    'path_provider': '^2.1.1',  // Latest stable
    
    // Models & Serialization
    'freezed_annotation': '^2.4.1',  // Latest stable 2.x
    'json_annotation': '^4.8.1',  // Latest stable
    'equatable': '^2.0.5',  // Latest stable
    
    // Dependency Injection
    'injectable': '^2.1.5',  // Latest stable
    'get_it': '^7.7.0',  // Latest stable
    
    // PDF & Sharing
    'share_plus': '^7.2.2',  // Latest before 8.0.0
    'pdf': '^3.10.4',  // Latest stable
    'printing': '^5.11.1',  // Latest stable
    
    // Utilities
    'collection': '^1.18.0',  // Latest stable
    'intl': '^0.18.1',  // Latest stable before 1.0.0
    'uuid': '^4.5.1',  // Latest stable
  };

  // Get current dependencies
  final dependencies = pubspecYaml['dependencies'] as YamlMap? ?? YamlMap();
  final devDependencies = pubspecYaml['dev_dependencies'] as YamlMap? ?? YamlMap();
  
  bool hasChanges = false;
  final yamlEditor = YamlEditor(pubspecContent);
  
  // Update dependencies
  print('\n🔍 Checking dependencies...');
  for (final entry in targetVersions.entries) {
    final package = entry.key;
    final targetVersion = entry.value;
    
    if (dependencies[package] != null) {
      final currentVersion = _getVersionString(dependencies[package]);
      if (currentVersion != targetVersion) {
        print('🔄 Updating $package: $currentVersion → $targetVersion');
        yamlEditor.update(
          ['dependencies', package],
          targetVersion,
          // Preserve the style (quoted or not)
          removeNodeIfEmpty: false,
        );
        hasChanges = true;
      }
    }
  }
  
  // Check for deprecated or problematic packages
  _checkForProblematicPackages(dependencies, devDependencies);
  
  if (hasChanges) {
    // Backup the original file
    final backupFile = File('pubspec.yaml.bak');
    await backupFile.writeAsString(pubspecContent);
    
    // Write the updated file
    await pubspecFile.writeAsString(yamlEditor.toString());
    
    print('\n✅ Updated pubspec.yaml');
    print('   Original saved as pubspec.yaml.bak');
    
    // Run pub get to update dependencies
    print('\n🔄 Running `flutter pub get`...');
    final process = await Process.start('flutter', ['pub', 'get']);
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);
    
    final exitCode = await process.exitCode;
    if (exitCode == 0) {
      print('\n✅ Dependencies updated successfully!');
      print('   Run `flutter pub outdated` to verify the updates.');
    } else {
      print('\n❌ Failed to update dependencies. Check the output above for errors.');
    }
  } else {
    print('\n✅ All dependencies are up to date with target versions!');
  }
}

String _getVersionString(dynamic version) {
  if (version is String) {
    return version;
  } else if (version is YamlMap) {
    return version['version']?.toString() ?? 'unknown';
  }
  return 'unknown';
}

void _checkForProblematicPackages(YamlMap dependencies, YamlMap devDependencies) {
  print('\n🔍 Checking for potentially problematic packages...');
  
  final allDeps = <String, dynamic>{};
  allDeps.addAll(dependencies);
  allDeps.addAll(devDependencies);
  
  final problematicPackages = {
    'http': 'Consider using dio or http_client for more features',
    'shared_preferences': 'Consider using hive or sqlite for more robust storage',
    'sqflite': 'Consider using drift (moor) for type-safe SQL',
    'connectivity': 'Use connectivity_plus instead',
    'url_launcher': 'Use url_launcher_plus for more features',
  };
  
  bool foundIssues = false;
  
  for (final package in allDeps.keys) {
    if (problematicPackages.containsKey(package)) {
      print('⚠️  Found ${package}: ${problematicPackages[package]}');
      foundIssues = true;
    }
  }
  
  if (!foundIssues) {
    print('✅ No known problematic packages found');
  }
}
