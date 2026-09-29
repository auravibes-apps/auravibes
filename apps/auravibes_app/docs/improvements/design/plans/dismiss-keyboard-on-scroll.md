# Fix: Dismiss the keyboard when form and search results scroll

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/dismiss-keyboard-on-scroll
- **Needs new dependency**: none

## Why

Form and filtered-list scrollables omit `keyboardDismissBehavior`, so their keyboard can keep covering content after the user starts scrolling. The chat timeline has the opposite problem: it explicitly dismisses on drag even though the article says chat scrolling should preserve an in-progress message.

## Where

Chat behavior to correct:

`apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart:176-203`

```dart
        ListView.separated(
          reverse: true,
          controller: controller,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) => _buildChatTimelineItem(
            index: index,
            data: data,
            showThinking: showThinking,
            isCompacting: isCompacting,
            thinkingCount: thinkingCount,
            compactionCount: compactionCount,
            disclosureController: controller,
            onDisclosureChanged: updateDisclosure,
            parentConversationId: parentConversationId,
            childConversations: childConversations,
            workspaceId: workspaceId,
            a2uiRuntime: isTopLevelConversation ? a2uiRuntime : null,
            replayPayloadsByMessageId: submittedA2uiReplayPayloads,
            conversation: conversation,
            retryableMessageId: retryableMessageId,
            onRetryMessage: onRetryMessage,
          ),
          separatorBuilder: (context, index) => const AuraSizedBox(height: .md),
          itemCount: itemCount,
          addAutomaticKeepAlives: false,
          scrollCacheExtent: const ScrollCacheExtent.pixels(500),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        ),
```

Form/search scrollables missing the property:

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:838`

```dart
  Widget build(BuildContext context) => ListView(
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:1727`

```dart
    return ListView(
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:2113`

```dart
  Widget build(BuildContext context) => ListView(
```

`apps/auravibes_app/lib/features/agents/screens/agents_screen.dart:593`

```dart
    return ListView.separated(
```

`apps/auravibes_app/lib/features/agents/widgets/compact_agent_selector.dart:322`

```dart
    : _child = ListView.separated(
```

`apps/auravibes_app/lib/features/chats/widgets/chat_list_widget.dart:1254`

```dart
  Widget build(BuildContext _) => ListView.separated(
```

`apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_account_login_screen.dart:24`

```dart
      child: ListView(
```

`apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_account_register_screen.dart:24`

```dart
      child: ListView(
```

`apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_account_forgot_password_screen.dart:20`

```dart
      child: ListView(
```

`apps/auravibes_app/lib/features/models/widgets/add_model_provider_widget.dart:789`

```dart
    return SingleChildScrollView(
```

`apps/auravibes_app/lib/features/models/widgets/add_model_provider_widget.dart:2225`

```dart
    return ListView.builder(
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

`apps/auravibes_app/lib/features/tools/widgets/add_mcp_modal.dart:165`

```dart
  Widget build(BuildContext context) => SingleChildScrollView(
```

`apps/auravibes_app/lib/features/tools/widgets/add_tool_modal.dart:276`

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

## The fix

Set:

```dart
keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
```

on every listed form/search scrollable. If both an outer and inner scrollable represent one surface, put it on the scrollable that actually wins vertical drag gestures; avoid redundant nested settings. Do not add it to the Markdown editor's long-form editing list or to horizontal control rows.

For the chat timeline, replace the current value with the article's chat exception:

```dart
keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
```

Do not change the chat composer's focus or submit callbacks.

## Steps

1. Add `.onDrag` to each listed form/search drag owner.
2. Change the chat timeline from `.onDrag` to `.manual`.
3. Add focused widget tests for a page form, a search/results list, and a modal list: focus input, drag list, assert focus clears.
4. Add a chat test: focus the composer, drag message history, assert focus remains.
5. Test touch drag and mouse-wheel behavior; only touch drag is required to unfocus.

## Check it

```sh
fvm flutter test test/features/cloud_accounts test/features/agents test/features/skills --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Chat composer submission.
- Markdown editor focus.
- Horizontal scrolling.
- `onTapOutside` behavior.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: Audited every listed scrollable. Form/search drag owners use
  `keyboardDismissBehavior: .onDrag`; chat history uses `.manual`. Existing
  widget tests cover cloud-login focus dismissal, agent-sheet and conversation
  search dismissal, and chat-history focus retention. The listed suites ran
  167 tests successfully, with one failure in
  `cloud_skill_production_routing_test.dart`; that test passed when run alone.
  App fatal analyzer passed. The parallel-suite failure was not reproduced;
  physical mouse-wheel behavior was not checked.

## STOP if

- A nested scrollable does not receive the drag. Move the property to the gesture-owning parent instead of adding manual focus listeners.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report updated drag owners and focused test cases.
