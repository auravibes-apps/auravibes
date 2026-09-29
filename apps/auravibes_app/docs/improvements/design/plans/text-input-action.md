# Fix: Give inputs the correct next, done, search, send, or newline action

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/text-input-action
- **Needs new dependency**: none

## Why

`AuraInput` exposes `textInputAction` and `onSubmitted`, but most call sites omit both. Multi-field forms cannot advance from the keyboard and final fields do not submit. The chat composer is the existing correct example.

## Where

`packages/auravibes_ui/lib/src/organisms/aura_input.dart:29-40`

```dart
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
```

`packages/auravibes_ui/lib/src/organisms/aura_input.dart:224-240`

```dart
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      style: _getTextStyle(
                        auraColors,
                        typography: context.auraTheme.typography,
                      ),
                      autofocus: widget.autofocus && isEnabled,
                      readOnly: isReadOnly,
                      obscureText: widget.obscureText,
                      maxLines: widget.maxLines,
                      minLines: widget.minLines,
                      maxLength: widget.maxLength,
                      onChanged: onChanged,
                      onTap: onTap,
                      onTapOutside: isEnabled ? widget.onTapOutside : null,
                      onFieldSubmitted: onSubmitted,
                      inputFormatters: widget.inputFormatters,
```

The current-source rescan also found these fields beyond the original scan:

- `apps/auravibes_app/lib/features/tools/widgets/add_mcp_modal.dart`: the URL
  is `.done` only when no later auth input is visible; the final OAuth client
  ID or bearer token is `.done` only when connection verification allows the
  existing save callback. Earlier fields stay `.next`.
- `apps/auravibes_app/lib/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart`:
  rename/delete prompt and invite email are single-field dialogs; `.done`
  invokes the same callback as Confirm/Add.
- `apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart`:
  nested body/definition editors remain `.newline`; final single-line enum or
  maximum field saves through the existing guarded callback.
- `apps/auravibes_app/lib/features/skills/screens/skill_credential_definition_edit_screen.dart`:
  final description saves; earlier title, variable, and description fields
  stay `.next`.
- `apps/auravibes_app/lib/features/settings/widgets/compaction_settings_section.dart`:
  numeric threshold uses `.done` and the existing save callback.

Existing correct send behavior:

`apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart:486-495`

```dart
  }) : input = AuraInput(
         controller: controller,
         placeholder: const TextLocale(
           LocaleKeys.chats_screens_chat_conversation_message_placeholder,
         ),
         textInputAction: .send,
         readOnly: isRecording,
         maxLines: ChatInputWidget._maxInputLines,
         onSubmitted: (_) => unawaited(actions.sendMessage()),
         onTapOutside: (_) => focusNode.unfocus(),
```

Affected field groups found by the full scan:

**Cloud auth**

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_login_form.dart:42`

```dart
        AuraInput(
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_login_form.dart:48`

```dart
        AuraInput(
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_register_form.dart:63`

```dart
          AuraInput(
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_register_form.dart:70`

```dart
          AuraInput(
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_register_form.dart:76`

```dart
          AuraInput(
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart:60`

```dart
          AuraInput(
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart:66`

```dart
          AuraInput(
```

`apps/auravibes_app/lib/features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart:78`

```dart
          AuraInput(
```

**Agent forms/search**

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:1124`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:1189`

```dart
  }) : _child = AuraInput(
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:1747`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:2146`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/agents/screens/agents_screen.dart:421`

```dart
  Widget build(BuildContext _) => AuraInput(
```

`apps/auravibes_app/lib/features/agents/widgets/compact_agent_selector.dart:293`

```dart
           AuraInput(
```

**Chat/A2UI/dialog**

`apps/auravibes_app/lib/features/chats/widgets/chat_catalog_text_field.dart:112`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/chats/widgets/chat_list_widget.dart:1183`

```dart
    : _input = AuraInput(
```

`apps/auravibes_app/lib/features/chats/widgets/chat_reasoning_controls.dart:453`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/chats/widgets/rename_conversation_dialog.dart:79`

```dart
  Widget build(BuildContext context) => TextField(
```

**Models/search**

`apps/auravibes_app/lib/features/models/widgets/add_model_provider_widget.dart:2205`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/models/widgets/compact_workspace_model_selector.dart:396`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/models/widgets/compact_workspace_model_selector.dart:658`

```dart
    child: TextField(
```

**Service connections**

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_create_screen.dart:835`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_create_screen.dart:857`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_create_screen.dart:1148`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_edit_screen.dart:1013`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_edit_screen.dart:1084`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_edit_screen.dart:1276`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_edit_screen.dart:1314`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connection_edit_screen.dart:1379`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/service_connections/screens/service_connections_screen.dart:594`

```dart
    child: AuraInput(
```

**Settings**

`apps/auravibes_app/lib/features/settings/widgets/compaction_settings_section.dart:434`

```dart
  Widget build(BuildContext _) => AuraInput(
```

**Skills**

`apps/auravibes_app/lib/features/skills/screens/skill_credential_definition_edit_screen.dart:615`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_credential_definition_edit_screen.dart:904`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_credential_definition_edit_screen.dart:938`

```dart
    return AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_detail_screen.dart:796`

```dart
         AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_resource_edit_screen.dart:350`

```dart
      AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:1619`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:1720`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:1744`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:1813`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:2090`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:2102`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:2166`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:2256`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:2270`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:2284`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:2308`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:2320`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skill_tool_edit_screen.dart:2353`

```dart
  Widget build(BuildContext context) => AuraInput(
```

`apps/auravibes_app/lib/features/skills/screens/skills_screen.dart:536`

```dart
  Widget build(BuildContext _) => AuraInput(
```

**Tools**

`apps/auravibes_app/lib/features/tools/widgets/add_mcp_modal.dart:994`

```dart
  }) : input = AuraInput(
```

`apps/auravibes_app/lib/features/tools/widgets/add_tool_modal.dart:173`

```dart
    child: AuraInput(
```

`apps/auravibes_app/lib/features/tools/widgets/tools_search_input.dart:14`

```dart
    child: AuraInput(
```

**Workspaces**

`apps/auravibes_app/lib/features/workspaces/screens/create_workspace_form.dart:309`

```dart
  }) : _child = AuraInput(
```

`apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart:393`

```dart
      child: AuraInput(
```

`apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart:1626`

```dart
    return AuraInput(
```

Existing multiline editor to preserve:

`apps/auravibes_app/lib/features/markdown/screens/markdown_editor_screen.dart:266-273`

```dart
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: _markdownInputDecoration(context, colors, textStyle),
      keyboardType: .multiline,
      style: textStyle,
      maxLines: null,
      minLines: _minimumEditorLines,
```

## The fix

Apply these rules to every listed group:

- search/filter fields: `.search`; `onSubmitted` may keep the current filter because live filtering already runs;
- non-final single-line fields: `.next`; keep `onEditingComplete` unset so Flutter performs its default next-focus traversal;
- final single-line field: `.done` (or `.go` for URL navigation) plus the same submit/save callback as the visible primary button;
- chat composer: keep `.send` and current callback;
- multiline/body/description editors: keep `maxLines` above `1` and either leave the inferred action alone or set `.newline`; never submit the form on Enter;
- numeric settings fields: `.done`, validate and commit through the existing save path;
- dynamic A2UI fields: `.newline` for multiline variants and `.done` for single-line unless the schema exposes an explicit action.

Use these literal patterns:

```dart
AuraInput(
  textInputAction: .next,
)

AuraInput(
  textInputAction: .done,
  onSubmitted: (_) => submit(),
)
```

Do not add `FocusNode`s or `onSubmitted` to `.next` fields: the article relies on Flutter's default focus traversal. Guard only final submit callbacks with the same loading and validation checks as the visible button. Do not change `AuraInput`'s public default because it cannot know form order.

`AuraInput` wraps its `TextFormField` in an existing `Focus` used to disable
focus when interaction is disabled. Set `skipTraversal: true` on that wrapper;
otherwise Flutter's default `.next` traversal does not reach the following
`AuraInput`. Keep `canRequestFocus` and `descendantsAreFocusable` unchanged. Add
an `AuraInput` widget test that sends `.next` and verifies focus reaches the next
field.

## Steps

1. Start with cloud auth: mark intermediate fields `.next` and connect final fields to the existing submit actions.
2. Classify agent, service-connection, skill, credential, local/cloud workspace, MCP, and settings fields in visual order; use Flutter's default focus traversal for `.next`.
3. Mark all search/filter fields `.search`.
4. Add explicit `.newline` to multiline editors where inference is ambiguous.
5. Add `.done` and submission to one-field dialogs/forms.
6. Add widget tests per form family: action label, default next focus, final submission exactly once, disabled/loading guard, and multiline newline.
7. Re-run the scan; every editable field must be classified or documented as an intentional platform default.

## Check it

```sh
cd packages/auravibes_ui && fvm flutter test test/src/organisms/auravibes_input_test.dart --no-pub
fvm flutter test test/features/cloud_accounts test/features/agents test/features/service_connections test/features/skills --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

Manual check one Android/iOS form using only the soft keyboard action key from first field through submit.

Current verification note: widget tests cover next/done labels and guarded
submission. `fvm flutter devices` lists an iPhone 17 Pro simulator and two
wireless iOS devices, but the native soft-keyboard check remains unverified
because the required Orca UI runtime could not connect.

## Don't touch

- Validation rules.
- Form layout.
- Chat Enter/Shift+Enter semantics beyond the existing `.send` contract.
- Read-only fields.
- Custom focus traversal or new `FocusNode`s.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- A dynamic form has no stable visual order or submit callback. Do not invent navigation; add the action only when the owning schema supplies enough intent.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report each field group classification, tests, and any documented exception.

## Attempt log

- 2026-09-28: Re-scanned editable fields. Search inputs use `.search`; ordered form fields use `.next`/`.done`; chat uses `.send`; dynamic A2UI uses `.newline` for multiline and `.done` for single-line; Markdown's unbounded multiline `TextFormField` keeps Flutter's inferred newline action. `AuraInput`'s wrapper skips traversal so default `.next` reaches the next field.
- `fvm flutter test test/src/organisms/auravibes_input_test.dart --no-pub`: 16 passed. `fvm flutter test test/features/cloud_accounts test/features/agents test/features/service_connections test/features/skills --no-pub`: 215 passed.
- `fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine`: exit 1. All emitted diagnostics were info-level lints in `friendly_build_error_widget.dart` and its test, not the text-action call sites; the friendly-error plan's STOP condition prevents changing that separate implementation here.
- Manual iOS soft-keyboard check remains unverified. The iPhone 17 Pro simulator is available, but Orca reported `runtime_unavailable` after startup; no alternate UI tool was used.
