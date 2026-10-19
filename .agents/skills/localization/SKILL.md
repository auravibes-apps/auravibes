---
name: localization
description: Use when adding translation keys or changing localization behavior. Skip unrelated UI edits and existing-key usage.
license: MIT
metadata:
  author: AuraVibes
  version: "2.0.0"
  domain: flutter
  triggers: translation, i18n, l10n, locale, easy_localization, LocaleKeys, TextLocale, translate, en.json, es.json, localization, gender, plural, linked, audit, codegen
  role: specialist
  scope: implementation
---

# Flutter Localization

Use this skill when you add translation keys or change localization behavior in AuraVibes.

## AuraVibes rules

- Read `apps/auravibes_app/AGENTS.md` before you change user-facing text.
- Check `pubspec.lock` before you use package APIs. It currently selects `easy_localization` 3.0.8.
- Add every new key to both `assets/i18n/en.json` and `assets/i18n/es.json`.
- App rules and `tool/localization_audit.dart` check key parity. Runtime fallback does not replace catalog entries.
- Use `TextLocale` for widget text when possible. Use `LocaleKeys` or `.tr()` when code needs a translated string.
- Use typed exceptions with localization keys for user-facing errors.
- Do not edit generated `lib/i18n/locale_keys.dart` by hand.

## Workflow

1. Read the app localization rules and inspect the target catalog entries.
2. Add or change the same nested key in both locale catalogs. Keep placeholders consistent.
3. From the repository root, run `fvm dart run melos run generate:localization`.
4. Use the generated `LocaleKeys` constant in code. Use `TextLocale` for widget text when possible.
5. Add or update a focused test when code behavior changes. See [usage and testing](references/usage-and-testing.md).
6. From `apps/auravibes_app`, run `fvm dart run tool/localization_audit.dart`.
7. Review catalog and generated-file diffs. Keep generated output from the generator.

## Completion checks

- No new user-facing text uses a hardcoded English string.
- Every changed key exists in both catalogs with matching placeholders.
- Generated `LocaleKeys` matches catalog keys.
- The localization audit reports no missing keys, parity issues, placeholder mismatches, or dynamic translation issues.
- Focused tests pass when code behavior changes.

## Reference branches

- For JSON structure, key names, placeholders, plurals, gender, or linked keys, read [catalogs](references/catalogs.md).
- For locale setup, switching, loaders, platform settings, or right-to-left behavior, read [runtime and platform](references/runtime.md).
- For `LocaleKeys`, `TextLocale`, or widget-test patterns, read [usage and testing](references/usage-and-testing.md).
