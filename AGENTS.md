# AuraVibes Agent Instructions
<!-- Managed by agent: AuraVibes | Last updated: 2026-10-20 -->

AuraVibes is an AI-powered Flutter app for conversations, agents, and workspace management across mobile, desktop, and web.

## Entrypoint

- Agents run from repo root. Treat this file as the required entrypoint.
- Nested `AGENTS.md` files are package-local hints, not architecture canon.
- Check `git status --short` before and after edits.
- Do not revert unrelated changes.
- Precedence: closest `AGENTS.md` to changed file wins; root rules apply otherwise.
- Before returning a local file link, resolve its path from the current workspace and verify the target exists.

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

## Product context

- For product ideation, feature discovery, or user-facing UX changes, read [target users](docs/product/target-users.md) for intended users and product direction.

## Commands

| Task                    | Command                                                                      |
| ----------------------- | ---------------------------------------------------------------------------- |
| Worktree setup          | `fvm use "$(python3 -c 'import json; print(json.load(open(".fvmrc"))["flutter"])')" --skip-pub-get`, then `python3 tool/validation_lease.py -- fvm dart run melos bootstrap` |
| Workspace bootstrap     | `python3 tool/validation_lease.py -- fvm dart run melos bootstrap` |
| App/UI focused test     | `python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" -- fvm flutter test test/path/to/file_test.dart --no-pub` from target package |
| App fatal analyzer      | `python3 tool/validation_lease.py -- fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine` |
| Local server integration | `fvm dart run melos run test:integration` (entrypoint owns the lease; no outer lease) |
| Engine focused test     | `python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" -- fvm dart test test/path/to/file_test.dart` from `packages/auravibes_engine` |
| Changed Dart preflight  | `python3 tool/validation_lease.py -- fvm dart run melos run validate:changed` |
| Changed-file local preflight | `python3 tool/validation_lease.py -- fvm dart run melos run preflight:changed` |
| Validation              | `python3 tool/validation_lease.py -- fvm dart run melos run validate:quick` (same form for `validate` and `validate:ci`) |
| Asset/clean scripts     | `python3 tool/validation_lease.py -- fvm dart run melos run generate:icons` (same form for `clean` and `generate:flavors`) |
| Code generation         | `python3 tool/validation_lease.py -- fvm dart run melos run generate` (same form for `generate:localization` and `generate:serverpod`) |
| Generated drift check    | `python3 tool/validation_lease.py -- fvm dart run melos run validate:generated` (clean worktree) |

- Script definitions and package filters live in root `pubspec.yaml`.
- For a new checkout or worktree, use the `fvm use` command above, then bootstrap before running `--no-pub` checks.
- Run local test, analyzer, code generation, bootstrap, and workspace validation commands through `tool/validation_lease.py`. Use the table’s self-leasing form for local server integration. From a package directory, use its absolute path via `$(git rev-parse --show-toplevel)`.
- The lease serializes validation only within the current worktree. Other worktrees and clones run independently. `python3 tool/agent_worktree.py status` reports worktrees and the current worktree's active lease owner.
- Temp-volume stats are advisory; quotas and container limits may still reject writes.

## Git context

- For routine context, use `git status --short --branch` and `git log -1 --oneline --decorate`; inspect named refs only when the task needs them.
- Before claiming a ticket or creating a worktree, run `python3 tool/agent_worktree.py preflight --issue <number>`; stop on reported conflicts until ownership is clear.
- Avoid `git branch -avv` for routine context; linked worktrees and remote refs can produce large output.

## DCL and lint compliance

- `analysis_options.yaml` is source of truth for Dart analyzer, DCL diagnostics and metrics, Riverpod lints, and scoped exceptions.
- For DCL checks, ignores, or architecture-boundary changes, read [DCL and lint rules](docs/agents/task-policies.md#dcl-and-lint-rules).

## Operations

- For `.fvmrc` changes, FVM drift, or CI failure triage, read [CI failure triage](docs/agents/operations.md#ci-failure-triage).
- For PR-check monitoring, read [PR check monitoring](docs/agents/operations.md#pr-check-monitoring).
- For GitHub CLI PR merges, follow [PR merge preflight](docs/agents/operations.md#github-cli-merge-preflight).
- For release tags or Codemagic build triage, read [Codemagic release triage](docs/agents/operations.md#codemagic-release-triage).
- For scoped database queries or native Flutter driver control, read the relevant section of [operations.md](docs/agents/operations.md).

## Verification

- Run the smallest scope-appropriate check with pinned FVM through the validation lease.
- For Dart syntax checks, use `fvm dart analyze <path>` when generic syntax parsing reports unsupported language.
- For generator-input changes, follow the generated-artifact check in [validation policy](docs/agents/task-policies.md#validation).
- For scope-specific checks, read [validation policy](docs/agents/task-policies.md#validation).
- For GitHub CI coverage, read the [local CI parity matrix](docs/agents/ci-local-parity.md); `validate:ci` covers the Melos validation subset only.
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
- UI/UX is automatic: before implementing any user-visible surface in app, shared UI, or Widgetbook work, load `.agents/skills/ux-view-clarity/SKILL.md`, even when the request only names a feature and never says design or UX. Apply its visual-quality baseline; use its short path for local edits. No explicit skill invocation is needed. For review-only visual or task-flow critiques, load `.agents/skills/ux-task-audit/SKILL.md`; use both only for an audit followed by requested UI changes. Use Aura defaults, but propose shared-UI or identity improvements when they better serve the task; avoid marketing-site styling by default.
- UI automation: use only browser/desktop controls the user named or approved. If unavailable or unclear, ask or give manual steps instead of substituting another tool.
- Marionette app control: load `.agents/skills/marionette-mcp/SKILL.md` before Marionette launches, connections, interaction, logs, or multi-agent routing; MCP runs from the repository-root FVM command, CLI only when MCP is unavailable. Follow its [repeatable smoke runbook](./.agents/skills/marionette-mcp/SKILL.md#repeatable-agent-smoke-runbook) for isolated validation.
- Riverpod work: prefer `.agents/skills/flutter-riverpod-expert/` over generic Flutter guidance.
- Localization: for translation keys or localization behavior, load `.agents/skills/localization/SKILL.md`.
- Melos configuration, bootstrap, or version troubleshooting: read `.agents/skills/melos-7/SKILL.md`; ordinary documented script runs need no skill load.
- Version conflicts: trust `.fvmrc` and package `pubspec.yaml` over skill examples.

## PR Gates

- PR titles use Conventional Commits. Keep each PR to one coherent change with its related tests; describe purpose, behavior, validation, and requested reviewer focus.
- Local review is the default. A request to review code before creating a Draft PR does not authorize sending code to a third-party reviewer; follow [PR delivery and review](docs/agents/operations.md#pr-delivery-and-review) before any external review.
- Use each contributor's configured tools and workflow for PR delivery and review. Do not install tools or prepare a full local environment solely for these tasks.
- Local commits do not publish changes and need no separate user authorization; `git push` and `gh pr merge` require explicit user authorization.
- If a requested Codex review rejects its configured model as unsupported, retry once with a model supported by the current host. Report a blocker if none is available.
- Before pushing code changes for review, run the smallest scope-appropriate local checks from the validation policy. Report checks that ran and any gaps. GitHub's required checks remain mandatory.

## Agent skills

- Issues/specs: GitHub issues in `auravibes-apps/auravibes` via `gh`; see `docs/agents/issue-tracker.md`.
- Triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`; see `docs/agents/triage-labels.md`. Domain docs: root `CONTEXT-MAP.md`, per-context `CONTEXT.md`, system-wide `docs/adr/`, and context-specific ADRs; see `docs/agents/domain.md`.

## Harness feedback

- For instruction, skill, or harness changes, follow [agent-instructions-maintenance](.agents/skills/agent-instructions-maintenance/SKILL.md).
