# Chat Activity Details Design

**Date:** 2026-09-29

**Issues:** #909, #910, #945, #1161

## Goal

Keep intermediate assistant content visible in Activity, expose provider failures with useful safe detail, and tell users when tool output was clipped before reaching the model or storage.

## User-visible behavior

- Assistant attachments, A2UI surfaces, replay payloads, and diagnostics followed by tool activity stay in chronological order inside Activity. Expanded content keeps its existing interaction behavior. Non-final content has no Copy, Fork, Retry, or final-response footer.
- Copy/Fork/Retry appear only after the assistant turn is terminal and no later assistant or tool activity belongs to it. A2UI content awaiting user interaction stays visible and interactive while response actions remain hidden.
- Provider detail survives initial, streaming, and retry failures. The inline error remains selectable and copyable; displayed and copied text is redacted.
- Expanded tool details identify context truncation, original byte size, and the actual context limit. They also state whether the persisted output was clipped. Results within the context budget have no truncation warning.

## Design

Keep behavior in the existing chats feature and engine output-policy boundary. Timeline items retain the assistant message needed to render rich content instead of reducing it to plain text. Terminal state gates response actions. Provider detail remains attached as errors cross app wrappers and is sanitized before persistence and display. Tool truncation disclosure reads the existing versioned projection envelope and persisted tool-call metadata; local and cloud reopen paths already carry those values.

Alternatives considered: parsing projection JSON directly in the app would couple UI to the engine format; a new diagnostics subsystem would add a second model for information already carried by chat errors and tool metadata. Both are rejected in favor of the current feature and engine contracts.

## Constraints

- Preserve current defaults: 16 KiB model-context output and 256 KiB persisted output. Do not add a full-output bypass or change tool-output policy.
- Do not expose credentials, tokens, passwords, or other detected secrets in persisted provider detail, rendered error text, or copied text.
- Keep new user-facing copy localized in English and Spanish.
- Preserve backward compatibility for messages without truncation metadata; do not infer unavailable sizes or limits.
- Scope remains the four assigned issues and their shared code. Do not modify #868 or #947 and do not depend on other groups' branches or completion.

## Verification

- Widget regressions cover rich intermediate responses, chronological ordering, streaming-to-terminal action visibility, A2UI interaction, and absence of final actions on intermediate content.
- App and engine tests cover provider detail preservation/redaction across initial, streaming, and retry paths, plus selectable/copyable rendering.
- Engine and app tests cover projection metadata decoding, context-only versus persisted truncation, within-budget output, and disclosure after conversation metadata reload.
- Run focused checks during implementation, then the workspace PR gates after the three tasks stabilize.
