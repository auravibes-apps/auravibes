# Fix: Keep final list content above the system navigation bar

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/safe-area-replacement
- **Needs new dependency**: none

## Why

Aura runs edge-to-edge. `AuraScreen` adds top padding only when an app bar exists, while page-root lists use fixed all-side padding. On gesture/navigation-bar devices, their last item can sit under the bottom system area.

## Where

`packages/auravibes_ui/lib/src/molecules/aura_screen.dart:86-93`

```dart
  Widget build(BuildContext context) {
    final appBar = screen.appBar;
    if (appBar == null) return child;

    return Padding(
      padding: .only(top: MediaQuery.paddingOf(context).top),
      child: child,
    );
```

The page-root scrollables with fixed bottom padding are:

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:838`

```dart
  Widget build(BuildContext context) => ListView(
```

`apps/auravibes_app/lib/features/agents/screens/agents_screen.dart:593`

```dart
    return ListView.separated(
```

`apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart:779`

```dart
  Widget build(BuildContext context) => SingleChildScrollView(
```

`apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_account_add_screen.dart:58`

```dart
      ListView(padding: const EdgeInsets.all(16), children: _children);
```

`apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_account_forgot_password_screen.dart:20`

```dart
      child: ListView(
```

`apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_account_login_screen.dart:24`

```dart
      child: ListView(
```

`apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_account_register_screen.dart:24`

```dart
      child: ListView(
```

`apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_accounts_screen.dart:27`

```dart
      child: ListView(
```

`apps/auravibes_app/lib/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart:78`

```dart
    return ListView(
```

`apps/auravibes_app/lib/features/intro/screens/intro_screen.dart:186`

```dart
      ListView(padding: const EdgeInsets.all(24), children: _children);
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_create_screen.dart:750`

```dart
    return ListView(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_create_screen.dart:957`

```dart
    return ListView(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_edit_screen.dart:935`

```dart
    return ListView(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connections_screen.dart:792`

```dart
    return ListView.separated(
```

`apps/auravibes_app/lib/features/settings/screens/settings_screen.dart:139`

```dart
    return SingleChildScrollView(
```

`apps/auravibes_app/lib/features/skills/screens/skill_credential_definition_edit_screen.dart:551`

```dart
    return ListView(
```

`apps/auravibes_app/lib/features/skills/screens/skill_credential_definitions_screen.dart:219`

```dart
    return ListView.separated(
```

`apps/auravibes_app/lib/features/skills/screens/skill_detail_screen.dart:715`

```dart
    return ListView(
```

`apps/auravibes_app/lib/features/skills/screens/skill_resource_edit_screen.dart:305`

```dart
    return ListView(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:1351`

```dart
  Widget build(BuildContext context) => ListView(
```

`apps/auravibes_app/lib/features/skills/screens/skills_screen.dart:882`

```dart
  Widget build(BuildContext context) => ListView.separated(
```

`apps/auravibes_app/lib/features/workspaces/screens/create_workspace_screen.dart:33`

```dart
    return ListView(
```

`apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart:373`

```dart
    return ListView(
```

The intro additionally wraps its scrollable ancestor in `SafeArea`:

`apps/auravibes_app/lib/features/intro/screens/intro_screen.dart:123-134`

```dart
  Widget build(BuildContext context) => SafeArea(
    child: _IntroContentContainer(
      slide: slide,
      titleKey: titleKey,
      bodyKey: bodyKey,
      onCreated: onCreated,
      onBack: onBack,
      onContinue: onContinue,
      onConnectAi: onConnectAi,
      onSkipAi: onSkipAi,
    ),
  );
```

## The fix

Add an app helper:

```dart
abstract final class BottomPadding {
  static double of(BuildContext context, {double minimum = 16}) {
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    return viewPadding > minimum ? viewPadding : minimum;
  }
}
```

For each page-root scrollable above, preserve left/top/right values and replace only bottom with `BottomPadding.of(context, minimum: currentBottom)`. Add a bottom padding to `new_chat_screen.dart` where the current scroll view has none. For intro, set `bottom: false` on the current `SafeArea` so top/side safety remains, and put its bottom inset in the `ListView.padding`.

Use `viewPadding`, not `padding` or `viewInsets`: the system-bar inset must remain stable when the keyboard opens. Do not add bottom padding to nested lists, chat messages above the composer, or bottom-sheet lists.

## Steps

1. Add `lib/widgets/bottom_padding.dart` with unit tests for minimum-vs-system inset.
2. Update every listed page-root scrollable, preserving its existing minimum.
3. Remove only intro's bottom `SafeArea` behavior.
4. Add widget tests for a zero inset and a larger fake `viewPadding.bottom`.
5. Test one short and one long page on a gesture-navigation device/emulator.

## Check it

```sh
fvm flutter test test/widgets/bottom_padding_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

Manual check: scroll each representative 8/12/16/24-padding page to its end; last control remains fully visible and content can still scroll behind the translucent system area.

## Don't touch

- Chat timeline padding.
- Bottom-sheet safe areas.
- Top app-bar inset behavior.
- Scroll physics.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- A listed scrollable is not the page root at implementation time. Trace its parent and avoid double-applying the inset.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report helper tests, screens sampled, device navigation mode, and any removed false-positive location.

## Attempt log

- 2026-09-28: STOP condition reached before edits. `agent_detail_screen.dart`'s listed `_AgentSkillsDialogList` and `_AgentToolPermissionsDialogList` are inside `_AgentManageDialog`, not page-root scrollables; adding page-root system-bar padding there would change dialog behavior. No source edits or checks run. The quoted `AuraScreen` excerpt still matches. The plan's `/details/md/` article URL is unavailable; the canonical Flutter Pro Design article was accessible at `/details/safe-area-replacement` and confirms the `viewPadding` approach. Remove the dialog false positives before retrying this plan.
- 2026-09-28: Rechecked the listed scroll owners after merging `origin/main`. Removed both agent dialog lists and the Markdown editor list (its `SafeArea` toolbar reserves the system inset); added the merged `SkillCredentialDefinitionsScreen` result list. Updated 23 page scroll owners to use `max(viewPadding.bottom, existing minimum)`; intro `SafeArea` now leaves the bottom edge to its scroll padding. `fvm flutter test test/widgets/bottom_padding_test.dart --no-pub` passed (2 tests). Fatal analysis of the 24 changed Dart files passed. Full app analysis failed twice; after fixing in-scope diagnostics, remaining INFOs were only in `friendly_build_error_widget.dart` and its test, so stopped per this plan's retry limit without touching that separate STOP case. Manual scroll sample not run: the connected iPhone 17 Pro app has no Flutter Driver extension enabled.
