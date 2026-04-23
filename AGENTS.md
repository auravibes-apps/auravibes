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
fvm dart run melos bs                    # Install dependencies & link packages
fvm dart run melos clean                 # Clean all packages
fvm dart run melos list                  # List all packages
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
fvm dart run melos analyze            # Analyze code quality
fvm dart run melos format             # Check code formatting
fvm dart run melos run test               # Run all tests
fvm dart run melos run validate:quick     # Quick development check
fvm dart run melos run validate           # Full CI validation
```

### Running Specific Tests

in the package directory, use:

```bash
fvm flutter test test/test_file_one.dart test/test_file_two.dart --no-pub
```

### Code Generation

Run code generation commands in the package directory:

```bash
# General build runner command
fvm dart run build_runner build --delete-conflicting-outputs

# Single file generation example
fvm dart run build_runner build --delete-conflicting-outputs --build-filter="lib/brick/db_types.g.dart"
```

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

| Rule                      | When Acceptable                              | Example           |
| ------------------------- | -------------------------------------------- | ----------------- |
| `experimental_member_use` | Using `@experimental` APIs from dependencies | Widgetbook addons |
| `avoid_print`             | CLI tools, debug utilities                   | Debug scripts     |
| `public_member_api_docs`  | Internal packages                            | Private utilities |

## AI Assistant Notes

### Understanding Project Context

- This is a **Flutter monorepo** using Melos for workspace management
- **Always use `fvm` prefix** for Dart/Flutter commands to ensure correct SDK version
- The project uses `very_good_analysis` for linting with strict rules
- Prefer Dart dot shorthand syntax when possible in Dart 3.11+ code if the context type is clear, especially for enums, constructors, and obvious static members

### Dart Style

- Use Dart dot shorthand syntax from `https://dart.dev/language/dot-shorthands` when it improves readability and the context type is obvious
- Prefer shorthand most strongly for enum values and typed constructor initialization such as `.new()`
- Use the explicit type instead when shorthand would be ambiguous, surprising, or harder to scan

### When Reviewing Code

- Check if ignore directives are documented and justified
- Prefer scoped solutions over broad ignores
- Verify version references are consistent across README, pubspec, and FVM config

## Active Technologies

- Dart 3.x (FVM pinned to 3.41.4+) + Flutter, Riverpod (with code generation), Freezed, auravibes_ui (001-two-step-model-selector)
- Drift database (existing, no schema changes needed) (001-two-step-model-selector)
- Dart 3.11+ (Flutter 3.41.4+ via FVM) + Flutter SDK, flutter_portal, gpt_markdown, riverpod (existing) (001-ui-library-widgets)
- Dart 3.11+ with Flutter 3.41.4+ (FVM pinned) + Flutter, Riverpod, Drift, dartantic_ai (`ChatResult<ChatMessage>` / `LanguageModelUsage`), auravibes_ui (003-token-usage-context)
- Existing Drift `messages` table metadata JSON (no schema migration planned) (003-token-usage-context)

## Recent Changes

- 001-two-step-model-selector: Added Dart 3.x (FVM pinned to 3.41.4+) + Flutter, Riverpod (with code generation), Freezed, auravibes_ui
- 001-ui-library-widgets: Added Dart 3.11+ (Flutter 3.41.4+ via FVM) + Flutter SDK, flutter_portal, gpt_markdown, riverpod (existing)

<!-- SPECKIT START -->

For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at `specs/006-fix-native-tool-permissions/plan.md`

<!-- SPECKIT END -->
