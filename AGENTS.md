# AuraVibes Agent Instructions
<!-- Managed by agent: AuraVibes | Last updated: 2026-10-01 -->

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

- Dart SDK: `^3.13.0`; Flutter: `.fvmrc` (`3.47.5`); Melos: `^8.7.0`.
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
| Validation              | Prefix `fvm dart run melos run`: `validate:quick` (quick), `validate` (full), `test:ci` (CI) |
| Asset/clean scripts      | `fvm dart run melos run clean`, `fvm dart run melos run generate:flavors`, `fvm dart run melos run generate:icons` |
| DCL metrics check       | `fvm dart run melos run dcl:analyze`                                         |
| Code generation         | Prefix `fvm dart run melos run`: `generate`, `generate:localization`, `generate:serverpod` |

## DCL and lint compliance

- `analysis_options.yaml` is source of truth for Dart analyzer, DCL diagnostics and metrics, Riverpod lints, and scoped exceptions. Consult the applicable rules before introducing a Dart pattern or resolving a lint; routine edits can reuse an established pattern and verify with the targeted analyzer.
- During iteration, run the smallest focused analyzer or test. Use `fvm dart run melos run analyze` for root Dart analysis, `fvm dart run melos run analyze:workspace` for built-in Melos workspace analysis, `fvm dart run melos run dcl:analyze` for DCL metrics, and `fvm dart run melos run validate:quick` for root analysis + format. Formatter runs are allowed; bare host `dart format` does not verify pinned-toolchain output.
- Run `dcl:analyze` when changing DCL or architecture boundaries, or when CI reports a relevant failure. Run full `validate` only when explicitly requested or when a multi-package behavior change needs full-workspace coverage beyond focused checks. Never run it solely because a PR is being opened or updated.
- CI also runs DCL unused-code, unused-file, and unnecessary-nullable checks. Remove orphaned declarations after refactors; do not hide findings with broad excludes or ignores.

## Operations

- For CI failure triage, scoped database queries, or native Flutter driver control, read the relevant section of [operations.md](docs/agents/operations.md).

## Verification

- Run the smallest focused check; invoke root scripts via `fvm dart run melos run <script>`. Quiet wrappers buffer child output until exit, print `Command succeeded.` on success, and replay both streams plus exit code on failure; keep tests/watch/start/fix/upgrade/result scripts visible.
- Assign one owner per validation command.
- Do not rerun completed checks or suites already covered by an aggregate gate unless relevant files or configuration changed.
- Announce commands expected to exceed two minutes with their purpose and expected duration.
- In handoffs, include each command, result, duration, and relevant failures.
- Report decision blockers immediately. Before retrying or replacing delegated work, inspect its current state and preserved output.

| Scope | Local validation |
| --- | --- |
| Focused file/bug | Focused test or analyzer; format changed Dart when relevant |
| Shared app logic/broad refactor | Focused tests and `validate:quick` once after stabilization |
| CI reproduction/explicit request | Requested CI command, such as `test:ci` |
| Documentation/skill-only | Relevant documentation checks and diff; no Dart suites |
| Workflow/config-only | Syntax/action checks for changed files; no unrelated Dart suites |

- When focused validation passes and a wider gate reports only unrelated diagnostics, report those diagnostics; do not escalate to broader local suites.
- A timeout or background job is incomplete: wait for its exit status; do not duplicate or retry it.
- Distinguish known baseline test failures from failures caused by the change.
- Before interpreting slow CI scope selection, verify CI head, base, and run attempt.
- Use `git diff --check` only for docs/patch-heavy edits, generated-code reviews, or final whitespace checks when relevant; do not run it in every code-edit loop.
- If verification cannot run, say why and name the next command to run.
- Generated-code changes require generator output review.

## Analyzer-only migrations

- For provider scope/dependency cleanup, fix every machine diagnostic including infos; run only the app fatal analyzer, not tests or broader gates.

## Project Rules

- Add dependencies with `fvm flutter pub add ...` from the target package; never use `any` constraints.
- Do not hand-edit generated files: `*.g.dart`, `*.freezed.dart`, `locale_keys.dart`, plugin registrants, Drift worker output.
- Drift schema changes require `schemaVersion` bump and migration logic.
- User-facing strings must be localized; user-facing errors use typed exceptions carrying localization keys.
- If `.fvmrc` changes, run `fvm use` and commit the resulting `.vscode/settings.json` sync.
- Freezed 4 classes must not declare abstract `hashCode`, `toString`, or `==`; those declarations suppress generated implementations. Run build runner after model changes and review generated output.
- DCL metric/rule ignores are allowed only for generated-backed Freezed declarations, Drift schema DSL, or symbols required by generated Drift output, with a reason; keep checks enabled for handwritten behavior.

## Architecture

- Load `.agents/skills/app-architecture/SKILL.md` when changing app layer placement, ownership, dependency direction, or architecture; routine edits within an established feature do not need the full skill.
- Load `.agents/skills/package-architecture/SKILL.md` when changing package boundaries, public APIs, package placement, or architecture; routine edits within an established package do not need the full skill.
- Keep durable architecture docs under `doc/architecture/`; update them only when package boundaries, layer rules, or file placement rules change.

## Skill routing
- When verified feedback exposes a reusable guidance gap, use `.agents/skills/agent-instructions-maintenance/SKILL.md` before changing instructions, skills, or harness checks. Routine tasks need no guidance audit.
- UX clarity: for new views, changed task flows, or visual regression work, load `.agents/skills/ux-view-clarity/SKILL.md`; for an existing-flow audit, load `.agents/skills/ux-task-audit/SKILL.md`. For local spacing or copy edits, check purpose, next action, recovery, and localization directly without loading a flow skill.
- Marionette app control: load `.agents/skills/marionette-mcp/SKILL.md` before Marionette launches, connections, interaction, logs, or multi-agent routing; MCP runs from the repository-root FVM command, CLI only when MCP is unavailable. Follow its [repeatable smoke runbook](./.agents/skills/marionette-mcp/SKILL.md#repeatable-agent-smoke-runbook) for isolated validation.
- Riverpod work: prefer `.agents/skills/flutter-riverpod-expert/` over generic Flutter guidance.
- Melos configuration, bootstrap, or version troubleshooting: read `.agents/skills/melos-7/SKILL.md`; ordinary documented script runs need no skill load.
- Version conflicts: trust `.fvmrc` and package `pubspec.yaml` over skill examples.

## PR Gates

- PR titles use Conventional Commits. Keep each PR to one coherent change with its related tests; describe purpose, behavior, validation, and requested reviewer focus.
- An authorized PR creation request completes after push, PR creation, and one current-head status snapshot. Wait for all checks or fix CI when requested; pending CI is reported as pending. Use `.agents/skills/pr-delivery/SKILL.md` for delivery.
- Before opening or updating a code PR, run only scope-appropriate local checks above. Full `validate`, `dependency_validator`, and `import_sorter` are not default local PR gates. Run dependency validation when dependency or package metadata changes, and import sorting when imports change. GitHub's required checks own repository-wide gates.

## Agent skills

- Issues/specs: GitHub issues in `auravibes-apps/auravibes` via `gh`; see `docs/agents/issue-tracker.md`.
- Triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`; see `docs/agents/triage-labels.md`. Domain docs: root `CONTEXT-MAP.md`, per-context `CONTEXT.md`, system-wide `docs/adr/`, and context-specific ADRs; see `docs/agents/domain.md`.

## Harness feedback

- For instruction, skill, or harness changes, run `python3 tool/verify_agent_harness.py`. Repair findings in the affected guidance and rerun that check.
- On a verified recurring failure, use the maintenance skill to fix its cause, add a regression scenario to the affected skill's `evals/evals.json`, and compare outcome, time, and rework. Do not turn every task into a harness audit.
