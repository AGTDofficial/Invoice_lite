# Modern Flutter & Dart Guidelines

This document outlines the modern practices and patterns used in this Flutter project.

## State Management
- **Riverpod** is the recommended state management solution (replacing Provider)
- Use `StateNotifier` with `StateNotifierProvider` for complex state
- Use `ChangeNotifier` only when necessary for simple local state
- Prefer `ConsumerWidget` or `HookConsumerWidget` over StatefulWidget

## Null Safety
- Always use sound null safety
- Use the `?` and `!` operators appropriately
- Use late initialization with `late` when a non-nullable variable will be initialized before use

## UI Components
- Use `Material 3` theming
- Prefer `const` constructors for widgets when possible
- Use `ListView.builder` for long lists instead of `Column` with multiple children
- Use `Expanded` and `Flexible` for responsive layouts

## Async Programming
- Use `async`/`await` with `FutureBuilder` or `StreamBuilder`
- Handle errors with `try`/`catch` and display user-friendly messages
- Use `mounted` checks after async operations in StatefulWidgets

## Code Organization
- Follow the feature-first folder structure
- Separate business logic from UI
- Use freezed for immutable models
- Use injectable for dependency injection

## Performance
- Use `const` constructors
- Implement `==` and `hashCode` for model classes
- Use `ListView.builder` for long lists
- Implement `AutomaticKeepAliveClientMixin` for state preservation

## Testing
- Write widget tests for all UI components
- Write unit tests for business logic
- Use Mockito for mocking dependencies
- Use `testWidgets` for widget tests

## Dependencies
- Use latest stable versions of all packages
- Keep dependencies up to date
- Document all third-party packages in README.md
