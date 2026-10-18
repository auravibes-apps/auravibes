# AuraVibes Agent Instructions
<!-- Managed by agent: AuraVibes | Last updated: 2026-10-18 -->

AuraVibes is an AI-powered Flutter app for conversations, agents, and workspace management across mobile, desktop, and web.

## Entrypoint

- Agents run from repo root. Treat this file as the required entrypoint.
- Nested `AGENTS.md` files are package-local hints, not architecture canon.
- Check `git status --short` before and after edits.
- Do not revert unrelated changes.
- Precedence: closest `AGENTS.md` to changed file wins; root rules apply otherwise.

## Index of scoped AGENTS.md

- App: [apps/auravibes_app/AGENTS.md](./apps/auravibes_app/AGENTS.md)
- Engine: [packages/auravibes_engine/AGENTS.md](./packages/auravibes_engine/AGENTS.md)
- UI: [packages/auravibes_ui/AGENTS.md](./packages/auravibes_ui/AGENTS.md)
- Widgetbook: [widgetbook/AGENTS.md](./widgetbook/AGENTS.md)

## Workspace source of truth

- Dart SDK and Melos versions: root `pubspec.yaml`; Flutter version: `.fvmrc`.
- Commands and package membership live in root `pubspec.yaml`.
- Diagnostics and scoped exceptions live in `analysis_options.yaml`.
- Required CI gates live in `.github/workflows/ci.yml`.
- Canonical architecture docs live under `doc/architecture/`.

## Commands

| Task                    | Command                                                                      |
| ----------------------- | ---------------------------------------------------------------------------- |
| Workspace bootstrap     | `fvm dart run melos bootstrap`                                               |
| App/UI focused test     | `fvm flutter test test/path/to/file_test.dart --no-pub` from target package  |
| App fatal analyzer      | `fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine` |
| Engine focused test     | `fvm dart test test/path/to/file_test.dart` from `packages/auravibes_engine` |
| Validation              | Prefix `fvm dart run melos run`: `validate:quick` (quick), `validate` (full), `validate:ci` (CI with coverage) |
| Asset/clean scripts      | `fvm dart run melos run clean`, `fvm dart run melos run generate:flavors`, `fvm dart run melos run generate:icons` |
| Code generation         | Prefix `fvm dart run melos run`: `generate`, `generate:localization`, `generate:serverpod` |

## DCL and lint compliance

- `analysis_options.yaml` is source of truth for Dart analyzer, DCL diagnostics and metrics, Riverpod lints, and scoped exceptions.
- For DCL checks, ignores, or architecture-boundary changes, read [DCL and lint rules](docs/agents/task-policies.md#dcl-and-lint-rules).

## Operations

- For `.fvmrc` changes, FVM drift, or CI failure triage, read [CI failure triage](docs/agents/operations.md#ci-failure-triage).
- For scoped database queries or native Flutter driver control, read the relevant section of [operations.md](docs/agents/operations.md).

## Verification

- Run the smallest scope-appropriate check with pinned FVM. Use `fvm dart run melos run <script>` for root scripts.
- For generated source changes, run the relevant generator and inspect its output.
- For scope-specific checks, read [validation policy](docs/agents/task-policies.md#validation).
- If a check cannot run, say why and name the next command.

## Analyzer-only migrations

- For provider scope or dependency cleanup, follow [analyzer-only migration rules](docs/agents/task-policies.md#analyzer-only-migrations).

## Project Rules

- Add dependencies with `fvm flutter pub add ...` from the target package. Never use `any` constraints.
- Do not hand-edit generated files: `*.g.dart`, `*.freezed.dart`, `locale_keys.dart`, plugin registrants, or Drift worker output.
- For app localization, user-facing errors, model changes, Drift schemas, or Freezed 4 rules, read [model and Drift rules](docs/agents/task-policies.md#model-and-drift-rules).

## Architecture

- Load `.agents/skills/app-architecture/SKILL.md` when changing app layer placement, ownership, dependency direction, or architecture; routine edits within an established feature do not need the full skill.
- Load `.agents/skills/package-architecture/SKILL.md` when changing package boundaries, public APIs, package placement, or architecture; routine edits within an established package do not need the full skill.
- Keep durable architecture docs under `doc/architecture/`; update them only when package boundaries, layer rules, or file placement rules change.

## Skill routing
- When verified feedback exposes a reusable guidance gap, use `.agents/skills/agent-instructions-maintenance/SKILL.md` before changing instructions, skills, or harness checks. Routine tasks need no guidance audit.
- UX clarity: for new views, changed task flows, or visual regression work, load `.agents/skills/ux-view-clarity/SKILL.md`; for an existing-flow audit, load `.agents/skills/ux-task-audit/SKILL.md`. For local spacing or copy edits, check purpose, next action, recovery, and localization directly without loading a flow skill.
- Marionette app control: load `.agents/skills/marionette-mcp/SKILL.md` before Marionette launches, connections, interaction, logs, or multi-agent routing; MCP runs from the repository-root FVM command, CLI only when MCP is unavailable. Follow its [repeatable smoke runbook](./.agents/skills/marionette-mcp/SKILL.md#repeatable-agent-smoke-runbook) for isolated validation.
- Riverpod work: prefer `.agents/skills/flutter-riverpod-expert/` over generic Flutter guidance.
- Localization: for translation keys or localization behavior, load `.agents/skills/localization/SKILL.md`.
- Melos configuration, bootstrap, or version troubleshooting: read `.agents/skills/melos-7/SKILL.md`; ordinary documented script runs need no skill load.
- Version conflicts: trust `.fvmrc` and package `pubspec.yaml` over skill examples.

## PR Gates

- For PR creation or updates, follow [PR delivery](.agents/skills/pr-delivery/SKILL.md).
- For code PR local checks, read [PR local checks](docs/agents/task-policies.md#pr-local-checks).

## Agent skills

- Issues/specs: GitHub issues in `auravibes-apps/auravibes` via `gh`; see `docs/agents/issue-tracker.md`.
- Triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`; see `docs/agents/triage-labels.md`. Domain docs: root `CONTEXT-MAP.md`, per-context `CONTEXT.md`, system-wide `docs/adr/`, and context-specific ADRs; see `docs/agents/domain.md`.

## Harness feedback

- For instruction, skill, or harness changes, follow [agent-instructions-maintenance](.agents/skills/agent-instructions-maintenance/SKILL.md).
