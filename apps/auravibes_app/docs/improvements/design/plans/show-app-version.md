# Fix: Show app version and build number in Settings

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/show-app-version
- **Needs new dependency**: `package_info_plus` (share the dependency with the changelog plan if both are implemented)

## Why

Settings ends after appearance and compaction controls. Users cannot quote the exact installed version/build in support reports.

## Where

`apps/auravibes_app/pubspec.yaml:8`

```yaml
version: 0.0.4
```

`apps/auravibes_app/lib/features/settings/screens/settings_screen.dart:138-153`

```dart
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_settingsScreenPadding),
      child: AuraColumn(
        children: [
          _AppSettingsCard(
            currentTheme: currentTheme,
            onThemeTap: onThemeTap,
            onThemeReset: onThemeReset,
          ),
          CompactionSettingsSection(workspaceId: workspaceId),
          const AccentColorSection(),
        ],
        crossAxisAlignment: .start,
      ),
    );
```

`apps/auravibes_app/lib/features/settings/screens/settings_screen.dart:157-174`

```dart
class const _AppSettingsCard({
  required final AppTheme currentTheme,
  required final VoidCallback onThemeTap,
  required final VoidCallback onThemeReset,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          _appSettingsHeader,
          _ThemeTile(theme: currentTheme, onTap: onThemeTap),
          _ThemeResetButton(onPressed: onThemeReset),
        ],
        spacing: .none,
        crossAxisAlignment: .start,
      ),
    );
```

## The fix

Add this focused widget under `features/settings/widgets/`, adapting only the color to Aura's theme:

```dart
class AppVersionIndicator extends StatefulWidget {
  const AppVersionIndicator({super.key});

  @override
  State<AppVersionIndicator> createState() => _AppVersionIndicatorState();
}

class _AppVersionIndicatorState extends State<AppVersionIndicator> {
  String? _label;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;

    final build = info.buildNumber.isEmpty ? '' : ' (${info.buildNumber})';
    setState(() => _label = '${info.appName} ${info.version}$build');
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) return const SizedBox.shrink();

    return Text(
      label,
      style: TextStyle(
        color: context.auraColors.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
```

Import `FontFeature` from `dart:ui`, `package_info_plus`, and the Aura UI barrel. Append `const AppVersionIndicator()` as the final child of `_SettingsBody`. This produces one dim line such as `AuraVibes 0.0.4 (123)`. Do not add Shorebird patch display because this repository does not use Shorebird.

## Steps

1. Add `package_info_plus` with `fvm flutter pub add package_info_plus` unless already added by the changelog work.
2. Add the focused version widget and append it to `_SettingsBody`.
3. Add a widget test with mocked package info for populated and empty build numbers; loading stays invisible through `SizedBox.shrink`.

## Check it

```sh
fvm flutter test test/features/settings --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

Manual check on one native target and web: displayed version/build matches package metadata.

## Don't touch

- Update checking.
- Release channels.
- Shorebird.
- Theme settings behavior.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: Confirmed `AppVersionIndicator` is the final Settings entry and
  shows package name, version, and build number; an empty build number is
  omitted. `package_info_plus` supports mocked metadata in widget tests. The
  focused Settings suite passed 60 tests and the full app fatal analyzer passed
  in the preceding verification run. No Shorebird dependency or patch API is
  present. Native/web runtime metadata was not manually checked.

## STOP if

- Package metadata cannot be mocked with `package_info_plus`'s test support. Stop instead of adding a singleton or a public architecture boundary.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report displayed values on tested platforms and focused-test result.
