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

Reply in-thread, then optionally resolve.

**Reply to a thread:**

```bash
gh api graphql \
  -F body='Fixed in <commit-sha>. Updated <short description of change>.' \
  -F threadId='<reviewThread.id>' \
  -f query='mutation($body:String!, $threadId:ID!) {
    addPullRequestReviewThreadReply(input:{body:$body, pullRequestReviewThreadId:$threadId}) {
      comment { databaseId }
    }
  }'
```

**Resolve a thread after reply:**

```bash
gh api graphql \
  -F threadId='<reviewThread.id>' \
  -f query='mutation($threadId:ID!) {
    resolveReviewThread(input:{threadId:$threadId}) {
      thread { isResolved }
    }
  }'
```

Only resolve after the fix is pushed. Do not resolve threads that were only partially addressed.

### 8. Reply To Review Comment (inline, not in thread)

For standalone review comments that are not part of a thread, use the REST endpoint with `in_reply_to`:

```bash
gh api repos/{owner}/{repo}/pulls/<pr-number>/comments \
  -X POST \
  -f body='Fixed in <commit-sha>. Updated <short description of change>.' \
  -f in_reply_to=<comment-id>
```

### 9. Reply To Issue Comment (PR comment)

Regular PR comments do not support threaded replies. Post a new PR comment that references the original comment:

```bash
gh pr comment <pr-number> --body "$(cat <<'EOF'
Re: @<author> — Fixed in <commit-sha>.
Updated <short description of change>.
EOF
)"
```

### 10. React To Or Acknowledge Comment

```bash
# React with thumbs up to a review comment
gh api repos/{owner}/{repo}/pulls/comments/<comment-id>/reactions \
  -X POST \
  -f content='+1'
```

Optional. Do not use reaction as the only acknowledgement when a textual reply is needed.

### 11. Create PR (if needed)

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
