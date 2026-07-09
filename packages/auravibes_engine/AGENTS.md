# AuraVibes Engine Agent Instructions

## Scope

- Applies to `packages/auravibes_engine`.
- Root-run agents must load `.agents/skills/package-architecture/SKILL.md`; it is the package architecture source of truth.
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
