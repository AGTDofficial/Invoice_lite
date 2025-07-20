import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as path;

void main() async {
  final projectRoot = Directory.current.path;
  final libDir = Directory(path.join(projectRoot, 'lib'));
  
  print('🔍 Analyzing codebase...\n');
  
  // 1. Verify model files exist
  await _verifyModelFiles();
  
  // 2. Analyze Hive type adapters
  await _analyzeHiveTypes(libDir);
  
  // 3. Check for deprecated APIs
  await _checkForDeprecatedCode(libDir);
  
  print('✅ Codebase analysis complete!');
}

Future<void> _verifyModelFiles() async {
  print('📋 Verifying model files...');
  
  final expectedModelFiles = [
    'lib/models/account.dart',
    'lib/models/invoice_item.dart',
    'lib/models/invoice.dart',
    'lib/models/invoice_state.dart',
    'lib/models/account_state.dart',
  ];
  
  bool allFilesExist = true;
  
  for (final filePath in expectedModelFiles) {
    final file = File(filePath);
    if (!await file.exists()) {
      print('❌ Missing file: $filePath');
      allFilesExist = false;
    }
  }
  
  if (allFilesExist) {
    print('✅ All model files exist');
  }
}

Future<void> _analyzeHiveTypes(Directory libDir) async {
  print('\n🔍 Analyzing Hive type adapters...');
  
  final collection = AnalysisContextCollection(includedPaths: [libDir.path]);
  final hiveTypeIds = <int, String>{};
  
  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final context = collection.contextFor(entity.path);
      final result = await context.currentSession.getResolvedUnit(entity.path);
      
      if (result is ResolvedUnitResult) {
        final visitor = _HiveTypeVisitor();
        result.unit.visitChildren(visitor);
        
        for (final type in visitor.hiveTypes) {
          if (hiveTypeIds.containsKey(type.typeId)) {
            print('❌ Duplicate Hive TypeId ${type.typeId}:');
            print('   - ${type.className} in ${entity.path}');
            print('   - ${hiveTypeIds[type.typeId]}');
          } else {
            hiveTypeIds[type.typeId] = '${type.className} in ${entity.path}';
          }
        }
      }
    }
  }
  
  print('\n📊 Hive TypeId Usage:');
  final sortedIds = hiveTypeIds.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in sortedIds) {
    print('  TypeId ${entry.key}: ${entry.value}');
  }
}

Future<void> _checkForDeprecatedCode(Directory libDir) async {
  print('\n⚠️  Checking for deprecated APIs...');
  
  final deprecatedApis = <String, List<String>>{};
  
  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      
      // Check for common deprecated patterns
      if (content.contains('@deprecated')) {
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].contains('@deprecated')) {
            final api = lines.length > i + 1 ? lines[i + 1].trim() : 'Unknown';
            deprecatedApis.putIfAbsent(entity.path, () => []).add(api);
          }
        }
      }
    }
  }
  
  if (deprecatedApis.isEmpty) {
    print('✅ No deprecated APIs found');
  } else {
    print('Found deprecated APIs:');
    deprecatedApis.forEach((file, apis) {
      print('\n📄 $file');
      apis.forEach((api) => print('  - $api'));
    });
  }
}

class _HiveTypeVisitor extends GeneralizingAstVisitor<void> {
  final List<_HiveTypeInfo> hiveTypes = [];
  
  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final typeId = _extractTypeId(node);
    if (typeId != null) {
      hiveTypes.add(_HiveTypeInfo(
        className: node.name.lexeme,
        typeId: typeId,
        filePath: node.declaredElement?.source.fullName ?? 'unknown',
      ));
    }
    
    super.visitClassDeclaration(node);
  }
  
  int? _extractTypeId(ClassDeclaration node) {
    for (final annotation in node.metadata) {
      final annotationCode = annotation.toString();
      if (annotationCode.contains('HiveType') && 
          annotationCode.contains('typeId:')) {
        final match = RegExp(r'typeId:\s*(\d+)').firstMatch(annotationCode);
        if (match != null) {
          return int.parse(match.group(1)!);
        }
      }
    }
    return null;
  }
}

class _HiveTypeInfo {
  final String className;
  final int typeId;
  final String filePath;
  
  _HiveTypeInfo({
    required this.className,
    required this.typeId,
    required this.filePath,
  });
}
