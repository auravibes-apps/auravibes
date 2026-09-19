---
name: pr-delivery
description: Prepare, push, create, and maintain AuraVibes pull requests through a green GitHub result. Use whenever the user asks to push a branch, open or update a PR, wait for GitHub checks, fix CI failures, resolve merge conflicts, or clear Sonar findings. Inspect the repository workflows and changed paths before choosing local checks, then keep following the same PR until its checks finish, its current head passes, and GitHub reports no merge conflict.
version: 0.1.0
triggers:
  - push.?changes?
  - push.?branch
  - create.?pr
  - pull.?request
  - open.?pr
  - update.?pr
  - prepare.?pr
  - pr.?checks?
  - ci.?checks?
  - monitor.?pr
  - wait.?for.?checks?
  - fix.?ci
  - fix.?workflow
  - fix.?sonar
  - merge.?conflicts?
  - sonar.?issues?
  - sonar.?findings?
  - get.?pr.?green
---

# PR delivery

Complete the current delivery request with a branch whose latest pull request
head has finished GitHub validation. Do not merge the pull request unless the
user asks for that separately.

## Read existing rules first

Before editing, committing, or pushing:

1. Read `AGENTS.md` and every closer `AGENTS.md` that applies to changed
   files. It owns AuraVibes safety rules, commands, package scope, generated
   files, validation gates, and commit conventions.
2. Read every current `.yml` and `.yaml` file in `.github/workflows`. Follow
   local composite actions and reusable workflows referenced by them. The
   workflows own the check list and path conditions.
3. Use `.agents/skills/review-pr/SKILL.md` and its `github.md` for existing PR
   lookup, creation syntax, and human or bot review comments. This skill adds
   the delivery loop; it does not copy those instructions.

Do not keep a second list of CI commands in this skill. Derive the list from
the workflow files on every invocation so workflow changes take effect without
editing this skill.

## Local preflight

1. Confirm repository root, worktree status, current branch, latest commit,
   remotes, GitHub authentication, and repository default branch. Use the
   read-only commands already documented by `AGENTS.md` and `review-pr`.
2. If `git branch --show-current` is empty, do not block. Derive a short
   descriptive branch name from the delivery request and changed files, then
   create it from the current `HEAD` with `git switch -c <type>/<summary>`
   before continuing. Use `fix/`, `feat/`, `chore/`, or `docs/` as appropriate.
   If the current branch has a name, keep it. Stop on a protected integration
   branch, missing `gh` auth, or a mixed worktree that contains unrelated user
   changes. Preserve those changes. Never rewrite history or force-push.
3. Find the open PR for the current branch. If none exists, check for a closed
   or merged PR before creating another one. Do not create a duplicate without
   the user's decision.
4. Resolve the PR base branch, or the repository default branch when no PR
   exists. Fetch it, retain its SHA, and compare it with `HEAD`. Include the
   exact base-to-head changed paths in the check plan.
5. If the branch is behind its base and the request authorizes a complete PR
   delivery, merge the fetched base branch before local validation. Resolve
   conflicts, commit the merge, and continue. Use merge rather than rebase.
   If the request only asks for inspection, report the divergence before any
   write.

## Derive and run local checks

Build a short plan by reading the applicable workflow jobs:

- Match workflow events, target branches, path filters, job `if` expressions,
  matrix inputs, `needs`, and intentional skips against the changed paths.
- Run each applicable local `run` block with its workflow working directory and
  environment. Use the project wrappers required by `AGENTS.md`. For behavior
  changes, start with the smallest focused tests covering the changed files or
  behavior; do not run the full test suite as the initial preflight. Reserve a
  full suite for an explicit request, a workflow that requires it, or a broad
  change where no meaningful focused check exists.
- For documentation, skill, workflow, or other configuration-only changes that
  do not alter runtime behavior, skip tests. Run the relevant syntax, schema,
  workflow, or diff checks instead. Do not silently replace missing focused
  coverage with a full suite; report the validation gap.
- For a local composite or reusable workflow, read it and include its commands.
  For hosted actions, secrets, external services, or unavailable operating
  systems, mark the check remote-only instead of inventing a local substitute.
- Run independent local gates when practical even after one failure. Collect
  the full local failure set, fix causes, then run the complete applicable plan
  again before delivery.
- Treat a failed, timed-out, or unavailable relevant local gate as blocked. Do
  not create or update a PR until the user explicitly accepts that blocker.
  Missing Docker, PostgreSQL, or other test infrastructure is not a pass.
- After generation or formatting, inspect the worktree. Follow `AGENTS.md` and
  the workflow for generated artifacts. Never hand-edit generated output to
  hide drift.

Finish local validation with the repository's documented status and diff
checks. If intended work remains, stage and commit it using explicit file
paths only; never use `git add .`, `git add -A`, or `git add --all`. Use the
required Conventional Commit form from `AGENTS.md`. Leave unrelated changes
unstaged.

## Push and create or update the PR

Perform remote writes only when the current request authorizes delivery.

1. Recheck the intended diff, branch, base SHA, and local validation result.
2. Use the existing push and PR creation commands from
   `.agents/skills/review-pr/github.md`. Push the current branch, then verify
   that the remote branch SHA equals local `HEAD`.
3. If no open PR exists, create one against the resolved base with the required
   title and a body containing the change summary, local commands, and known
   remote-only checks. Do not claim that checks passed before monitoring them.
4. Keep the PR number, URL, and pushed head SHA. All later queries must target
   that PR and its current head.

## Wait for the complete GitHub result

After creation or every push, wait for all checks. Do not stop at the first
failure and do not use fail-fast mode.

```bash
gh pr checks "$pr" --watch --interval 15
gh pr checks "$pr" --json name,workflow,state,bucket,link
gh pr view "$pr" --json \
  number,url,baseRefName,headRefName,headRefOid,mergeable,mergeStateStatus,statusCheckRollup
```

Pending, failed, cancelled, absent expected checks, and unresolved merge state
are not complete. A summary job does not replace the individual check rows.
Intentional non-required skips are acceptable only when the workflow explains
them. If a watch exceeds the current shell wait, poll in bounded intervals and
continue the task or use a quiet follow-up when the user requested monitoring
beyond the current turn.

Before fixing anything, compare `headRefOid` with the SHA that was pushed. A
dependency bot, workflow, or another user may have added a commit. Discard
stale conclusions, inspect the new diff, and wait for the new head.

### Verify Sonar findings separately

A successful `SonarCloud Code Analysis` check or `Quality Gate passed` message
does not prove that the PR has no live Sonar issues. After the checks finish and
the PR head matches the pushed SHA:

1. Find the Sonar check's `link` with `gh pr checks "$pr" --json name,link`.
   Treat a missing link as unverified unless the workflow explicitly explains
   why Sonar is not expected for these paths.
2. Read the Sonar project key (`id`) and PR number (`pullRequest`) from the
   linked dashboard URL. Query SonarCloud's PR-scoped issues endpoint with
   `resolved=false` and paginate until its reported total is covered. Use an
   existing `SONAR_TOKEN` only when the project requires authentication; never
   print it.

   ```bash
   curl --fail --silent --show-error --get \
     --data-urlencode "componentKeys=$sonar_project" \
     --data-urlencode "pullRequest=$pr" \
     --data-urlencode "resolved=false" \
     --data-urlencode "ps=100" \
     'https://sonarcloud.io/api/issues/search'
   ```
3. A non-zero unresolved issue count is a delivery blocker, even when the
   quality gate is green. Record each issue's key, severity, type, component,
   line, and message, then fix it or report it as a blocker. A failed,
   inaccessible, stale, or skipped Sonar analysis is unverified, not green.

This independent issue query is required because Sonar can pass its configured
quality gate while the PR still lists new issues.

For every failed check, read the complete failed-step log with `gh run view
<run-id> --log-failed` or follow the check link when it is external. Collect all
failures from the finished run before applying fixes, unless a cancelled or
stuck run requires immediate recovery.

Use the actual job and log to choose the fix:

- Fix code, test, formatting, analysis, dependency, generation, or platform
  failures in the repository and rerun their workflow commands locally.
- For Sonar, inspect the reported issue and quality-gate output, then run the
  PR-scoped unresolved-issue query above. Fix every returned issue. A scan
  skipped for a fork or missing token is unverified, even if its parent job
  passed. Do not lower the quality gate or suppress an issue to hide it.
- For `DIRTY` or `CONFLICTING` merge state, fetch the PR base, merge it into the
  branch, resolve the conflict, rerun local gates, commit, push, and restart
  the full wait. Do not rebase or force-push.
- For review comments, use `review-pr` instead of adding another review parser
  here.
- For a clear transient hosted failure with no repository cause, rerun failed
  jobs once. Inspect the new run. Do not retry a reproducible failure forever.
- For review, permission, branch-protection, or unavailable-infrastructure
  blockers, report the exact required action and stop.

After each fix cycle, rerun the applicable local plan, commit named files,
push, verify the new remote SHA, and return to the complete wait. Never report
success after a local fix but before the new GitHub checks finish.

## Completion test

Report a green PR only when:

- the worktree has no unintended changes or generated drift;
- local `HEAD`, the remote branch, and the PR `headRefOid` match;
- every expected check for that head finished successfully, with only
  workflow-explained non-required skips;
- Sonar's current PR analysis was independently queried for unresolved issues
  and returned zero, or Sonar was explicitly workflow-explained as not
  applicable for the changed paths;
- no check is pending, failed, or cancelled; and
- GitHub reports `mergeable: MERGEABLE` and `mergeStateStatus: CLEAN`.

Report the PR URL, head SHA, check results, merge state, local blockers, and
remote-only or skipped checks separately. Do not call a planned, stale, or
partially verified result complete.
