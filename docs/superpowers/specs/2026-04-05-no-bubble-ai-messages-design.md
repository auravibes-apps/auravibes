# No-Bubble AI Messages

**Date:** 2026-04-05
**Status:** Approved

## Summary

Remove the bubble styling (background, border radius, shadow, max-width) from all AI messages in the chat interface. AI messages render full-width with no visual container, while user messages retain their existing bubble appearance.

## Motivation

AI messages read more naturally without a bubble — they fill the available horizontal space and feel like system-level content rather than chat bubbles.

## Design

### Approach

Skip `AuraMessageBubble` entirely for AI messages. Render markdown content directly in `chat_messages_widget.dart` for AI messages. `AuraMessageBubble` stays unchanged — it remains a bubble widget for user messages.

Rationale: A "bubble without a bubble" is a contradiction. AI messages with no background, no max-width, no decoration are just markdown text. No need to stretch the bubble abstraction.

### Changes

#### 1. `chat_messages_widget.dart` — `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart`

- In `_ChatMessageRow.build`, branch on `message.isUser`:
  - **User messages** (`isUser == true`): use `AuraMessageBubble` as before (unchanged)
  - **AI messages** (`isUser == false`): render `GptMarkdown` directly with `onSurface` text color, no Container, no max-width, no background, no alignment. Optionally show timestamp below.

#### 2. `AuraMessageBubble` — no changes

- Remains unchanged as a bubble-only widget
- No new parameters needed

### What stays the same

- User messages: bubble, right-aligned, primary background, max-width 75%
- Tool call widgets: unchanged
- Markdown rendering via GptMarkdown: unchanged
- Message status and delivery indicators: unchanged
- AuraMessageBubble: no changes to public API

### Affected files

| File | Change |
|------|--------|
| `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart` | Branch rendering: user → AuraMessageBubble, AI → direct markdown |
| `packages/auravibes_ui/test/src/molecules/auravibes_message_bubble_test.dart` | No changes needed |

### Testing

- Existing `AuraMessageBubble` tests remain passing (widget unchanged)
- Manual visual verification: AI messages full-width, no bubble; user messages unchanged
