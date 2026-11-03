# Issue #1439: Make historical A2UI surfaces visibly read-only

## Goal

Make a historical A2UI surface clearly recognizable as read-only to sighted and screen-reader users, while keeping current actionable surfaces interactive and ensuring historical actions cannot execute.

## Current behavior and scope

`ChatA2uiHistoricalSurface` already wraps each GenUI `Surface` in `AuraInteractionPolicy.readOnly()`, disables its ticker, and supplies `ReadOnlyChatA2uiActionDelegate`, whose handler consumes events without dispatching them. `ChatA2uiSurfaceHost` separately renders live/current surfaces. The visible historical surface has no read-only status, so disabled controls can look broken. Keep the existing policy and delegate as the behavior boundary; this change adds an explicit status in the historical host only. Do not change parsing, diagnostics, live runtime, or external-link/navigation behavior.

## Implementation

1. Add a compact Aura status badge with a lock icon and localized “Read only” text directly before each successfully rendered historical `Surface`. This keeps the explanation adjacent to the unavailable controls and avoids announcing one status for a whole message containing multiple independent surfaces. Exclude the decorative icon from semantics and give the badge a localized semantic label/header. Use existing Aura spacing, color, and badge components.
2. Add matching English and Spanish catalog keys, resolve the generated `LocaleKeys` key through `chatA2uiText` for a readable fallback, and generate `locale_keys.dart` through the repository generator in hosted CI. Never edit generated localization output by hand.
3. Leave the `AuraInteractionPolicy.readOnly`, `TickerMode(enabled: false)`, and no-op `ReadOnlyChatA2uiActionDelegate` intact. Preserve current/live surface behavior and A2UI local navigation.

## Tests

Add focused widget coverage in the app package for:

- visible and semantic read-only status in English and Spanish;
- status placement for each historical surface when a message contains more than one surface;
- the historical surface retaining its action-consuming delegate and read-only slider behavior, with the current equivalent still interactive;
- existing malformed/rootless history diagnostics remaining unchanged.

Retain and extend the existing read-only slider coverage if it is the narrowest proof that value changes remain blocked. Prefer observable control state and action effects over inspecting implementation-only wrappers.

## Before/after evidence

Create a deterministic fixture that renders two historical progress summary surfaces from one message at a fixed viewport, locale, theme, text scale, and Flutter renderer. A temporary push-triggered hosted workflow captures both the exact base revision (`46065bc5983bc9dc9100696aaa3c98ba66c7c56b`) and the feature head with the same fixture, and uploads the generated locale-key file for review. The baseline run uses the fixture from the feature checkout but the base app sources, so it asserts the absent status before and present status after. Record source SHA, renderer, Flutter version, viewport, locale, text scale, theme, and fixture description in JSON sidecars. Put the resulting PNGs and sidecars under `docs/evidence/issue-1439/` in the PR, with a short explanation of what changed. Remove the temporary workflow after capturing and checking the evidence. This is hosted-only because the pinned local Flutter target/validation lease is unavailable.

## Validation and review

Run the focused widget tests, formatter, localization audit/code generation, and repository-required checks through hosted CI. Do not delete caches or bypass the validation lease. Review the full diff against the approved scope, check the badge’s order/spacing and the en/es captures, and verify the `current` surface test still proves interaction. If screenshot runtime is unavailable, report that gap rather than claiming visual verification.

## Self-review

- Scope is limited to the historical renderer and localized status; the current runtime, parser, and diagnostics are untouched.
- Read-only semantics already exist in Aura policy and the no-op delegate, so the plan preserves them instead of duplicating safety logic in the UI.
- A per-surface marker remains visible next to controls even when one message contains multiple A2UI surfaces; a message-level banner could become separated from a later surface during scrolling.
- English and Spanish parity and generated output are explicit acceptance checks.
- The evidence plan compares identical fixtures and records source provenance; capturing only the feature revision would not substantiate the before/after claim.
- Local validation is intentionally omitted while the lease and pinned SDK are blocked; hosted CI remains the verification path.
