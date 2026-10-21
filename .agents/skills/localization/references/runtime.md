# Runtime and platform settings

Read this file when you change locale setup, locale switching, asset loading, platform settings, or right-to-left behavior.

## Inspect current app wiring

- `apps/auravibes_app/lib/main/main_locale.dart` owns `EasyLocalization` settings.
- `apps/auravibes_app/lib/main.dart` initializes `MainLocale` before `runApp` and wraps the app with it.
- The app passes `context.locale`, `context.localizationDelegates`, and `context.supportedLocales` to `MaterialApp`.
- `apps/auravibes_app/lib/widgets/text_locale.dart` resolves `TextLocale` with the current context.

Inspect these files before you change locale behavior. Do not replace app wiring with a generic package example.

The current app supports `en` and `es`. It uses English as fallback and enables fallback for missing or empty translations. Keep both catalogs complete because app rules and audit checks need matching keys.

## Locale switching

Use the package context extension to switch or reset the locale. In async callbacks, await locale changes.

```dart
await context.setLocale(const Locale('es'));
await context.resetLocale();
```

Use `context.deviceLocale` to read the device locale. Await `context.deleteSaveLocale()` to clear the saved locale.

## Optional code generation

The app currently loads JSON assets. Use `CodegenLoader` only when a task needs compile-time translation assets. This generic command assumes `apps/auravibes_app` as the working directory. Check generator help for the resolved package version.

```bash
fvm dart pub run easy_localization:generate \
  -S assets/i18n \
  -f json \
  -O lib/generated \
  -o codegen_loader.g.dart
```

Import the generated `CodegenLoader` from `package:auravibes_app/generated/codegen_loader.g.dart` and pass `CodegenLoader()` as `assetLoader`. Regenerate after catalog changes and review generated output.

Use `extraAssetLoaders` when another package owns translation assets. Check the installed loader package before you name a loader class.

## Platform and failure behavior

- The current iOS `Info.plist` lists `en` and `es` under `CFBundleLocalizations`. Match this list when you add a supported locale.
- Easy Localization supports right-to-left locales. Flutter uses `Directionality` for layout direction.
- Use `errorWidget` for translation-load failures. Localize any user-facing message.
- Change logger settings only when the task needs different missing-key diagnostics. Keep useful error logs enabled.
