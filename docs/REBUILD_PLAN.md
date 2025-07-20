# Invoice Lite - Rebuild Plan

## Project Goals
1. Modernize the codebase using latest Flutter and Dart features
2. Implement a clean architecture with clear separation of concerns
3. Use Riverpod 2.0 for state management
4. Use Drift for local database operations
5. Improve code organization and maintainability
6. Enhance performance and reliability
7. Add comprehensive testing

## Project Structure
```
lib/
├── core/
│   ├── database/       # Drift database setup and DAOs
│   ├── di/            # Dependency injection
│   ├── errors/        # Error handling
│   ├── router/        # App routing
│   ├── theme/         # App theming
│   └── utils/         # Utility functions and extensions
│
├── features/          # Feature modules
│   ├── items/         # Item management
│   ├── customers/     # Customer management
│   ├── invoices/      # Invoice management
│   └── reports/       # Reporting
│
├── shared/            # Shared widgets and models
│   ├── widgets/       # Reusable widgets
│   └── models/        # Shared data models
│
└── app.dart          # Main app configuration
```

## Technology Stack
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Riverpod 2.0
- **Local Database**: Drift
- **Dependency Injection**: Riverpod + get_it
- **UI**: Flutter Material 3
- **Testing**: flutter_test, mockito
- **Build Runner**: For code generation

## Implementation Plan

### Phase 1: Project Setup
- [ ] Initialize new Flutter project
- [ ] Set up project structure
- [ ] Configure build system and CI/CD
- [ ] Set up static analysis and code formatting
- [ ] Configure Drift database
- [ ] Set up Riverpod providers

### Phase 2: Core Features
- [ ] Implement base database models
- [ ] Create repository layer
- [ ] Set up dependency injection
- [ ] Implement authentication (if needed)
- [ ] Create base UI components

### Phase 3: Feature Implementation
- [ ] Items management
  - [ ] CRUD operations
  - [ ] Categories and units
  - [ ] Stock management
- [ ] Customer management
  - [ ] Customer profiles
  - [ ] Contact management
- [ ] Invoicing
  - [ ] Create/edit invoices
  - [ ] PDF generation
  - [ ] Email/SMS sending
- [ ] Reports
  - [ ] Sales reports
  - [ ] Inventory reports
  - [ ] Financial summaries

### Phase 4: Polish & Testing
- [ ] Unit tests
- [ ] Widget tests
- [ ] Integration tests
- [ ] Performance optimization
- [ ] UI/UX improvements

## Current Progress
- [x] Analyzed existing codebase
- [ ] Set up new project structure
- [ ] Implemented core database
- [ ] Set up state management
- [ ] Implemented features

## Notes
- Follow Flutter best practices
- Write clean, maintainable code
- Document complex logic
- Add meaningful comments
- Write tests for critical paths

## Dependencies to Add
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  hooks_riverpod: ^2.4.0
  
  # Database
  drift: ^2.13.0
  sqlite3_flutter_libs: ^0.5.15
  path_provider: ^2.1.1
  path: ^1.8.3
  
  # UI
  flutter_hooks: ^0.20.0
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.7
  
  # Utils
  intl: ^0.18.1
  uuid: ^4.2.2
  equatable: ^2.0.5
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.12.2
  build_runner: ^2.4.7
  mockito: ^5.4.2
  flutter_lints: ^3.0.1
```
