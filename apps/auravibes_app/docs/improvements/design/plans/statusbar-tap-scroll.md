# Fix: Preserve iOS status-bar tap scrolling in chat

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/statusbar-tap-scroll
- **Needs new dependency**: none

## Why

Chat needs a custom controller for disclosure anchoring and jump-to-latest behavior. Passing it directly to `ListView` prevents iOS from discovering it as the route's primary scroll controller.

## Where

`apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart:60-66`

```dart
}) extends HookConsumerWidget {
  // Null lets callers fall back to per-message provider reads.
  // ignore: unnecessary-nullable
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(_DisclosureScrollController.new);
    useEffect(() => controller.dispose, [controller]);
```

`apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart:174-203`

```dart
    return Stack(
      children: [
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

`apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart:1130-1143`

```dart
class const _LoadedChatConversationView({
  required final _LoadedChatConversationData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _ChatConversationBody(data: data),
      appBar: _ChatConversationAppBar(
        title: data.conversation.title,
        leading: data.leading,
      ),
    );
  }
}
```

`apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart:1966-1980`

```dart
class _DisclosureScrollController extends ScrollController {
  var anchorActive = false;
  _RenderDisclosureSizeReporter? _anchorReporter;
  double _pendingExtentDelta = 0;

  void beginAnchor(_RenderDisclosureSizeReporter? reporter) {
    anchorActive = true;
    _anchorReporter = reporter;
    _pendingExtentDelta = 0;
  }

  void clearAnchor() {
    anchorActive = false;
    _anchorReporter = null;
    _pendingExtentDelta = 0;
```

## The fix

The `PrimaryScrollController` must be above `AuraScreen`, because `AuraScreen` creates the `Scaffold` whose iOS status-bar handler reads the inherited controller. A wrapper inside `ChatMessagesWidget` is too low in the tree.

Add this owner beside `ChatMessagesWidget`:

```dart
class const ChatPrimaryScrollController({
  required final Widget child,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(_DisclosureScrollController.new);
    useEffect(() => controller.dispose, [controller]);

    return PrimaryScrollController(controller: controller, child: child);
  }
}
```

Wrap the screen's scaffold:

```dart
return ChatPrimaryScrollController(
  child: AuraScreen(
    child: _ChatConversationBody(data: data),
    appBar: _ChatConversationAppBar(
      title: data.conversation.title,
      leading: data.leading,
    ),
  ),
);
```

Then replace local controller creation in `ChatMessagesWidget.build` with:

```dart
final controller =
    PrimaryScrollController.of(context) as _DisclosureScrollController;
```

Keep `controller: controller` on `ListView.separated`, exactly as the article passes the same custom controller to both `PrimaryScrollController` and the scrollable. Keep disclosure and jump-to-latest references on that instance. Flutter's iOS handler animates the primary controller to offset `0.0`; for this reverse list that is the newest-message edge and matches `jumpToLatest`.

## Steps

1. Add `ChatPrimaryScrollController` in `chat_messages_widget.dart`; it owns and disposes the existing custom controller.
2. Wrap `_LoadedChatConversationView`'s `AuraScreen` with that owner.
3. Read the inherited controller in `ChatMessagesWidget`; remove its local creation/disposal and keep passing it to the list.
4. Keep disclosure and jump-to-latest references unchanged.
5. Add a widget test proving the `Scaffold` and list resolve the same controller and that offset `0.0` is the newest edge.
6. Test on a physical iPhone; simulators/status-bar clicks can differ.

## Check it

```sh
fvm flutter test test/features/chats/widgets/chat_messages_widget_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Reverse chat ordering.
- Disclosure scroll calculations.
- Jump-to-latest threshold/animation.
- Shared `AuraScreen`; this controller belongs only to chat.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: STOP condition reached because the plan's local-controller
  excerpts are stale: `ChatPrimaryScrollController` now owns the disclosure
  controller above `AuraScreen`, and `ChatMessagesWidget` reads that same
  inherited controller. The focused jump-to-latest test passed and confirms the
  Scaffold/list share the controller and return to the newest edge. Fatal app
  analyzer passed in the preceding verification run. Physical iPhone
  status-bar-tap behavior remains unverified; no source change made.

## STOP if

- Primary controller wiring changes initial chat offset or disclosure anchoring. Fix controller ownership before proceeding; do not patch offsets.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report focused tests and physical-iPhone status-bar behavior.
