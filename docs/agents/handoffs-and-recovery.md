# Handoffs and recovery

Use for parallel feature work, credential/access review, or interrupted validation.

## Dispatch and handoff

Before dispatch, assign each shared editor, repository, or contract to one worker.
Serialize overlapping edits; independent work can continue. Transfer ownership
with the receiving commit and pending checks, rather than only a ticket number.

Keep the parent progress document as an index, not a transcript. Keep one
compact checkpoint per active worker and replace superseded status at each
milestone. Summarize completed checks and link detailed output. Update before
handoff or context loss:

- Owner, worktree, branch, integration base, completed commit, owned/shared paths.
- Acceptance criteria completed and pending, including provisional integration.
- For active or pending checks, exact command, working directory, revision,
  output path, and process/session handle.
- Baseline failure evidence, blockers, next action, and superseded decisions.

At each workstream boundary, collect one status with owner, worktree, branch,
commit, completed and pending checks, blockers, and next action. Inspect the
current process or output before retrying a check. Avoid duplicate status
requests while worker state has not changed.

For broad handwritten feature changes, include scoped DCL results before a
readiness handoff. Reuse the configured `dcl:analyze` command and CI parity
matrix; use its same failure threshold when checking only affected paths.
Focused fixes retain the scope-appropriate checks in the validation policy.
A focused analyzer pass does not establish DCL or generated-drift success.

## Review transitions

For credential/access changes, reviewers trace affected callers through applicable
migration, failed-write, concurrent-replacement, grant/revocation, membership
removal/rejoin, receipt-replay, and stream paths. Require deterministic
regressions for changed behavior; extend existing suites instead of duplicating
in-flight fixes. Report uncovered transitions as acceptance gaps.

## Recover evidence

Inspect recorded processes, sessions, and complete output before replacing work
or starting another check. Running jobs remain owned by their original check.
Missing exit evidence means incomplete, even if an output tail appears green.
Changes after a check require rerunning only the affected verification scope.

Reuse a recorded golden-baseline comparison while its source paths, snapshots,
toolchain, and rendering environment remain applicable. Cite the baseline SHA
and exact differences. Repeat comparison when those inputs change. A matching
baseline explains an existing failure; it does not make that check pass.

Automatic validation receipts are deferred. The lease replaces itself with its
child; adding a supervisor requires separate signal and lock-lifetime testing.
