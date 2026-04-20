---
name: review-pr
description: Review and fix GitHub PR feedback from bots or humans, including CodeRabbit threads, review summaries, and plain PR comments
version: 0.2.0
triggers:
  - review.?pr
  - pr.?review
  - fix.?pr.?review
  - fix.?review.?comments?
  - resolve.?pr.?comments?
  - review.?comments?
  - coderabbit.?autofix
  - coderabbit.?auto.?fix
  - autofix.?coderabbit
  - coderabbit.?fix
  - fix.?coderabbit
  - coderabbit.?review
  - review.?coderabbit
  - coderabbit.?issues?
  - show.?coderabbit
  - get.?coderabbit
  - cr.?autofix
  - cr.?fix
  - cr.?review
---

# Review PR

Fetch and fix PR feedback for the current branch. Handle bot reviews, human reviews, CodeRabbit threads, review-summary comments, nitpicks, and internal comments left in regular PR comments.

## Prerequisites

### Required Tools

- `gh` (GitHub CLI) - [Installation guide](./github.md)
- `git`

Verify: `gh auth status`

### Required State

- Git repo on GitHub
- Current branch has open PR
- PR has review feedback in at least one GitHub surface: review threads, review bodies, PR comments, or standalone review comments

## Workflow

### Step 0: Load Repository Instructions (`AGENTS.md`)

Before any review-fix actions, search for `AGENTS.md` in the current repository and load applicable instructions.

- If found, follow its build/lint/test/commit guidance throughout the run.
- If not found, continue with default workflow.

### Step 1: Check Local and Push Status

Check: `git status` and whether current branch has unpushed commits.

**If uncommitted changes:**

- Warn: "⚠️ Uncommitted changes are not part of the pushed PR state"
- Ask whether to continue against current PR feedback or stop for user to commit first.

**If unpushed commits:**

- Warn: "⚠️ Current branch has unpushed commits. Existing PR feedback may not match local code"
- Ask whether to push first.
- If user pushes first, inform that fresh bot reviews may need a few minutes, then EXIT skill.

### Step 2: Find Open PR

```bash
gh pr list --head $(git branch --show-current) --state open --json number,title
```

**If no PR:** Ask whether to create one. If yes, create PR (see [github.md § 9](./github.md#9-create-pr-if-needed)), then inform user to rerun after reviewers respond.

### Step 3: Collect All Open Review Feedback

Gather feedback from all relevant GitHub sources, not only review threads.

**Pagination:** All four sources support pagination. Loop through all pages before filtering or normalizing — never stop at page 1. See [github.md § 2–5](./github.md#2-fetch-unresolved-review-threads) for the exact pagination loop per endpoint.

Collect:

- Unresolved review threads from `pullRequest.reviewThreads`
- Review bodies / review summaries from `gh api repos/{owner}/{repo}/pulls/{pr}/reviews`
- Standalone review comments from `gh api repos/{owner}/{repo}/pulls/{pr}/comments`
- Regular PR issue comments from `gh api repos/{owner}/{repo}/issues/{pr}/comments`

Include feedback from:

- CodeRabbit bots (`coderabbitai`, `coderabbit[bot]`, `coderabbitai[bot]`)
- Other bots
- Human reviewers

Treat as review items when comment text contains actionable feedback, including:

- bug reports
- requested changes
- nitpick / nit / nits
- internal review notes
- suggestions left in plain comments instead of code-review threads

Skip items that are clearly non-actionable, such as:

- approvals with no requested change
- pure acknowledgements
- resolved threads with no newer follow-up
- duplicate text already represented by a live thread item

If a bot review is still in progress, surface that explicitly and stop before applying fixes based on partial output.

### Step 4: Normalize Review Items

Convert all collected feedback into one ordered list.

For each item, capture:

1. Source: `thread`, `review`, `review-comment`, or `issue-comment`
2. Author: login and whether it is bot or human
3. Title/summary: use explicit title if present, else derive short summary from first actionable sentence
4. Location: file path and line numbers when available
5. Body: actionable request
6. Fix prompt:
   - Prefer CodeRabbit's `🤖 Prompt for AI Agents` block when present
   - Else use the actionable feedback text itself
7. Severity / priority:
   - security, crash, correctness, data loss -> CRITICAL
   - bug, regression, requested change -> HIGH
   - performance, maintainability, unclear behavior -> MEDIUM
   - nitpick, style, wording -> LOW

Deduplicate by comment/thread identity first, then by same location plus same requested change.

Keep original links or IDs for every item so the skill can reply later.

### Step 5: Present Findings

Display the normalized list in priority order, preserving source details.

Example:

```
PR Review Items for PR #123: [PR Title]

| # | Priority | Source | Author | Title | Location | Action |
|---|----------|--------|--------|-------|----------|--------|
| 1 | CRITICAL | thread | coderabbitai | Insecure auth check | src/auth/service.dart:42 | Fix |
| 2 | HIGH | review | teammate | Handle null API response | src/data/repo.dart | Fix |
| 3 | LOW | issue-comment | coderabbitai | Nit: rename helper for clarity | test/foo_test.dart:18 | Optional |
```

### Step 6: Ask User for Fix Preference

Use AskUserQuestion:

- `Review each issue` - manual review and approval
- `Auto-fix all` - apply all actionable items without per-item approval
- `Only high priority` - fix CRITICAL and HIGH only
- `Cancel` - exit

**Also ask:** commit strategy preference

- `Single commit` - one consolidated commit for all fixes (default)
- `Commit per fix` - individual commit for each applied fix

Record the choice to determine Step 9 behavior.

### Step 7: Manual Review Mode

For each selected item:

1. Read relevant files
2. Treat the normalized fix prompt as direct instruction
3. Prepare a minimal fix without applying yet
4. Show in one step:
   - title and source
   - author
   - location
   - exact fix prompt used
   - proposed diff
   - AskUserQuestion: `Apply fix` | `Defer` | `Skip`

If applied:

- Apply with local editing tools
- Track changed files and linked review item IDs for later replies

If deferred or skipped:

- Record reason if user provides one

### Step 8: Auto-Fix Mode

For each selected actionable item:

1. Read relevant files
2. Treat the normalized fix prompt as direct instruction
3. Apply minimal fix
4. Track changed files and linked review item IDs for later replies
5. Report fixed or skipped status

### Step 9: Create Commit(s)

Apply the commit strategy chosen in Step 6.

**If `Single commit` (default):**

```bash
git add <all-changed-files>
git commit -m "fix: address PR review feedback"
```

**If `Commit per fix`:**

For each applied fix (in order applied):

```bash
git add <files-for-this-fix>
git commit -m "fix: <brief description of this specific fix>"
```

Use repository instructions from `AGENTS.md` if they override the user's choice.

### Step 10: Run Validation Before Push

If fixes were applied:

- Offer to run repo-standard validation before push
- Follow `AGENTS.md` guidance if present
- Report failures clearly before asking to push

### Step 11: Push Changes

If a commit was created:

- Ask whether to push changes
- If user agrees, `git push`

If code was changed but not pushed, do not post review replies yet.

### Step 12: Reply After Push

After a successful push, comment back on the review items that were addressed.

Preferred behavior:

- For unresolved review threads: reply in thread with what changed, then resolve thread if appropriate
- For standalone review comments: reply to the comment when GitHub supports replies; otherwise include it in PR summary
- For review-summary bodies and issue comments: post a PR comment that references the addressed feedback and commit SHA

Reply content should include:

- short status: fixed / partially addressed / intentionally skipped
- commit SHA or pushed branch reference
- short note on what changed

Do this only after push so links and commit references point to final branch state.

### Step 13: Post PR Summary Comment

After push, post one summary comment to the PR with:

- count of addressed items
- count of skipped/deferred items
- files modified
- pushed commit SHA
- note that per-thread or per-comment follow-ups were posted where possible

See [github.md § 6](./github.md#6-post-summary-comment) for template details.

## Key Notes

- Do not limit analysis to CodeRabbit. Humans and other bots count too.
- Do not limit analysis to code-review threads. Plain PR comments and review bodies count too.
- Nitpicks and internal review notes are valid review items when actionable.
- Prefer the smallest fix that satisfies the comment.
- Preserve links or IDs for every review item so replies can be posted after push.
- Post replies after push, not before.
