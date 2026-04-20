# Git Platform Commands

GitHub CLI commands for the Review PR skill.

## Prerequisites

**GitHub CLI (`gh`):**

- Install: `brew install gh` or [cli.github.com](https://cli.github.com/)
- Authenticate: `gh auth login`
- Verify: `gh auth status`

## Core Operations

### 1. Find Pull Request

```bash
gh pr list --head $(git branch --show-current) --state open --json number,title
```

Gets the PR number for the current branch.

### 2. Fetch Unresolved Review Threads

Use GitHub GraphQL `reviewThreads`. Supports pagination via `pageInfo { hasNextPage, endCursor }`.

**Pagination strategy:**

Loop until `pageInfo.hasNextPage == false`, collecting all pages:

```bash
# Page 1
gh api graphql \
  -F owner='{owner}' \
  -F repo='{repo}' \
  -F pr=<pr-number> \
  -f query='query($owner:String!, $repo:String!, $pr:Int!) {
    repository(owner:$owner, name:$repo) {
      pullRequest(number:$pr) {
        reviewThreads(first:100) {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            isResolved
            path
            comments(first:100) {
              nodes {
                id
                databaseId
                body
                author { login }
                path
                position
              }
            }
          }
        }
      }
    }
  }'

# Subsequent pages: append after:$endCursor from previous response
gh api graphql \
  -F owner='{owner}' \
  -F repo='{repo}' \
  -F pr=<pr-number> \
  -f query='query($owner:String!, $repo:String!, $pr:Int!) {
    repository(owner:$owner, name:$repo) {
      pullRequest(number:$pr) {
        reviewThreads(first:100 after:"<endCursor>") {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            isResolved
            path
            comments(first:100) {
              nodes {
                id
                databaseId
                body
                author { login }
                path
                position
              }
            }
          }
        }
      }
    }
  }'
```

Filter criteria:

- `isResolved == false`
- root comment contains actionable review feedback

Use the root comment body plus reply context for the normalized review item.

### 3. Fetch Review Bodies / Summaries

```bash
gh api repos/{owner}/{repo}/pulls/<pr-number>/reviews?page=1&per_page=100
```

Supports pagination via `Link` header containing `next`, `prev`, `last` URLs.

**Pagination strategy:**

Loop while the `Link` response header contains `rel="next"`. Follow the `next` URL for each page until no `next` link remains.

Collect all pages before filtering. Use to collect:

- review state (`COMMENTED`, `CHANGES_REQUESTED`, `APPROVED`)
- review body text
- author login
- review ID for later referencing

Skip approvals without actionable text.

### 4. Fetch Standalone Review Comments

```bash
gh api repos/{owner}/{repo}/pulls/<pr-number>/comments?page=1&per_page=100
```

Supports pagination via `Link` header.

**Pagination strategy:** Same loop as § 3 — follow `next` until no `next` link remains.

Use to collect:

- file path and line metadata
- comment body
- author login
- comment ID

This catches comments that are not surfaced as unresolved threads in the workflow.

### 5. Fetch Regular PR Comments

```bash
gh api repos/{owner}/{repo}/issues/<pr-number>/comments?page=1&per_page=100
```

Supports pagination via `Link` header.

**Pagination strategy:** Same loop as § 3 — follow `next` until no `next` link remains.

Use to collect:

- nitpicks
- internal review notes
- bot review summaries
- plain-text follow-up requests

Treat only actionable comments as review items.

### 6. Post Summary Comment

```bash
gh pr comment <pr-number> --body "$(cat <<'EOF'
## Review Feedback Addressed

Addressed <issue-count> review item(s) across threads, reviews, and PR comments.

**Files modified:**
- `path/to/file-a.ts`
- `path/to/file-b.ts`

**Commit:** `<commit-sha>`

Replies were posted to review threads/comments where possible after push.

The latest changes are on the `<branch-name>` branch.

EOF
)"
```

Post after the push step (if pushing) so branch state is final.

### 7. Reply To Review Thread

Use GraphQL `addPullRequestReviewThreadReply` to reply in-thread when needed, then resolve with `resolveReviewThread` if appropriate.

Minimum reply body:

```text
Fixed in <commit-sha>.
Updated <short description of change>.
```

Only resolve after the fix is pushed.

### 8. React To Or Acknowledge Comment

```bash
# React with thumbs up to a review comment
gh api repos/{owner}/{repo}/pulls/comments/<comment-id>/reactions \
  -X POST \
  -f content='+1'
```

Optional. Do not use reaction as the only acknowledgement when a textual reply is needed.

### 9. Create PR (if needed)

```bash
gh pr create --title '<title>' --body '<body>'
```

## Error Handling

**Missing `gh` CLI:**

- Inform user and provide install instructions
- Exit skill

**API failures:**

- Log error and continue
- Don't abort entire fix workflow for reply/comment posting failures

**Getting repo info:**

```bash
gh repo view --json owner,name,nameWithOwner
```
