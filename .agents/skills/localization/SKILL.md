---
name: localization
description: Comprehensive guide for Flutter localization using easy_localization. Covers adding translations, structuring JSON files, reusing templates and keys, saving space, using LocaleKeys, TextLocale widget, gender, plurals, linked translations, audit, and advanced features. Use when adding, editing, or troubleshooting app translations.
license: MIT
metadata:
  author: AuraVibes
  version: "2.0.0"
  domain: flutter
  triggers: translation, i18n, l10n, locale, easy_localization, LocaleKeys, TextLocale, translate, en.json, es.json, localization, gender, plural, linked, audit, codegen
  role: specialist
  scope: implementation
---

# Flutter Localization with easy_localization

This skill covers the complete workflow for adding, structuring, generating, and using translations in the AuraVibes Flutter app using `easy_localization`.

**Package version**: `easy_localization: ^3.0.8` (published 9 months ago as of 2026-04-30)  
**Docs**: https://pub.dev/packages/easy_localization

## Tech Stack

- `easy_localization: ^3.0.8`
- `easy_localization_loader: ^2.0.2`
- JSON-based translation files
- Code-generated `LocaleKeys` class
- Optional: `CodegenLoader` for compile-time asset loading

## Quick Commands

```bash
# Generate LocaleKeys after editing JSON files
fvm dart run melos run generate:localization

# Or directly in the app package:
fvm dart pub run easy_localization:generate \
  -S assets/i18n \
  -f keys \
  -O lib/i18n \
  -o locale_keys.dart \
  --skip-unnecessary-keys && fvm dart format lib/i18n/locale_keys.dart

# Audit missing keys in code vs translations
fvm dart pub run easy_localization:audit -t assets/i18n -s lib
```

## File Structure

```
apps/auravibes_app/
├── assets/i18n/
│   ├── en.json          # Base language (required, fallback)
│   └── es.json          # Additional language
├── lib/
│   ├── i18n/
│   │   └── locale_keys.dart   # Auto-generated, DO NOT EDIT
│   ├── main/locale.dart       # EasyLocalization wrapper
│   └── widgets/
│       └── text_locale.dart   # Const-safe Text wrapper
```

## 1. Adding Translations

### JSON Structure

Use dot-notation hierarchy. Group by **feature/screen** at the top level, not by UI element.

```json
{
  "menu": {
    "home": "Home",
    "new_chat": "New Chat"
  },
  "chats_screens": {
    "chat_conversation": {
      "message_placeholder": "Type your message...",
      "queued_messages_count": {
        "one": "1 queued message",
        "other": "{} queued messages"
      }
    }
  }
}
```

### Rules

- **Always add to `en.json` first**. It is the fallback language.
- **Mirror the exact same keys** in `es.json` (or other languages).
- Use `snake_case` for all keys.
- Prefer **nouns** over verbs for key names: `home` not `go_home`.

### String Interpolation

Use `{}` for positional arguments:

```json
{
  "list_url_label": "URL: {}",
  "list_delete_confirm": "Are you sure you want to delete {name}?",
  "tools_count": "{enabled} of {total} enabled"
}
```

- `{}` — first arg
- `{name}` — named arg (passed as `namedArgs`)

### Pluralization

Use ICU plural forms (`zero`, `one`, `other`):

```json
{
  "models_available": {
    "zero": "No models available",
    "one": "{} model available",
    "other": "{} models available"
  }
}
```

- `zero` — 0
- `one` — 1
- `other` — everything else
- `two`, `few`, `many` — enable with `ignorePluralRules: false` (see Advanced Config)

## 2. Good Structure

### Group by Feature, Not by Widget

❌ Bad:

```json
{
  "buttons": { "save": "Save", "cancel": "Cancel" },
  "labels": { "name": "Name" }
}
```

✅ Good:

```json
{
  "models_screens": {
    "add_provider": {
      "fields": {
        "name": {
          "label": "Name",
          "placeholder": "Enter provider name",
          "hint": "Choose a descriptive name"
        }
      }
    }
  }
}
```

### Shared Common Keys

Extract strings reused across multiple screens into a `common` namespace:

```json
{
  "common": {
    "cancel": "Cancel",
    "save": "Save",
    "delete": "Delete",
    "confirm": "Confirm",
    "close": "Close"
  }
}
```

This avoids duplication and keeps per-feature files lean.

### Tool/Model Names

If names need translation, isolate them:

```json
{
  "tools_names": {
    "calculator": {
      "name": "Calculator",
      "description": "Solve Math problems"
    }
  }
}
```

## 3. Reusing Templates (Args & Plurals)

### Positional Args in Widgets

```dart
TextLocale('models_screens.list_url_label', args: ['https://api.openai.com'])
```

### Named Args

```dart
// In JSON: "list_delete_confirm": "Are you sure you want to delete {name}?"
text.tr(namedArgs: {'name': 'OpenAI'})
```

### Plurals with `tr()`

```dart
Text(
  'models_available'.tr(
    pluralValue: count,
    args: [count.toString()],
  ),
)
```

### Plurals with NumberFormat

```dart
import 'package:intl/intl.dart';

Text('money').plural(
  1000000,
  format: NumberFormat.compact(locale: context.locale.toString()),
) // Output: "You have 1M dollars"
```

### Gender

```json
{
  "greeting": {
    "male": "Hi man ;) {}",
    "female": "Hello girl :) {}",
    "other": "Hello {}"
  }
}
```

```dart
Text('greeting').tr(gender: isFemale ? 'female' : 'male', args: ['Alex'])
```

## 4. Reusing Keys (Linked Translations)

If one key always has the same text as another, **link** to it with `@:` prefix.

### Basic Linking

```json
{
  "common": {
    "save": "Save",
    "save_action": "@:common.save"
  }
}
```

```dart
Text('common.save_action').tr() // Output: "Save"
```

### Composite Links

```json
{
  "example": {
    "hello": "Hello",
    "world": "World!",
    "helloWorld": "@:example.hello @:example.world"
  }
}
```

```dart
print('example.helloWorld'.tr()); // Output: "Hello World!"
```

### Links with Args

```json
{
  "date": "{currentDate}.",
  "dateLogging": "INFO: the date today is @:date"
}
```

```dart
print(
  'dateLogging'.tr(
    namedArgs: {'currentDate': DateTime.now().toIso8601String()},
  ),
);
// Output: "INFO: the date today is 2026-04-30T10:00:00.000."
```

### Formatting Linked Keys

Control case of linked messages with modifiers:

| Modifier           | Effect                  |
| ------------------ | ----------------------- |
| `@.upper:key`      | UPPERCASE               |
| `@.lower:key`      | lowercase               |
| `@.capitalize:key` | Capitalize first letter |

```json
{
  "forms": {
    "fullName": "Full Name",
    "emptyNameError": "Please fill in your @.lower:forms.fullName"
  }
}
```

```dart
print('forms.emptyNameError'.tr()); // Output: "Please fill in your full name"
```

**Best practice**: Use linked translations for:

- Reusing `common` strings inside feature-specific keys
- Composing complex messages from smaller parts
- Ensuring consistent terminology across the app

## 5. Saving Space

- **`useFallbackTranslations: true`** — Missing keys in `es.json` fall back to `en.json` automatically. No need to copy everything.
- **`useFallbackTranslationsForEmptyResources: true`** — If a translation is an empty string in the locale file, use fallback.
- **`useOnlyLangCode: true`** — Uses `en` instead of `en_US`, reducing asset variants.
- **`--skip-unnecessary-keys`** in the generation command skips unused keys, keeping `locale_keys.dart` smaller.
- **Keep JSON flat where possible** — Deep nesting bloats both the file and the generated Dart.
- **Use `common` namespace + linked keys** — Prevents duplicate strings across features.
- **`ignorePluralRules: true`** (default) — Ignores `few`/`many` forms, keeping JSON smaller for languages that don't need them.

## 6. Using Translation in the App

### Setup in `main.dart`

```dart
import 'package:auravibes_app/main/locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MainLocale.ensureInitialized();

  runApp(
    ProviderScope(
      child: MainLocale(child: MyApp()),
    ),
  );
}
```

### `MainLocale` Wrapper

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

export 'package:easy_localization/easy_localization.dart'
    show BuildContextEasyLocalizationExtension;

const supportedLocales = [Locale('en'), Locale('es')];

class MainLocale extends StatelessWidget {
  const MainLocale({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: supportedLocales,
      path: 'assets/i18n',
      fallbackLocale: supportedLocales.first,
      useFallbackTranslations: true,
      useFallbackTranslationsForEmptyResources: true,
      useOnlyLangCode: true,
      saveLocale: true,
      child: child,
    );
  }

  static Future<void> ensureInitialized() {
    return EasyLocalization.ensureInitialized();
  }
}
```

### MaterialApp Delegates

```dart
MaterialApp.router(
  locale: context.locale,         // Required: widgets rebuild on locale change
  localizationsDelegates: context.localizationDelegates,
  supportedLocales: context.supportedLocales,
  // ...
)
```

**Critical:** `locale: context.locale` is required. Without it, `context.setLocale()` won't trigger a rebuild and the UI won't update when switching languages.

### Switching Locale

```dart
// Change to Spanish
context.setLocale(Locale('es'));

// Reset to device locale
context.resetLocale();

// Get device locale
print(context.deviceLocale); // Locale('en', 'US')

// Clear saved locale from storage
context.deleteSaveLocale();
```

### Locale String Utilities

```dart
import 'package:easy_localization/easy_localization.dart';

// Parse string to Locale
'en_US'.toLocale();                    // Locale('en', 'US')
'en|US'.toLocale(separator: '|');      // Locale('en', 'US')

// Locale to formatted string
Locale('en', 'US').toStringWithSeparator(separator: '|'); // "en|US"
```

## 7. Using LocaleKeys

### Import

```dart
import 'package:auravibes_app/i18n/locale_keys.dart';
```

### In Widgets

```dart
TextLocale(LocaleKeys.menu_home)
TextLocale(LocaleKeys.models_screens_add_provider_fields_name_label)
```

### In Logic / Non-Widget Code

```dart
import 'package:easy_localization/easy_localization.dart';

String formatError(String provider) {
  return LocaleKeys.models_screens_list_error.tr(args: [provider]);
}
```

### Testing with LocaleKeys

Unit tests that don't need a BuildContext can import `LocaleKeys` directly and use a mock translate function:

```dart
import 'package:auravibes_app/i18n/locale_keys.dart';

String mockTranslate(String key, {List<String>? args}) {
  if (args != null && args.isNotEmpty) return '$key:${args.first}';
  return key;
}

expect(result, LocaleKeys.home_screen_date_formatting_just_now);
```

This decouples business logic from widget-tree dependencies.

## 8. Using TextLocale

`TextLocale` is a thin, **const-safe** wrapper around Flutter's `Text` that automatically calls `.tr()`.

### Basic Usage

```dart
TextLocale(LocaleKeys.menu_home)
```

### With Arguments

```dart
TextLocale(
  LocaleKeys.chats_screens_chat_conversation_queued_messages_count,
  args: [count.toString()],
)
```

### With Styling

```dart
TextLocale(
  LocaleKeys.home_screen_welcome_title,
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### Inside Other Widgets

```dart
AuraText(
  style: AuraTextStyle.bodySmall,
  color: AuraColorVariant.onSurfaceVariant,
  child: TextLocale(LocaleKeys.settings_screen_app_settings_subtitle),
)
```

### Why TextLocale?

- **Const constructor** — `const TextLocale(...)` works at compile time.
- **Zero boilerplate** — No manual `.tr()` calls in UI code.
- **Type-safe** — Accepts only `String` keys, not arbitrary text.
- **Testable** — Constructor tests verify params without a BuildContext.

### Testing TextLocale

```dart
test('constructor stores args', () {
  const widget = TextLocale('some.key', args: ['arg1', 'arg2']);
  expect(widget.args, ['arg1', 'arg2']);
});
```

For widget tests that actually resolve text, wrap with `EasyLocalization`:

```dart
import 'package:auravibes_app/test/helpers/test_app.dart';

await tester.pumpWidget(
  testableApp(child: MyWidget()),
);
await tester.pumpAndSettle();
```

## 9. Advanced Features

### Codegen Loader (Compile-Time Assets)

Instead of loading JSON at runtime, generate a Dart file with all translations embedded:

```bash
fvm dart pub run easy_localization:generate \
  -S assets/i18n \
  -f json \
  -O lib/generated \
  -o codegen_loader.g.dart
```

```dart
import 'package:auravibes_app/generated/codegen_loader.g.dart';

EasyLocalization(
  assetLoader: const CodegenLoader(),
  // ... other options
)
```

**Pros**: Faster startup, no asset loading delay.  
**Cons**: Must regenerate when translations change, larger binary.

### Multi-Module / Package Support

Load translations from other packages:

```dart
EasyLocalization(
  extraAssetLoaders: [
    TranslationsLoader(packageName: 'auravibes_ui'),
  ],
  // ...
)
```

### Audit Missing Keys

Find keys used in Dart code but missing from translation files:

```bash
fvm dart pub run easy_localization:audit -t assets/i18n -s lib
```

Output shows which keys are referenced in code but not found in JSON files.

### Logger Customization

```dart
// Show only errors and warnings (e.g., missing keys)
EasyLocalization.logger.enableLevels = [
  LevelMessages.error,
  LevelMessages.warning,
];

// Completely disable logger
EasyLocalization.logger.enableBuildModes = [];

// Custom printer
EasyLocalization.logger.printer = (
  Object object, {
  String? name,
  StackTrace? stackTrace,
  LevelMessages? level,
}) {
  debugPrint('[$level] $name: $object');
};
```

### Error Widget

Show a custom widget when translation loading fails:

```dart
EasyLocalization(
  errorWidget: (message) => Scaffold(
    body: Center(child: Text('Failed to load translations: $message')),
  ),
  // ...
)
```

### iOS Setup

Add supported locales to `ios/Runner/Info.plist`:

```xml
<key>CFBundleLocalizations</key>
<array>
  <string>en</string>
  <string>es</string>
</array>
```

Without this, iOS may not recognize supported languages.

### RTL Locales

`easy_localization` automatically handles RTL (right-to-left) locales like Arabic (`ar`) and Hebrew (`he`). Flutter's `Directionality` widget adapts layout automatically when the locale changes.

## Workflow Summary

1. **Add/change strings** in `assets/i18n/en.json` (and `es.json` if applicable).
2. **Run generation**: `fvm dart run melos run generate:localization`
3. **Use keys** via `LocaleKeys.*` in widgets and logic.
4. **Render text** with `TextLocale(LocaleKeys.your_key)` or `.tr()` directly.
5. **Test** unit logic with `LocaleKeys` constants; widget tests with `testableApp`.
6. **Audit** periodically: `fvm dart pub run easy_localization:audit`

## Common Pitfalls

| Problem                     | Cause                               | Fix                                                |
| --------------------------- | ----------------------------------- | -------------------------------------------------- |
| `LocaleKeys` not found      | Forgot to run generator             | Run `fvm dart run melos run generate:localization` |
| Key shows raw string        | Missing in target JSON, no fallback | Add to `en.json`, enable `useFallbackTranslations` |
| `{}` not replaced           | Args list empty/mismatch            | Pass `args: [value]` to `TextLocale` or `.tr()`    |
| Plural always uses `other`  | `pluralValue` not passed            | Use `.tr(pluralValue: count, args: [...])`         |
| Widget test shows `tr(...)` | No `EasyLocalization` wrapper       | Use `testableApp()` helper                         |
| Linked key shows `@:...`    | `@:` syntax wrong or target missing | Verify target key exists; use full dotted path     |
| iOS not localized           | Missing `CFBundleLocalizations`     | Add to `Info.plist`                                |
| Locale not persisted        | `saveLocale: false`                 | Set `saveLocale: true` in `EasyLocalization`       |
| Gender always `other`       | Gender string mismatch              | Ensure JSON keys match `gender` param exactly      |
