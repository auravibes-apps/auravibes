# AuraVibes Engine Agent Instructions
<!-- Managed by agent: AuraVibes | Last updated: 2026-09-11 -->

## Scope

- Applies to `packages/auravibes_engine`.
- Load `.agents/skills/package-architecture/SKILL.md` for package boundary, public API, placement, or architecture changes. Routine edits within an established package can follow nearby code and these scoped rules.
- Keep this package pure Dart: no Flutter, Riverpod, Drift, app imports, UI imports, or localization.

## Boundaries

- Engine owns app-neutral agent, tool, skill, provider-protocol, Genkit provider, and sub-agent primitives.
- App-specific persistence, permissions, credentials, localization, Riverpod wiring, and UI state stay in `apps/auravibes_app` adapters.
- Export supported public API from `lib/auravibes_engine.dart`; keep internal helpers under `lib/src/`.
- Do not add unique engine architecture rules here; update the root skill instead.

## Verification

- Prefer focused package tests in `packages/auravibes_engine/test`.
- Focused test, from this package: `fvm dart test test/path/to/file_test.dart`.
- For broad package boundary changes, run `fvm dart run melos run validate:quick` from repo root.
