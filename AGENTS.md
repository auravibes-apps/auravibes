# AuraVibes Flutter Monorepo - Agent Guidelines

## Project Overview
Flutter monorepo for AuraVibes AI Assistant using Melos for package management.
### Apps:
- AuraVibes: `apps/auravibes_app/`

### Packages:
- `packages/*/`

## Packages

### auravibes_ui
UI component library following const-first design.

**Important:** Read `packages/auravibes_ui/STYLE_GUIDE.md` before modifying UI components.
- Use `AuraColorVariant` enum instead of `Color?` for const compatibility
- Only children/dropdown lists can be variable parameters
- Maximize compile-time constants via enums

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
valid on melos >7
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
flutter test test/test_file_one.dart test/test_file_two.dart --no-pub 
```

### Code Generation
Run code generation commands in the package directory:
```bash
# General build runner command
dart run build_runner build --delete-conflicting-outputs

# Single file generation (use --build-filter for targeted rebuilds)
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/domain/entities/messages.g.dart"

# Multiple specific files
dart run build_runner build --delete-conflicting-outputs \
  --build-filter="lib/domain/entities/messages.g.dart" \
  --build-filter="lib/features/chats/providers/conversation_providers.g.dart"

# Drift database only
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/data/database/drift/app_database.g.dart"

# Router only
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/router/app_router.g.dart"
```

### Build Configuration (`build.yaml`)
The app uses a `build.yaml` to scope generators to relevant directories, reducing unnecessary file scanning:
- **freezed**: `domain/entities/`, `domain/models/`, `features/**/models/`, `features/**/providers/`, `features/**/notifiers/`, `providers/`, `services/`
- **riverpod_generator**: `features/**/providers/`, `features/**/notifiers/`, `providers/`
- **json_serializable**: `domain/entities/`, `services/`
- **drift_dev**: `data/database/`
- **go_router_builder**: `router/`

## Version Conventions

### Badge Versions vs FVM Pinned Version
- **Badge versions** in README.md reflect the **exact FVM pinned version** (e.g., `3.41.4+`)
- This aligns with `.fvmrc` configuration for consistency
- The `+` suffix indicates "this version or compatible updates"

### SDK Constraints in pubspec.yaml
- Use caret syntax for minimum version: `sdk: ^3.11.0`
- This allows any compatible version within the major version range

## Analyzer Ignore Directives

### When to Use `// ignore:` vs `// ignore_for_file:`

**Prefer line-level ignores** (`// ignore: rule_name`) when:
- Only specific lines trigger the warning
- The warning is localized to a known pattern

**Use file-level ignores** (`// ignore_for_file: rule_name`) only when:
- Multiple lines throughout the file trigger the same warning
- The ignore is justified by project architecture

### Required Documentation for Ignores

All ignore directives **must** have a comment explaining the justification:

```dart
// Good: Documented line-level ignore
SomeExperimentalApi(), // ignore: experimental_member_use - Required for widgetbook addon

// Good: Documented file-level ignore
// ignore_for_file: avoid_print
// Required: This is a CLI tool that intentionally prints to stdout
```

### Common Ignore Scenarios

| Rule | When Acceptable | Example |
|------|-----------------|---------|
| `experimental_member_use` | Using `@experimental` APIs from dependencies | Widgetbook addons |
| `avoid_print` | CLI tools, debug utilities | Debug scripts |
| `public_member_api_docs` | Internal packages | Private utilities |

## AI Assistant Notes

### Understanding Project Context
- This is a **Flutter monorepo** using Melos for workspace management
- **Always use `fvm` prefix** for Dart/Flutter commands to ensure correct SDK version
- The project uses `very_good_analysis` for linting with strict rules

### When Reviewing Code
- Check if ignore directives are documented and justified
- Prefer scoped solutions over broad ignores
- Verify version references are consistent across README, pubspec, and FVM config

## Active Technologies
- Dart 3.x (FVM pinned to 3.41.4+) + Flutter, Riverpod (with code generation), Freezed, auravibes_ui (001-two-step-model-selector)
- Drift database (existing, no schema changes needed) (001-two-step-model-selector)
- Dart 3.11+ (Flutter 3.41.4+ via FVM) + Flutter SDK, flutter_portal, gpt_markdown, riverpod (existing) (001-ui-library-widgets)

## Recent Changes
- 001-two-step-model-selector: Added Dart 3.x (FVM pinned to 3.41.4+) + Flutter, Riverpod (with code generation), Freezed, auravibes_ui
- 001-ui-library-widgets: Added Dart 3.11+ (Flutter 3.41.4+ via FVM) + Flutter SDK, flutter_portal, gpt_markdown, riverpod (existing)
