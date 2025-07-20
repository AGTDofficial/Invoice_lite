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
- [x] Items Management
  - [x] CRUD operations
  - [x] Unit of measurement support
  - [x] Stock level tracking
  - [ ] Categories and variants
  - [ ] Bulk import/export

- [x] Customer Management
  - [x] Customer profiles
  - [x] Contact information
  - [ ] Customer groups
  - [ ] Customer statements
  - [ ] Customer payment history

- [ ] Invoicing (In Progress)
  - [x] Basic invoice creation UI
  - [x] Item selection
  - [ ] Customer selection
  - [ ] Tax calculation
  - [ ] Discounts and adjustments
  - [ ] Invoice numbering
  - [ ] PDF generation
  - [ ] Payment tracking

- [ ] Reports
  - [ ] Sales reports
  - [ ] Inventory reports
  - [ ] Financial summaries
  - [ ] Tax reports
  - [ ] Customer statements
  - [ ] Export to Excel/CSV

- [ ] Settings
  - [ ] Company information
  - [ ] Tax configuration
  - [ ] Invoice templates
  - [ ] User preferences

### Phase 4: Polish & Testing
- [ ] Testing
  - [ ] Unit tests for business logic
  - [ ] Widget tests for UI components
  - [ ] Integration tests for critical flows
  - [ ] Performance testing
  - [ ] Test coverage reporting

- [ ] UI/UX Improvements
  - [ ] Responsive design for tablets
  - [ ] Dark/light theme support
  - [ ] Animations and transitions
  - [ ] Accessibility improvements
  - [ ] Localization support
  - [ ] Keyboard shortcuts

- [ ] Performance Optimization
  - [ ] Database query optimization
  - [ ] Image/asset optimization
  - [ ] Lazy loading for lists
  - [ ] Memory management
  - [ ] Startup time optimization

- [ ] Documentation
  - [ ] API documentation
  - [ ] User guides
  - [ ] Developer documentation
  - [ ] Setup instructions

## Current Progress
- [x] Analyzed existing codebase
- [x] Set up new project structure
- [x] Implemented core database with Drift
- [x] Set up Riverpod for state management
- [x] Implemented customer management features
  - [x] Customer list with search and filtering
  - [x] Add/Edit customer form with validation
  - [x] Delete customer with confirmation
- [x] Implemented item management features
  - [x] Item list with search and filtering
  - [x] Add/Edit item form with validation
  - [x] Stock level tracking
  - [x] Unit of measurement support
- [ ] Implemented invoice management features (In Progress)
  - [x] Basic invoice creation UI
  - [x] Item selection interface with search and filtering
  - [x] Customer selection with searchable dropdown
  - [x] Invoice items management
    - [x] Add/remove items
    - [x] Update quantities with validation
    - [x] Calculate line item totals
  - [x] Tax calculation
  - [x] Discount application
  - [ ] Invoice numbering system
  - [x] Save invoices with items to database
  - [ ] Print/PDF generation
- [ ] Implemented reporting features
  - [ ] Sales reports
  - [ ] Inventory reports
  - [ ] Financial summaries

## Next Priority Tasks
1. **Complete Invoice Management**
   - Implement customer selection in invoice creation
   - Add invoice items management (add/remove/update)
   - Implement tax and discount calculations
   - Add invoice numbering system
   - Implement PDF generation

2. **Enhance Existing Features**
   - Add barcode/QR code support for items
   - Implement bulk import/export for items and customers
   - Add customer groups and tags
   - Implement stock adjustment functionality

3. **Testing and Quality**
   - Add unit tests for business logic
   - Implement widget tests for critical UI components
   - Set up integration tests for main user flows
   - Add performance monitoring

## Notes
- Follow Flutter best practices and Material Design 3 guidelines
- Write clean, maintainable, and well-documented code
- Document complex logic and business rules
- Add meaningful comments and API documentation
- Write tests for critical paths and edge cases
- Follow accessibility best practices
- Optimize for both mobile and tablet layouts

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
