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

All Dart-related commands should be prefixed with `fvm ` to ensure the correct SDK version is used.

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

Valid on Melos 7+.

```bash
fvm dart run melos analyze                # Analyze code quality
fvm dart run melos format             # Check code formatting
fvm dart run melos run test               # Run all tests (fast, no coverage)
fvm dart run melos run test:coverage      # Run all tests with coverage
fvm dart run melos run test:ci            # Run tests in CI mode (coverage + optimized)
fvm dart run melos run validate:quick     # Quick development check
fvm dart run melos run validate           # Full CI validation (without coverage)
fvm dart run melos run validate:ci        # Full CI validation with coverage
```

### Running Specific Tests

In the package directory, use:

```bash
# Single file
fvm flutter test test/path/to/file_test.dart --no-pub

# Multiple files
fvm flutter test test/file_one_test.dart test/file_two_test.dart --no-pub

# Entire directory
fvm flutter test test/domain/usecases/ --no-pub

# Filter by test name (regex)
fvm flutter test --name "should emit loading" --no-pub

# Filter by tag (see dart_test.yaml for defined tags)
fvm flutter test --tags slow --no-pub

# Exclude tagged tests
fvm flutter test --exclude-tags widget --no-pub

# Use CI flags (reduced concurrency for 2-core runners)
fvm flutter test --concurrency=2 --timeout=30s --reporter=compact --no-pub
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

### Implementation Standards (from Constitution v2.1.0)

These rules are non-negotiable for all new code and refactors:

1. **Database Cascade**: Use `ON DELETE CASCADE` at the Drift schema level. No manual cascade deletion in app code.
2. **Business Logic in Usecases**: Business rules, validation, and orchestration MUST live in domain usecase classes. Providers delegate; widgets render.
3. **Reactive Data as Streams**: Repository queries feeding live-updating UI MUST return `Stream`. One-shot `Future` only when live updates are not needed.
4. **Localization**: All user-facing strings MUST use `tr()` / `LocaleKeys` / `TextLocale`. No hardcoded English in UI code. Prefer the `TextLocale` widget for `Text()` children; use `.tr()` only for non-widget contexts (String parameters, error messages, tooltips).
5. **Typed Errors**: User-facing errors MUST be typed exception classes carrying localization keys. No raw `String` error messages in `AsyncValue` or state objects.
6. **AsyncValue Switch Pattern**: Use Dart 3 switch expressions / pattern matching on `AsyncValue`. `.when()` is PROHIBITED in new code.
7. **Mutation State**: Data mutations (CRUD) MUST use Riverpod `Mutation` or equivalent explicit mutation pattern. No manual `AsyncValue.loading()` toggling in notifiers.
8. **UI Package Purity**: `packages/auravibes_ui/` widgets MUST be domain-agnostic and reusable across projects. No business-specific naming or logic in the UI package.
9. **Small Widgets**: Each widget SHOULD watch at most one provider. Decompose large widgets into focused composable pieces.

## When Reviewing Code

- Check if ignore directives are documented and justified
- Prefer scoped solutions over broad ignores
- Verify version references are consistent across README, pubspec, and FVM config
- Verify new code follows the 9 Implementation Standards above

## Active Technologies

- **Current baseline (workspace-wide):** Dart 3.11+ with Flutter 3.41.9 via FVM, Flutter, Riverpod (hooks_riverpod/Riverpod 3 + code generation), Freezed, Drift, auravibes_ui.
- **Spec-specific additions/notes:**
  - (008-avoid-approval-flash) Existing Drift `messages` metadata JSON and tool permission tables; no schema changes planned.
  - (001-two-step-model-selector) Existing Drift database; no schema changes needed.
  - (001-ui-library-widgets) Uses `flutter_portal` and `gpt_markdown` with existing Riverpod setup.
  - (003-token-usage-context) Uses `dartantic_ai` (`ChatResult<ChatMessage>` / `LanguageModelUsage`) and existing Drift `messages` metadata JSON (no schema migration planned).

## Recent Changes

- 001-two-step-model-selector: Added Dart 3.x (FVM pinned to 3.41.4+) + Flutter, Riverpod (with code generation), Freezed, auravibes_ui
- 001-ui-library-widgets: Added Dart 3.11+ (Flutter 3.41.4+ via FVM) + Flutter SDK, flutter_portal, gpt_markdown, riverpod (existing)

<!-- SPECKIT START -->

For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at `specs/011-agent-compaction-settings/plan.md`

<!-- SPECKIT END -->
