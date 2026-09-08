# Agent Validation Speed Design

## Problem

AuraVibes agent runs spend most elapsed time in broad validation and opaque waits, not file inspection or editing. Recent evidence showed workspace analysis taking up to 891 seconds, `validate:quick` taking 193–536 seconds, and delegated waits lasting 8–20 minutes. Repeated broad checks and blocked delegation magnify this cost.

## Goals

- Keep guidance portable across Codex, OpenCode, Pi, and similar agents.
- Make broad validation phases visible without adding a validation framework.
- Make Pi implementation workers faster while preserving explicit validation and decision boundaries.
- Deliver three independent PRs based on `origin/main`.

## Non-goals

- Replace Melos, Dart analysis, Flutter tests, or CI.
- Add harness-specific wrappers for every agent product.
- Modify `pi-subagents` runtime behavior.
- Introduce hard tool, token, or turn budgets for mutation-capable workers.
- Optimize analyzer internals without profiling evidence beyond command duration.

## PR 1: Portable Agent Policy

Branch: `docs/agent-validation-policy`

Update root `AGENTS.md` with capability-neutral delegated-work rules:

- Assign one owner to each validation command.
- Prefer the smallest check that proves the change.
- Run broad validation once, after implementation stabilizes and only when scope requires it.
- Do not repeat a completed command unless relevant files or config changed.
- Announce long-running commands with exact command and expected duration.
- Include command, result, duration, and relevant failures in handoffs.
- Report decision blockers immediately.
- Inspect delegated work state before retrying or replacing it.

These rules avoid Pi-specific nouns such as `fleet`, `contact_supervisor`, and `subagent_wait` so other coding agents can follow them.

Validation: inspect Markdown diff and run `git diff --check`. No Dart suite.

## PR 2: Observable Melos Validation

Branch: `chore/observable-validation-steps`

Replace shell `&&` chains in `validate`, `validate:ci`, and `validate:quick` with Melos-native `steps`. Existing commands, order, and fail-fast behavior remain unchanged. Melos owns step display and failure attribution; no new script or dependency is added.

This PR improves accuracy when deciding which phase is slow. It does not claim to make Dart analysis itself faster.

Validation:

- Parse `pubspec.yaml` through repository tooling.
- List Melos scripts and confirm all three validation entries resolve.
- Run the smallest harmless command that proves step syntax; do not run full validation solely for this config change.

## PR 3: AuraVibes Pi Worker Defaults

Branch: `chore/pi-worker-speed`

Extend `.pi/settings.json` with project-scoped `subagents` settings:

- `defaultThinking: medium`.
- Override `worker` to use `thinking: medium` and `defaultContext: fresh`.
- Append a compact project prompt requiring a complete task contract, focused validation ownership, pre-announcement of long commands, and immediate blocker escalation.

Fresh context avoids sending large parent histories to implementation workers. Accuracy depends on parent prompts naming goal, target files or seam, approved decisions, success criteria, one validation owner, and output expectations. Existing package configuration remains intact.

Validation: parse JSON and inspect Pi agent resolution with read-only subagent management commands. No Dart suite.

## Delivery Flow

1. Worktrunk creates each branch and worktree from `origin/main`.
2. Herdr opens one workspace per existing Worktrunk worktree.
3. One Pi agent owns each workspace and PR.
4. Each agent edits only its PR scope, runs the specified focused checks, commits, pushes, and opens a ready PR with a Conventional Commit title.
5. Parent verifies branch state, diff, checks, and PR URL before reporting completion.

Parallel writers remain isolated because every PR has its own worktree. PRs are independent and may merge in any order.

## Failure Handling

- A child announcing a long command remains owner of that command until it exits or is explicitly stopped.
- A timeout is incomplete evidence, not permission to duplicate the command.
- Before replacement, inspect latest state and preserved output.
- If Pi fresh-context tasks lack required decisions or targets, worker escalates rather than guessing.
- If Melos `steps` changes command semantics, retain current shell chain and limit PR 2 to phase labels; behavior preservation wins.

## Success Criteria

- Three independent PRs exist against `main`.
- No PR introduces a dependency or harness wrapper.
- Root guidance remains product-neutral.
- Validation commands retain existing order and coverage.
- Pi worker resolves to fresh context and medium thinking in AuraVibes.
- Each PR has focused verification evidence and no unrelated changes.
