# AuraVibes Flutter Monorepo - Agent Guidelines

## Project Overview
Flutter monorepo for AuraVibes AI Assistant using Melos for package management.
### Apps:
- AuraVibes: `apps/auravibes_app/`

### Packages:
- `packages/*/`

## Commands
all dart related commands should prefix with `fvm ` to ensure correct SDK version is used.

e.g. `fvm dart run melos bootstrap`

### Melos Commands
```bash
melos bs                    # Install dependencies & link packages
melos clean                 # Clean all packages
melos list                  # List all packages
```

### Dependency Management
**IMPORTANT**: Always use these commands instead of manually editing pubspec.yaml files.

```bash
# Add runtime dependencies
fvm flutter pub add package_name

# Add development dependencies  
fvm flutter pub add dev:package_name

# Add dependencies with version constraints
fvm flutter pub add package_name:^1.0.0

# Examples:
fvm flutter pub add riverpod dio flutter_markdown
fvm flutter pub add dev:build_runner dev:json_serializable
```

### Quality & Testing
```bash
melos analyze            # Analyze code quality
melos format             # Check code formatting
melos run test               # Run all tests
melos run validate:quick     # Quick development check
melos run validate           # Full CI validation
```

### Running Specific Tests
in the package directory, use:
```bash
flutter test test/my_test_file.dart
```

### Code Generation
Run code generation commands in the package directory:
```bash
# General build runner command
dart run build_runner build --delete-conflicting-outputs

# Single file generation example
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/brick/db_types.g.dart"
```