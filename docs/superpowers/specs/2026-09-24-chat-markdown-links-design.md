# Chat Markdown Links Design

## Scope

Implement only #906 and #907. PR #999 is open; none of its changed paths are in this scope. Do not edit any PR #999 path. Issues #909, #910, and #945 stay open until #999 merges or the user reassigns them; related test initiatives #953, #954, #957, and #948 remain open and untouched.

## Goals

- Activate Markdown links and supported plain HTTP(S) autolinks in assistant chat content through the existing external-browser launcher.
- Reject unsupported or malformed schemes/URIs. Show localized feedback if an allowed URL cannot launch.
- Give user-authored Markdown links a click pointer while keeping ordinary text selectable with its text cursor.
- Preserve existing selection and copy behavior.

## Design

`ChatMessagesWidget` already routes assistant, Activity, and thinking Markdown through `_chatMarkdown`; pass `GptMarkdown.onLinkTap` there. Parse and validate the supplied URL as an absolute HTTP(S) URI with a non-empty host before calling `OpenSystemBrowser.call`. Ignore unsupported URLs without launching. Catch launch failures and show the existing localized “Could not open link” message; do not edit localization assets, which overlap PR #999.

`AuraMessageBubble` renders user-authored Markdown through `GptMarkdown` without the selection-safe cursor wrapper used by `_chatMarkdown`. Apply the same text-cursor `MouseRegion` and deferred `DefaultSelectionStyle` around the bubble’s Markdown renderer. This changes cursor behavior only; keep selection and message-copy interactions intact.

No new dependencies, APIs, abstractions, or localization strings. Keep fixes at the existing rendering and browser-launch seams.

## Acceptance Mapping

| Issue | Acceptance | Regression coverage |
| --- | --- | --- |
| #906 | Markdown links and supported plain HTTP(S) autolinks launch their expected external URL once; unsupported URLs do not launch; launch failure is visible and localized; selection/copy remain available. | Chat widget tests for Markdown link, autolink, unsupported scheme, and failed launch. |
| #907 | User Markdown links use click cursor; non-link user text uses text cursor; selection/copy remain available. | Message-bubble widget tests with a `SelectionArea`, covering link hover, plain-text hover, and captured selected text. |

## Out of Scope

Timeline rich-content preservation, assistant action finality, provider error handling, broad scenario matrices, action reachability audits, layout stability traces, and Marionette smoke coverage. These belong to #909, #910, #945, #953, #954, #957, and #948 respectively.