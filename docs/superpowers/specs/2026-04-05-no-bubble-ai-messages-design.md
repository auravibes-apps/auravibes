# No-Bubble AI Messages

**Date:** 2026-04-05
**Status:** Approved

## Summary

Remove the bubble styling (background, border radius, shadow, max-width) from all AI messages in the chat interface. AI messages render full-width with no visual container, while user messages retain their existing bubble appearance.

## Motivation

AI messages read more naturally without a bubble — they fill the available horizontal space and feel like system-level content rather than chat bubbles.

## Design

### Approach

Add a `bool showBubble` parameter (default `true`) to the existing `AuraMessageBubble` widget. When `false`, the widget skips all bubble decoration and renders content directly at full width.

### Changes

#### 1. `AuraMessageBubble` — `packages/auravibes_ui/lib/src/molecules/auravibes_message_bubble.dart`

- Add parameter: `final bool showBubble;` (defaults to `true`)
- When `showBubble == false`:
  - No `Container` with `BoxDecoration` (no background color, no border radius, no shadow, no error border)
  - No max-width constraint — content fills available horizontal space
  - No `Align` widget — content is left-aligned naturally
  - Content (GptMarkdown) renders with `onSurface` text color
  - Timestamp and status indicators still render below content

#### 2. `chat_messages_widget.dart` — `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart`

- Pass `showBubble: !message.isUser` to `AuraMessageBubble`
- AI messages (`isUser == false`) get `showBubble: false`
- User messages remain unchanged (`showBubble: true` by default)

### What stays the same

- User messages: bubble, right-aligned, primary background, max-width 75%
- Tool call widgets: unchanged
- Markdown rendering via GptMarkdown: unchanged
- Message status and delivery indicators: unchanged
- AuraMessageBubble public API: backward-compatible (new parameter has default value)

### Affected files

| File | Change |
|------|--------|
| `packages/auravibes_ui/lib/src/molecules/auravibes_message_bubble.dart` | Add `showBubble` parameter, conditional rendering |
| `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart` | Pass `showBubble: !message.isUser` |
| `packages/auravibes_ui/test/src/molecules/auravibes_message_bubble_test.dart` | Add tests for `showBubble: false` |
| `widgetbook/lib/aura_ui/auravibes_message_bubble_stories.dart` | Add story for flat variant |

### Testing

- Unit tests for `AuraMessageBubble` with `showBubble: false` — verify no `BoxDecoration`, no max-width constraint
- Existing tests remain passing (backward-compatible change)
- Widgetbook story for visual verification
