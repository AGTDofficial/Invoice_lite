# Project Dependencies

This document tracks all project dependencies, their versions, and upgrade paths.

## Current Dependencies (as of 2023)

### Core Flutter
- Flutter SDK: `>=2.18.0 <4.0.0`
- Dart SDK: `>=2.18.0 <4.0.0`

### State Management
- `provider: ^6.1.1` - State management
- `flutter_riverpod: ^2.4.9` - State management with Riverpod
- `hooks_riverpod: ^2.4.9` - Riverpod with Flutter Hooks

### UI Components
- `dropdown_search: ^5.0.6` - Enhanced dropdown with search
- `flutter_typeahead: ^5.1.0` - Typeahead/autocomplete
- `flutter_hooks: ^0.20.0` - React hooks for Flutter
- `flutter_slidable: ^3.0.1` - Slidable list items

### Form Handling & Validation
- `email_validator: ^2.1.17` - Email validation
- `form_validator: ^2.1.1` - Form validation utilities
- `phone_number: ^2.1.0` - Phone number parsing and validation

### Data Storage
- `hive: ^2.2.3` - Lightweight and fast NoSQL database
- `hive_flutter: ^1.1.0` - Flutter integration for Hive
- `path_provider: ^2.1.1` - Filesystem path utilities

### Model & Serialization
- `freezed_annotation: ^2.4.1` - Immutable models
- `json_annotation: ^4.8.1` - JSON serialization
- `equatable: ^2.0.5` - Value equality

### Dependency Injection
- `injectable: ^2.1.5` - Code generation for get_it
- `get_it: ^7.6.7` - Service locator

### PDF Generation & Sharing
- `share_plus: ^7.2.1` - Share content
- `pdf: ^3.10.4` - PDF generation
- `printing: ^5.11.1` - Print PDFs

### Utilities
- `collection: ^1.18.0` - Collection utilities
- `intl: ^0.18.1` - Internationalization
- `uuid: ^4.5.1` - UUID generation

### Hardware Integration
- `blue_thermal_printer: ^1.1.5` - Bluetooth thermal printing

## Dev Dependencies
- `build_runner: ^2.4.7` - Code generation
- `hive_generator: ^2.0.1` - Hive model generation
- `freezed: ^2.4.5` - Code generation for Freezed
- `json_serializable: ^6.7.1` - JSON serialization
- `injectable_generator: ^2.3.2` - Code generation for get_it
- `analyzer: ^6.3.0` - Static analysis
- `lint: ^2.1.1` - Linting rules

## Version Compatibility Notes
- All packages are compatible with Flutter 3.x
- Hive 2.x is used instead of 3.x for better stability
- Riverpod 2.x is used for state management
- Freezed is used for immutable models with value equality

## Known Issues
- Some packages might need null-safety migration
- Blue Thermal Printer might need platform-specific configuration
- Hive requires proper initialization before use
