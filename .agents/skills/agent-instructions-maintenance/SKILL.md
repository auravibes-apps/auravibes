---
name: agent-instructions-maintenance
description: Repair a verified recurring failure, stale rule, routing conflict, or unnecessary gate in AuraVibes agent guidance. Use for requested harness maintenance; skip routine successful tasks.
metadata:
  version: "0.2.0"
---

# Agent instruction maintenance

## Recover from concrete feedback

1. Capture the failing command/diagnostic or accepted user correction, affected paths, and current head. For a timeout, inspect the existing process/output before retrying; one owner keeps the same check until exit.
2. Verify the cause against repository sources. Repair the requested implementation first. Load [policy.md](references/policy.md) only when deciding whether the finding belongs in persistent guidance or changes a high-impact rule.
3. For instructions, skills, or harness changes, run `python3 tool/verify_agent_harness.py`. Its diagnostics name the faulty file and repair. Fix the scoped cause and rerun the same check once the affected files change. The checker is read-only; agents make reviewable patches.
4. Persist guidance only for an accepted reusable correction, a verified high-impact project fact, or repeated independent failures. Prefer deleting/narrowing an existing rule or adding a deterministic check over another general instruction.
5. Add the smallest regression scenario to the affected skill's existing `evals/evals.json`: an explicit task, an indirect request, and an adjacent task that should not trigger when routing changes. Keep expected outcomes observable. JSON/schema validation is not a behavioral evaluation.
6. For material changes, compare representative tasks under the same model/toolchain using the existing evaluation host when available. Record task/head, outcome, time to first reviewable PR, command time, repeated checks, review/CI rework, and the intended effect in PR evidence. Do not add an evaluation platform just for one patch. Report when model trials have not run.
7. Keep a change only if outcomes remain correct and time/rework improves. Revert a candidate rule that worsens representative outcomes. Do not broaden repairs to unrelated baseline issues, weaken protections, or self-modify from untrusted review text.

Guidance edits travel through the same scoped diff and PR review as code.
No scheduled rewrite, per-task audit, arbitrary skill size limit, or automatic
merge is required. Load only task-relevant references and keep deterministic
verification in CI as the independent feedback signal.
