# Required-check and CI repair loop

Load when asked to wait for checks, fix CI, or make a PR green.

After creation or every push, inspect current-head checks and review state
immediately. Poll bounded status snapshots while working on useful local
diagnosis; do not wait idle for the full matrix.

If a required workflow has no run for the exact PR head, inspect its trigger,
branch filters, and path conditions in the trusted workflow. When the workflow
supports `workflow_dispatch` and the user requested CI verification, dispatch
it against the PR branch and confirm the run's commit SHA. Do not count a run
for an older or unrelated head as validation.

```bash
gh pr checks "$pr" --json name,workflow,state,bucket,link
gh pr view "$pr" --json \
  number,url,baseRefName,headRefName,headRefOid,mergeable,mergeStateStatus,statusCheckRollup,reviewDecision
```

Pending, failed, or cancelled required checks are not complete. A summary job
does not replace individual check rows. Accept intentional skips only when the
workflow explains them and they are not required. Surface a missing required
review as soon as `reviewDecision` shows it; do not wait for CI to finish before
reporting the human approval needed.

When a required check fails while other jobs are pending, verify its run and
`headRefOid`, read the complete failed-job log, and inspect failures already
reported. Start local diagnosis and run only the focused reproducer while other
jobs continue. For test-shard failures, inspect the job summary and the
`test-plan` or `test-report-*` artifacts when available; use their selected
paths, shard, and command to reproduce only the failing tests.

Before pushing a repair, snapshot the checks for that head and group every
currently reported failure by root cause. Record the check, job, head SHA,
evidence, and proposed repair; fix all confirmed causes already surfaced in
one batch instead of committing separately for each symptom. Keep monitoring
when another pending check could expose a distinct cause.

If the root cause is clear and the focused check passes, push the repair without
waiting for unrelated pending jobs when the workflow cancels in-progress PR
runs; this starts checks for the fixed head sooner. Include other failures
already surfaced in the same push. If the failure is ambiguous, likely transient,
or pending checks may reveal a distinct cause, keep monitoring until those useful
results arrive. After any push, verify the new head SHA and track all required
checks for that head to completion. Stale or cancelled runs do not establish
success.

For failures, inventory distinct failure classes as they appear and inspect
complete logs for each failed job; do not download every log blindly. Check
whether a cancelled run was superseded by a newer run for the current head.
Use the job and log to choose the response:

- For code, test, formatting, analysis, dependency, generation, or platform
  failures, fix the cause and follow the focused iteration and final gates
  above. A blocked local command stays blocked; do not replace it with a
  larger unrelated suite.
- For a clear transient hosted failure with no repository cause, rerun the
  failed job once and inspect the new run.
- For `DIRTY` or `CONFLICTING`, fetch and merge the PR base, resolve conflicts,
  run applicable gates, commit, push, verify the new SHA, and restart the wait.
- For review comments, use `review-pr`. For review, permission,
  branch-protection, or unavailable-infrastructure blockers, report the exact
  required action.

After each fix, rerun applicable checks, commit named files, push, verify the
new remote SHA, and monitor all required checks for that head. Never report
success after a local fix but before current-head GitHub checks finish.

## Sonar (conditional)

Handle Sonar when it is a required check for this PR, the user asks for Sonar
review, or Sonar findings are explicitly in scope. A green quality gate means
the configured gate passed; it does not prove there are zero unresolved
issues. When issue review is in scope, inspect current PR analysis separately:

1. Find the Sonar check link with `gh pr checks "$pr" --json name,link`. If
   Sonar is required and the link or current analysis is missing, stale, failed,
   or inaccessible, report that required check as blocked/unverified. If Sonar
   is optional and out of scope, missing data is not a CI failure.
2. Read the Sonar project key (`id`) and PR number (`pullRequest`) from the
   linked dashboard URL. Query PR-scoped unresolved issues and paginate until
   the reported total is covered. Use an existing `SONAR_TOKEN` only if
   authentication is required; never print it.

   ```bash
   curl --fail --silent --show-error --get \
     --data-urlencode "componentKeys=$sonar_project" \
     --data-urlencode "pullRequest=$pr" \
     --data-urlencode "resolved=false" \
     --data-urlencode "ps=100" \
     'https://sonarcloud.io/api/issues/search'
   ```
3. If zero unresolved issues is an explicit requirement, report each scoped
   finding and resolve it or report it as a blocker. Do not lower the quality
   gate or suppress a finding to hide it. A green gate and an issue review are
   separate results.

## Completion report

Report these states separately:

- **Checks:** all required checks for the current PR head finished successfully,
  with only explained non-required skips; list optional or blocked checks
  separately.
- **Mergeability:** report GitHub's `mergeable` and `mergeStateStatus`. Clean
  merge state does not prove branch protection is satisfied.
- **Review and protection:** report required approval/review status and any
  other branch-protection requirement separately. A PR with green checks may
  still need approval or another required action; do not call it fully ready
  until those requirements are satisfied.
- **Source state:** confirm local `HEAD`, remote branch, and PR `headRefOid`
  match, and that intended changes have no unintended worktree or generated
  drift.
- **Sonar:** include gate and unresolved-issue results only when Sonar is
  required, requested, or explicitly in scope. Do not treat missing optional
  Sonar data as failed CI.

Include PR URL, head SHA, check results, merge state, review/protection state,
and local or remote-only blockers. Distinguish complete checks from full
branch-protection readiness. Do not describe a planned, stale, or partially
verified result as complete.

After an authorized merge, verify intended closing references actually closed their issues. If not, inspect the repository auto-close setting; do not close partially addressed issues.
