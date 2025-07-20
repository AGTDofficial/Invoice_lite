# Maintenance Guide

This guide provides best practices for keeping your Flutter project up-to-date with modern development standards while avoiding the bleeding edge.

## Dependency Management

### Update Strategy
- **Target Versions**: Aim for versions that are 6-12 months old (stable but not outdated)
- **Update Frequency**: Check for updates every 3 months
- **Testing**: Always test thoroughly after updates, especially for major version changes

### Using the Dependency Updater

1. Run the dependency updater tool:
   ```bash
   dart run tool/dependency_updater.dart
   ```

2. The tool will:
   - Check current versions against recommended targets
   - Backup your pubspec.yaml
   - Update to recommended versions
   - Run `flutter pub get`

3. Review changes in `pubspec.yaml` and test your app

### Manual Update Process

1. Check outdated packages:
   ```bash
   flutter pub outdated
   ```

2. Update a specific package:
   ```bash
   flutter pub upgrade package_name
   ```

3. Update all packages to latest compatible versions:
   ```bash
   flutter pub upgrade --major-versions
   ```

## Code Modernization

### Modern Flutter Patterns

1. **State Management**:
   - Use Riverpod for most state management needs
   - Consider Provider for simpler state needs
   - Avoid using StatefulWidget directly for complex state

2. **Null Safety**:
   - Ensure all code is null-safe
   - Use the `?` and `!` operators appropriately
   - Prefer non-nullable types where possible

3. **Async/Await**:
   - Use `async`/`await` instead of `.then()`
   - Handle errors with try/catch
   - Use `FutureBuilder` for UI that depends on async data

### Hive Best Practices

1. **Type Adapters**:
   - Keep type IDs unique
   - Document each type ID in `docs/code_reference/MODELS_REFERENCE.md`
   - Use `@HiveType` and `@HiveField` consistently

2. **Database Migrations**:
   - Plan for schema changes
   - Write migration scripts when changing models
   - Test migrations thoroughly

## Testing Updates

1. **Unit Tests**:
   - Run after every dependency update
   - Focus on business logic and models

2. **Widget Tests**:
   - Test UI components
   - Mock dependencies appropriately

3. **Integration Tests**:
   - Test critical user flows
   - Run on multiple devices/emulators

## Common Issues and Solutions

### Version Conflicts
1. **Symptom**: `Because package depends on X which doesn't match any versions, version solving failed`
   - **Solution**: Run `flutter clean` then `flutter pub get`
   - If persists, check dependency constraints in `pubspec.yaml`

2. **Symptom**: Breaking changes after update
   - **Solution**: Check package changelog for migration guide
   - Consider using `dependency_overrides` temporarily

### Performance Issues
1. **Symptom**: App feels sluggish after update
   - **Solution**: Run Flutter performance profiler
   - Check for expensive operations in `build` methods

## Recommended Tools

1. **Code Analysis**:
   - `flutter analyze`
   - `flutter pub run build_runner build --delete-conflicting-outputs`

2. **Dependency Visualization**:
   ```bash
   flutter pub deps
   flutter pub outdated --show-all-transitive-dependencies
   ```

3. **Code Generation**:
   ```bash
   # Run after updating freezed models
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## Security Best Practices

1. **Dependencies**:
   - Regularly audit dependencies for security vulnerabilities
   - Use `dart pub outdated --show-dependencies`

2. **Secrets**:
   - Never commit API keys or secrets to version control
   - Use environment variables or `--dart-define`

## Continuous Integration

Consider setting up CI to:
1. Run tests on every push
2. Check for outdated dependencies
3. Enforce code style and analysis

## When to Update

- **Update Now**: Security fixes, critical bug fixes
- **Plan Update**: New features, performance improvements
- **Defer Update**: Major version changes, breaking changes

## Getting Help

- Check package documentation and GitHub issues
- Search for migration guides
- Ask in Flutter community forums

Remember: The goal is to stay current enough to benefit from improvements and security fixes, while avoiding the instability of the absolute latest versions.
