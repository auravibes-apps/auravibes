# Agent Validation Speed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver three independent PRs that reduce wasted agent time through portable validation ownership, observable Melos phases, and faster AuraVibes Pi worker defaults.

**Architecture:** Each PR owns one file and one concern. Worktrunk creates independent worktrees from `origin/main`; Herdr hosts one Pi writer in each workspace. No PR depends on another.

**Tech Stack:** Markdown, Melos 8 YAML, Pi project JSON, Worktrunk, Herdr, GitHub CLI.

## Global Constraints

- Base every branch on `origin/main`.
- Keep PRs independent and free of unrelated changes.
- Add no dependencies or harness wrappers.
- Preserve validation command order and coverage.
- Use focused config/document checks; do not run Dart suites for docs/config-only changes.
- Push branches and open ready PRs with Conventional Commit titles.

---

### Task 1: Portable Agent Validation Policy

**Files:**
- Modify: `AGENTS.md:33-53`
- Include existing: `docs/superpowers/specs/2026-08-10-agent-validation-speed-design.md`
- Include existing: `docs/superpowers/plans/2026-08-10-agent-validation-speed.md`

**Interfaces:**
- Consumes: existing verification table and project command rules.
- Produces: product-neutral delegated-work rules usable by Codex, OpenCode, Pi, and similar agents.

- [ ] **Step 1: Confirm isolated branch state**

Run: `git status --short && git merge-base --is-ancestor origin/main HEAD`

Expected: only design/plan docs are committed; command exits 0.

- [ ] **Step 2: Add delegated-work rules under Verification**

Add concise bullets requiring one validation owner, smallest proving check, one final broad gate, no duplicate command without relevant changes, long-command announcement, timed handoff evidence, immediate blocker reporting, and state inspection before replacement. Do not use Pi-specific tool names.

- [ ] **Step 3: Review policy portability**

Run: `grep -nE 'fleet|contact_supervisor|subagent_wait|needsAttentionAfterMs' AGENTS.md`

Expected: no matches in new policy.

- [ ] **Step 4: Validate documentation diff**

Run: `git diff --check && git diff -- AGENTS.md docs/superpowers/specs/2026-08-10-agent-validation-speed-design.md docs/superpowers/plans/2026-08-10-agent-validation-speed.md`

Expected: no whitespace errors; diff contains only intended docs.

- [ ] **Step 5: Commit, push, and open PR**

```bash
git add AGENTS.md docs/superpowers/specs/2026-08-10-agent-validation-speed-design.md docs/superpowers/plans/2026-08-10-agent-validation-speed.md
git commit -m "docs(agents): define efficient delegated validation"
git push -u origin docs/agent-validation-policy
gh pr create --base main --head docs/agent-validation-policy --title "docs(agents): Define efficient delegated validation" --body $'## Summary\n- define portable validation ownership and delegation rules\n- document three-PR speed design and plan\n\n## Validation\n- `git diff --check`'
```

Expected: ready PR URL returned.

---

### Task 2: Observable Melos Validation Steps

**Files:**
- Modify: `pubspec.yaml:171-196`

**Interfaces:**
- Consumes: existing `analyze`, `unused:*`, `format:check`, `test:local`, and `test:ci` scripts.
- Produces: `validate`, `validate:ci`, and `validate:quick` with unchanged commands/order represented as Melos `steps`.

- [ ] **Step 1: Confirm isolated branch state**

Run: `git status --short && git rev-parse --abbrev-ref HEAD`

Expected: clean branch `chore/observable-validation-steps`.

- [ ] **Step 2: Convert validation chains to native steps**

Use these exact ordered entries:

```yaml
validate:
  steps:
    - melos analyze
    - melos run unused:files
    - melos run unused:code
    - melos run unnecessary:nullable
    - melos run format:check
    - melos run test:local

validate:ci:
  steps:
    - melos analyze
    - melos run unused:files
    - melos run unused:code
    - melos run unnecessary:nullable
    - melos run format:check
    - melos run test:ci

validate:quick:
  steps:
    - dart analyze --fatal-infos --fatal-warnings
    - dart format --line-length 80 -o none --set-exit-if-changed .
```

Retain existing descriptions.

- [ ] **Step 3: Validate YAML and Melos discovery**

Run: `fvm dart run melos list >/dev/null && fvm dart run melos run --list --json > /tmp/auravibes-melos-scripts.json && grep -E '\"validate(:ci|:quick)?\"' /tmp/auravibes-melos-scripts.json`

Expected: YAML loads and output lists `validate`, `validate:ci`, and `validate:quick`; do not select or execute broad validation.

- [ ] **Step 4: Review semantic diff**

Run: `git diff --check && git diff -- pubspec.yaml`

Expected: only representation changes; command strings and ordering match previous pipeline.

- [ ] **Step 5: Commit, push, and open PR**

```bash
git add pubspec.yaml
git commit -m "chore(tooling): expose validation pipeline steps"
git push -u origin chore/observable-validation-steps
gh pr create --base main --head chore/observable-validation-steps --title "chore(tooling): Expose validation pipeline steps" --body $'## Summary\n- expose each validation phase through Melos native steps\n- preserve command order and fail-fast behavior\n\n## Validation\n- `fvm dart run melos list`\n- `fvm dart run melos run --list --json`\n- `git diff --check`'
```

Expected: ready PR URL returned.

---

### Task 3: AuraVibes Pi Worker Defaults

**Files:**
- Modify: `.pi/settings.json:1-5`

**Interfaces:**
- Consumes: existing Pi package list and builtin `worker` agent.
- Produces: project-scoped `subagents.defaultThinking` and `agentOverrides.worker` configuration.

- [ ] **Step 1: Confirm isolated branch state**

Run: `git status --short && git rev-parse --abbrev-ref HEAD`

Expected: clean branch `chore/pi-worker-speed`.

- [ ] **Step 2: Extend Pi settings without removing packages**

Keep `npm:@narumitw/pi-lsp`. Add:

```json
"subagents": {
  "defaultThinking": "medium",
  "agentOverrides": {
    "worker": {
      "thinking": "medium",
      "defaultContext": "fresh",
      "systemPromptMode": "append",
      "systemPrompt": "For AuraVibes implementation tasks, require a complete task contract with goal, target seam, approved decisions, success criteria, validation owner, and expected output. Run only focused validation assigned to this worker; do not run broad validation unless explicitly assigned. Before a command expected to run longer than two minutes, report the exact command and expected duration. Escalate decision blockers immediately instead of guessing."
    }
  }
}
```

- [ ] **Step 3: Validate JSON**

Run: `python3 -m json.tool .pi/settings.json >/dev/null`

Expected: exits 0.

- [ ] **Step 4: Inspect resolved worker**

Run from Pi parent: `subagent({ action: "get", agent: "worker" })`.

Expected: project worker reports `thinking: medium`, `default context: fresh`, appended project prompt, and existing tool allowlist.

- [ ] **Step 5: Review diff**

Run: `git diff --check && git diff -- .pi/settings.json`

Expected: only Pi project settings changed; package entry preserved.

- [ ] **Step 6: Commit, push, and open PR**

```bash
git add .pi/settings.json
git commit -m "chore(pi): optimize worker delegation defaults"
git push -u origin chore/pi-worker-speed
gh pr create --base main --head chore/pi-worker-speed --title "chore(pi): Optimize worker delegation defaults" --body $'## Summary\n- use fresh context and medium thinking for AuraVibes Pi workers\n- append focused validation and blocker-escalation guidance\n\n## Validation\n- `python3 -m json.tool .pi/settings.json`\n- resolved worker config inspection\n- `git diff --check`'
```

Expected: ready PR URL returned.

---

## Parent Verification

- [ ] Confirm all three PRs target `main` and are not drafts.
- [ ] Confirm each PR diff contains only its declared files.
- [ ] Confirm each branch reports focused check results and residual risks.
- [ ] Confirm no branch includes dirty files from `llm-cache`.
