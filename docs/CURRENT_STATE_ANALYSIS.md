# Invoice Lite - Current State Analysis

## Application Overview
Invoice Lite is a Flutter-based invoicing application designed to help small businesses manage their inventory, customers, and financial transactions. The app provides features for creating and managing items, generating invoices, tracking stock movements, and managing customer accounts.

## Key Features

### 1. Item Management
- Create, edit, and delete inventory items
- Track item details (name, code, description, rates)
- Stock level tracking with minimum stock alerts
- Categorization using item groups
- Support for different units of measurement

### 2. Customer Management
- Customer and supplier management
- Contact information and account details
- Transaction history

### 3. Invoicing
- Create sales and purchase invoices
- Multiple items per invoice
- Calculate totals and taxes
- Print/save invoices as PDF

### 4. Stock Management
- Track stock movements (in/out)
- Opening stock management
- Stock level monitoring

## Technical Implementation

### State Management
- Uses `flutter_riverpod` for state management
- Implements `StateNotifier` pattern for complex state
- Freezed for immutable state and union types

### Data Storage
- **Hive**: Primary NoSQL database for local storage
  - Used for storing items, customers, invoices, etc.
  - Type-safe boxes for different data models
- **Drift**: SQLite-based local database (partially implemented)
  - Intended for more complex queries and relationships

### Architecture
- Feature-based folder structure
- Separation of concerns with clear layers:
  - Data (repositories, models)
  - Domain (business logic, state management)
  - Presentation (UI components, screens)

### Dependencies
- **State Management**: flutter_riverpod, hooks_riverpod
- **UI**: flutter_hooks, dropdown_search, flutter_typeahead
- **Data**: hive, drift, path_provider
- **PDF Generation**: pdf, share_plus
- **Utilities**: intl, uuid, equatable

## UI/UX
- Material Design 3 theming
- Responsive layout
- Form validation
- Loading and error states
- Confirmation dialogs for destructive actions

## Current Limitations
1. Mixed usage of Hive and Drift causing complexity
2. Some state management could be more streamlined
3. Inconsistent error handling
4. Limited offline capabilities
5. Basic reporting features

## Planned Improvements
1. Full migration to Drift for better data relationships
2. Enhanced state management with Riverpod 2.0
3. Improved offline support
4. Advanced reporting and analytics
5. Better test coverage
6. Enhanced PDF generation
7. Multi-currency support
8. User roles and permissions

## Next Steps
1. Set up new project structure
2. Implement core database with Drift
3. Rebuild features with improved architecture
4. Add comprehensive testing
5. Implement new features from the planned improvements list
