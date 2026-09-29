# Fix: Show localized release notes once after an app update

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/in-app-changelog
- **Needs new dependency**: add `package_info_plus` and direct `pub_semver`; `shared_preferences` already exists

## Why

`main()` starts the app and schedules model sync, but no code compares the running version with the last version the user saw. Releases therefore have no discoverable “what's new” moment.

## Where

`apps/auravibes_app/pubspec.yaml:8`

```yaml
version: 0.0.4
```

`apps/auravibes_app/pubspec.yaml:51-71`

```yaml
  intl: ^0.20.2
  json_annotation: ^4.12.0
  json_schema_builder: ^0.1.7
  logging: ^1.3.0
  marionette_flutter: 0.6.0
  material_ui: ^1.2.0
  math_expressions: ^3.1.0
  mcp_client: ^2.2.1
  mime: ^2.1.0
  openai_dart: ^8.0.0

  # Other dependencies
  path: ^1.9.1
  path_provider: ^2.1.6
  record: ^7.1.1
  riverpod: 3.4.3
  riverpod_annotation: 4.0.7
  rxdart: ^0.28.0
  schemantic: ^0.2.0
  serverpod_auth_core_client: 4.0.3
  shared_preferences: ^2.5.4
```

`apps/auravibes_app/lib/main.dart:28-43`

```dart
Future<void> main() async {
  _configureFlavor();
  final marionetteInstanceId = _ensureFlutterBinding();
  _configureLogging();
  await MainLocale.ensureInitialized();

  _configureSystemUi();
  final container = ProviderContainer();
  if (marionetteInstanceId != null) {
    MarionetteExtensionRegistration.register(
      MarionetteExtensionBootstrap.createState(container),
    );
  }

  _runApp(container);
  _scheduleModelSync(container);
```

`apps/auravibes_app/lib/main/main_locale.dart:9-13`

```dart
class const MainLocale({required final Widget child, super.key})
    extends StatelessWidget {
  static const supportedLocales = [Locale('en'), Locale('es')];
  static Future<void> ensureInitialized() {
    return EasyLocalization.ensureInitialized();
```

`apps/auravibes_app/assets/i18n/en.json:1`

```json
{
```

`apps/auravibes_app/assets/i18n/es.json:1`

```json
{
```

## The fix

1. Add exact compatible versions with `fvm flutter pub add package_info_plus pub_semver` from `apps/auravibes_app`.
2. Define the article's remote JSON contract. The product-approved HTTPS endpoint must return this exact shape and include every supported locale:

```json
{
  "0.0.4": {
    "en": ["First English release note."],
    "es": ["Primera nota de la versión en español."]
  }
}
```

The sample strings describe shape only; replace them with approved release copy. Do not ship them.

3. Add `lib/features/changelog/app_changelog.dart` with the article's version comparison, adapted to locale codes and deterministic ascending order:

```dart
typedef AppChangelog = Map<String, Map<String, List<String>>>;

List<String> unseenChanges({
  required AppChangelog changelog,
  required String lastSeen,
  required String current,
  required String languageCode,
}) {
  final lastSeenVersion = Version.parse(lastSeen);
  final currentVersion = Version.parse(current);
  final entries = changelog.entries.toList()
    ..sort(
      (left, right) =>
          Version.parse(left.key).compareTo(Version.parse(right.key)),
    );
  final result = <String>[];

  for (final entry in entries) {
    final entryVersion = Version.parse(entry.key);
    if (entryVersion > lastSeenVersion && entryVersion <= currentVersion) {
      result.addAll(entry.value[languageCode] ?? const []);
    }
  }

  return result;
}
```

4. Add `lib/features/changelog/app_changelog_service.dart` that fetches and decodes the approved endpoint through the app's existing `Dio` dependency, then:
   - reads `PackageInfo.version`;
   - parses it with `Version.parse`;
   - reads the literal preference key `last_seen_version` from `SharedPreferences`;
   - returns no dialog on first install and persists the current version;
   - selects every entry newer than the last seen version and no newer than the current version;
   - combines skipped release entries in ascending version order;
   - persists only after dismissal.
5. Add a localized changelog dialog widget. Show version headings and bullet lists, with one localized dismiss action.
6. Add a post-frame app-start coordinator under the existing `MainLocale`/`MaterialApp` tree. Do not open a dialog before a navigator and localization context exist.
7. On network, HTTP, schema, locale, or version-parse failure, log through the existing logger and show nothing. Never block startup and never advance `last_seen_version` when the remote changelog could not be evaluated.

## Steps

1. Add dependencies through Flutter tooling, not by typing constraints.
2. Add English and Spanish title/dismiss localization keys; regenerate localization output with the repository command.
3. Add the approved remote changelog document, fetcher, version comparison service, and dialog.
4. Invoke it once after the first frame from the app shell.
5. Add unit tests for first install, same version, one update, skipped updates, downgrade, malformed stored version, and persistence only after dismiss.
6. Add a widget test proving the dialog appears once with the current locale's copy.

## Check it

From `apps/auravibes_app`:

```sh
fvm flutter test test/features/changelog --no-pub
```

From repository root:

```sh
fvm dart run melos run generate:localization
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

Manual check: start with no preference, confirm no dialog; store `0.0.3`, launch `0.0.4`, dismiss, relaunch, and confirm it does not repeat.

## Don't touch

- Release update/download flows.
- Model sync scheduling.
- Analytics.
- Generated localization files by hand.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The release-note copy for either locale is unavailable.
- No product-approved HTTPS changelog endpoint exists. Do not invent a URL or silently replace the article's remote source with hard-coded Dart copy.
- Product wants first-install onboarding to show release notes; that conflicts with the article's first-install rule and needs a separate decision.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report dependency versions, storage key, tests run, and the two manual launch outcomes.

## Attempt log

### 2026-09-28 — blocked on product inputs

- Confirmed app version remains `0.0.4`; no changelog service, release-note document, or changelog UI exists in the app.
- Searched app source, localization assets, web files, and pubspec for changelog/release-note content and endpoint configuration; found no approved endpoint or English/Spanish release copy.
- Stopped before adding dependencies or placeholder data, as required by the plan.
- Status: requires product-approved HTTPS endpoint and localized release-note copy.
