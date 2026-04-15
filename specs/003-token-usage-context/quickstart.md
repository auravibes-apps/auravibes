# Quickstart: Conversation Token Usage Indicator

## 1) Implement persistence mapping

1. Extend message metadata entity with usage fields.
2. Map `ChatResult.usage` into metadata during assistant message streaming updates.
3. Ensure final message update persists usage snapshot.

## 2) Implement aggregation

1. Add conversation-level provider to compute used tokens from persisted messages.
2. Overlay in-flight streaming usage from `messagesStreamingNotifier` state.
3. Resolve model context limit for active conversation model.
4. Apply fallback order `totalTokens -> prompt+completion -> 0` and clamp UI percent to `0..100`.

## 3) Implement top-bar UI

1. Add usage label in format `39k/205k - 19%`.
2. Add circular progress indicator bound to computed percent.
3. Ensure values refresh while streaming.

## 4) Validate

1. Run focused tests for use case and provider behavior.
2. Run app-level analysis/tests as feasible.

## 5) Commands

From repo root:

- `fvm dart run melos analyze`
- `fvm dart run melos run test`

Or package/app-scoped tests during development.
