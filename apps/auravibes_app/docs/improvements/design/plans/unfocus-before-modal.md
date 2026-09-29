# Fix: Clear primary focus before opening modal UI

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/unfocus-before-modal
- **Needs new dependency**: none

## Why

Aura's shared dialog/modal helpers and direct Flutter modal calls open routes without clearing `FocusManager.instance.primaryFocus`. A keyboard can return when the modal closes even though the user left the field.

## Where

Shared UI entry points:

`packages/auravibes_ui/lib/src/organisms/aura_confirm_dialog.dart:270-287`

```dart
Future<T?> _showAuraDialog<T>(_AuraDialogRequest request) =>
    _showGeneralDialog(request);

Future<T?> _showGeneralDialog<T>(_AuraDialogRequest request) =>
    _AuraGeneralDialogData<T>(request).future;

class _AuraGeneralDialogData<T> {
  new(_AuraDialogRequest request)
    : future = showGeneralDialog<T>(
        context: request.context,
        pageBuilder: _auraDialogPageBuilder(request.child),
        barrierDismissible: request.barrierDismissible,
        barrierLabel: MaterialLocalizations.of(request.context)
            .modalBarrierDismissLabel,
        barrierColor: request.context.auraColors.scrim,
        transitionBuilder: (_, animation, _, child) =>
            _AuraDialogTransition(animation: animation, child: child),
      );
```

`packages/auravibes_ui/lib/src/organisms/aura_modal.dart:112-120`

```dart
  Future<void> _show(BuildContext context) async {
    if (_isShowing || !AuraInteractionScope.of(context).allowsNavigation) {
      return;
    }

    _isShowing = true;
    try {
      await _showAuraModal(context, widget);
    } finally {
```

`packages/auravibes_ui/lib/src/organisms/aura_date_time_input.dart:197-203`

```dart
  Future<DateTime?> _openPickerDialog(_PickerDialogRequest request) =>
      showGeneralDialog<DateTime>(
        context: request.parentContext,
        pageBuilder: (_, _, _) => _AuraDateTimePickerPage(request: request),
        barrierColor: request.parentContext.auraColors.scrim,
        useRootNavigator: false,
      );
```

Direct app modal entry points currently bypass those helpers:

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:208`

```dart
    return showDialog<void>(
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:252`

```dart
    return showDialog<void>(
```

`apps/auravibes_app/lib/features/agents/screens/agents_screen.dart:192`

```dart
  final shouldDelete = await showDialog<bool>(
```

`apps/auravibes_app/lib/features/agents/screens/agents_screen.dart:848`

```dart
      showModalBottomSheet<AgentVisibility>(
```

`apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart:1742`

```dart
    showDialog<void>(
```

`apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart:1760`

```dart
    showDialog<void>(
```

`apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart:1875`

```dart
  final confirmed = await showDialog<bool>(
```

`apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart:104`

```dart
      showDialog<void>(
```

`apps/auravibes_app/lib/features/chats/widgets/active_sub_agent_status_widget.dart:160`

```dart
  final _ = showModalBottomSheet<void>(
```

`apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart:928`

```dart
  return showModalBottomSheet<void>(
```

`apps/auravibes_app/lib/features/chats/widgets/chat_reasoning_control.dart:49`

```dart
      showModalBottomSheet<void>(
```

`apps/auravibes_app/lib/features/chats/widgets/rename_conversation_dialog.dart:9`

```dart
    return showDialog<String>(
```

`apps/auravibes_app/lib/features/chats/widgets/tool_call_response_modal.dart:29`

```dart
    return showDialog<void>(
```

`apps/auravibes_app/lib/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart:432`

```dart
  return showDialog<String>(
```

`apps/auravibes_app/lib/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart:456`

```dart
  final result = await showDialog<bool>(
```

`apps/auravibes_app/lib/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart:484`

```dart
  final result = await showDialog<_InviteRequest>(
```

`apps/auravibes_app/lib/features/skills/screens/skill_credential_definition_edit_screen.dart:297`

```dart
    return showDialog<bool>(
```

`apps/auravibes_app/lib/features/skills/screens/skill_detail_screen.dart:418`

```dart
    return showDialog<bool>(
```

`apps/auravibes_app/lib/features/skills/screens/skill_detail_screen.dart:1378`

```dart
    final shouldDelete = await showDialog<bool>(
```

`apps/auravibes_app/lib/features/skills/screens/skill_resource_edit_screen.dart:233`

```dart
    final result = await showDialog<bool>(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:566`

```dart
    await showDialog<void>(
```

`apps/auravibes_app/lib/features/skills/screens/skills_screen.dart:117`

```dart
    return showDialog<bool>(
```

`apps/auravibes_app/lib/features/skills/screens/skills_screen.dart:754`

```dart
Future<bool?> _confirmSkillsBulkDelete(BuildContext context) =>
    showDialog<bool>(
```

`apps/auravibes_app/lib/features/tools/widgets/add_mcp_modal.dart:30`

```dart
    return showDialog<void>(
```

`apps/auravibes_app/lib/features/tools/widgets/add_tool_modal.dart:28`

```dart
    return showDialog<void>(
```

`apps/auravibes_app/lib/features/markdown/markdown_editor_launcher.dart:10`

```dart
    return Navigator.of(context).push<String>(
```

## The fix

Call exactly:

```dart
FocusManager.instance.primaryFocus?.unfocus();
```

after interaction guards and immediately before each shared/direct modal route is created. Put it centrally in `AuraDialogs`, `AuraModal`, and `AuraDateTimeInput`; do not edit their many callers. Add the same line at every direct app entry point listed above. If a method is expression-bodied, convert only enough to insert the call.

Do not use `FocusScope.of(context).unfocus()`; it can move focus within the scope rather than clearing the primary focus.

## Steps

1. Add central focus clearing to the three Aura UI entry points.
2. Add it to each direct app modal entry point.
3. Add tests: focus field → open modal → dismiss → assert field does not regain focus.
4. Cover dialog, bottom sheet, date picker, AuraModal, and full-screen editor route.

## Check it

```sh
cd packages/auravibes_ui && fvm flutter test --no-pub
cd ../../apps/auravibes_app && fvm flutter test test/features/chats test/features/workspaces --no-pub
```

## Don't touch

- Focus inside the modal after it opens.
- Autofocus on single-field modal contents.
- Popup menus that do not create modal routes.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: Confirmed shared `AuraDialogs`, `AuraModal`, and
  `AuraDateTimeInput` clear `FocusManager.instance.primaryFocus` before route
  creation. All listed direct modal openers do too; the custom spring-sheet
  caller also unfocuses. Tests cover dialog, date picker, `AuraModal`, rename,
  reasoning sheet, and Markdown editor focus restoration. UI package suite
  passed 731 tests. Chat/workspace suite: 1,058 passed, one unrelated
  transcript-context test failed in the grouped run; that file passed all 6
  tests in isolation. The full app fatal analyzer passed earlier. No exception
  requiring focus restoration found.

## STOP if

- A modal is intentionally launched from an active editor and must restore its exact selection. Document that exception and test it rather than globally refocusing.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report central entry points, direct exceptions, and focus-restoration tests.
