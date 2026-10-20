# AuraVibes Agent Instructions
<!-- Managed by agent: AuraVibes | Last updated: 2026-10-19 -->

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

- Script definitions and package filters live in root `pubspec.yaml`.
- Wrap local test, analyzer, code generation, bootstrap, and workspace validation commands with:
  `python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" -- <command>`.
- The lease coordinates linked worktrees that share this repository's Git common directory. Commands started outside the wrapper bypass it; CI runners remain independent.
- Temp-volume stats are advisory; quotas and container limits may still reject writes.

## DCL and lint compliance

- `analysis_options.yaml` is source of truth for Dart analyzer, DCL diagnostics and metrics, Riverpod lints, and scoped exceptions.
- For DCL checks, ignores, or architecture-boundary changes, read [DCL and lint rules](docs/agents/task-policies.md#dcl-and-lint-rules).

## Operations

- For `.fvmrc` changes, FVM drift, or CI failure triage, read [CI failure triage](docs/agents/operations.md#ci-failure-triage).
- For PR-check monitoring, read [PR check monitoring](docs/agents/operations.md#pr-check-monitoring).
- For scoped database queries or native Flutter driver control, read the relevant section of [operations.md](docs/agents/operations.md).

## Verification

- Run the smallest scope-appropriate check with pinned FVM through the validation lease.
- For Dart syntax checks, use `fvm dart analyze <path>` when generic syntax parsing reports unsupported language.
- For generated source changes, run the relevant generator and inspect its output.
- For scope-specific checks, read [validation policy](docs/agents/task-policies.md#validation).
- For shared result or status contract changes, follow [behavior-path review](docs/agents/task-policies.md#behavior-path-review).
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
- UI automation: use only browser/desktop controls the user named or approved. If unavailable or unclear, ask or give manual steps instead of substituting another tool.
- Marionette app control: load `.agents/skills/marionette-mcp/SKILL.md` before Marionette launches, connections, interaction, logs, or multi-agent routing; MCP runs from the repository-root FVM command, CLI only when MCP is unavailable. Follow its [repeatable smoke runbook](./.agents/skills/marionette-mcp/SKILL.md#repeatable-agent-smoke-runbook) for isolated validation.
- Riverpod work: prefer `.agents/skills/flutter-riverpod-expert/` over generic Flutter guidance.
- Localization: for translation keys or localization behavior, load `.agents/skills/localization/SKILL.md`.
- Melos configuration, bootstrap, or version troubleshooting: read `.agents/skills/melos-7/SKILL.md`; ordinary documented script runs need no skill load.
- Version conflicts: trust `.fvmrc` and package `pubspec.yaml` over skill examples.

## PR Gates

- PR titles use Conventional Commits. Keep each PR to one coherent change with its related tests; describe purpose, behavior, validation, and requested reviewer focus.
- Use each contributor's configured tools and workflow for PR delivery and review. Do not install tools or prepare a full local environment solely for these tasks.
- PR creation adds no local validation gate. Report checks that ran and any gaps. GitHub's required checks remain mandatory.

## Agent skills

- Issues/specs: GitHub issues in `auravibes-apps/auravibes` via `gh`; see `docs/agents/issue-tracker.md`.
- Triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`; see `docs/agents/triage-labels.md`. Domain docs: root `CONTEXT-MAP.md`, per-context `CONTEXT.md`, system-wide `docs/adr/`, and context-specific ADRs; see `docs/agents/domain.md`.

## Harness feedback

- For instruction, skill, or harness changes, follow [agent-instructions-maintenance](.agents/skills/agent-instructions-maintenance/SKILL.md).
