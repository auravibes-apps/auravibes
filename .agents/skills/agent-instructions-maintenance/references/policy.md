# Agent instruction maintenance

Keep agent guidance accurate, scoped, and worth the context it consumes. Treat `AGENTS.md` and skills as versioned project behavior: inspect evidence, make targeted changes, and remove rules when their source or value disappears.

## Task-time loop

1. Read root `AGENTS.md`, closer `AGENTS.md` files for the affected paths, and only the skills relevant to the task. Do not run a repository-wide guidance audit at the start of every task.
2. While doing the requested work, notice concrete friction: a wrong or stale instruction, a repeated detour, a conflict, a user or reviewer correction, or a project fact that could not be inferred and caused rework or risk.
3. Before finishing, classify each candidate using the evidence rules below. If the gap and its scope are clear, update the relevant guidance as part of the current work without waiting for the user to request that maintenance. If the evidence is uncertain or the change would alter security boundaries, permissions, destructive operations, or architecture policy, report the candidate instead of encoding a guess.
4. Summarize guidance changes with the observed evidence and the check performed. Keep unrelated implementation work moving; guidance maintenance should not become a general cleanup project.

## Evidence threshold

Promote a candidate when at least one condition holds:

- The user or an accepted review comment corrected an approach in a way that expresses reusable project intent.
- The same avoidable mistake or costly rediscovery occurred in two independent tasks. One occurrence is enough when it exposed a verified, non-obvious project fact with material correctness or safety impact.
- A source-of-truth change made existing guidance demonstrably stale.
- A model, agent host, or skill-loading change invalidates an assumption; reassess the affected rule instead of carrying it forward unchanged.
- A skill repeatedly fails to trigger when needed, triggers for adjacent work, or causes needless steps.

Do not promote a rule for a one-off transient failure, task-specific preference, unsupported inference, or information already clear in the codebase. Do not restate requirements already enforced reliably by CI, a linter, a type checker, or another executable guard; link to that enforcement when useful.

## Diagnose before editing

Identify which failure occurred:

- **Missing:** add the smallest actionable rule.
- **Stale:** correct or delete it after checking the source of truth.
- **Conflicting:** resolve the existing conflict and precedence; do not append another competing instruction.
- **Ignored:** check whether the rule is vague, buried, too broad, or attached to the wrong directory. Clarify, move, or enforce it instead of duplicating it.
- **Overly broad or redundant:** narrow it, merge it with the authoritative rule, or remove it.

The agent ignoring a rule does not by itself prove that more rules are needed. First check whether the instruction was discoverable, applicable, and consistent with higher-priority guidance.

Use task evidence as the maintenance signal. Do not schedule a broad rewrite just because time passed or a file is long. Revisit a rule when its source, model assumptions, trigger behavior, or observed outcomes change.

After model changes, distinguish **capability coaching** (steps the base model may no longer need) from **workflow preferences or policy** (the team's verified way of working). Retest the former; preserve the latter only while it still matches actual requirements.

Check for recurring instruction smells:

- **Context bloat:** low-value detail makes critical guidance harder to find.
- **Skill leakage:** rare, specialized workflow is always loaded instead of placed in a triggered skill.
- **Lint leakage:** prose repeats a reliable formatter, linter, analyzer, or CI check.
- **Blind reference:** a path is named without saying what it contains or when to read it.
- **Initialization fossilization:** generated starter instructions remain unreviewed as the project changes.
- **Conflicts:** multiple rules prescribe incompatible actions.

These are review prompts, not automatic failures. A line-count threshold is not a universal quality limit; confirm that content causes context cost, wrong behavior, or maintenance risk before pruning it.

## Choose the right home

| Guidance type | Put it here |
| --- | --- |
| Short rule that applies across the repository; command entry points; routing to authoritative sources | Root `AGENTS.md` |
| Rule that applies only to one package or directory | Closest scoped `AGENTS.md` |
| Repeated, narrow, multi-step workflow with a clear trigger, inputs, output, and checks | A triggered skill's `SKILL.md`; put long references or scripts beside it |
| Deterministic rule that can be checked mechanically | CI, analyzer, linter, test, or script; document how to run it |
| One-time task detail or speculative preference | Do not persist it |

Keep always-loaded guidance short. Prefer a pointer to the source of truth over copying information that will drift. Do not create a skill for a one-off fact or a generic instruction the agent can already follow. Use progressive disclosure: keep the skill description precise, load procedure only when relevant, and load references only as needed.

Make references conditional and descriptive (for example, “Read the migration guide when changing the schema”), not a mandatory reading list for every task. Skills can contain scripts and external resources, so inspect their side effects, dependencies, and network use before trusting or expanding them; use least privilege when execution is involved.

## Make the smallest useful edit

- Write reusable guidance in generic terms: state a clear trigger and action,
  plus the boundary or exception. Keep issue numbers, branch names,
  feature-only fixture IDs or keys, and one-off action sequences in tests, task
  documents, or PR evidence unless they are stable inputs to a repeated
  workflow.
- Prefer changing or deleting an existing rule over adding a parallel version.
- Verify repo-specific facts against their owner: package manifests, CI workflows, analyzer configuration, or architecture documents. Do not infer commands, versions, or policy from memory when the source is available.
- For unusual rules whose rationale is not obvious, preserve a short evidence pointer or reason so a future maintainer can decide whether it still applies. Keep history out of always-on instructions.
- For skills, make the description say when to trigger. Keep workflow details in the body and long material in referenced files. Use an existing scenario/evaluation convention when present; do not add a new framework just to test one small documentation edit.

## Verify and prune

After editing:

1. Check that the rule is in the narrowest correct file and does not duplicate or contradict a closer or higher-priority instruction.
2. Verify referenced paths, commands, versions, and policies against current repository sources.
3. For skill changes, confirm that the trigger matches the intended tasks and excludes nearby tasks that should not load it. Use existing evaluation cases when available and relevant.
4. Review the diff for accidental expansion, then run the applicable documentation checks. Do not run unrelated code suites for a documentation-only change.

For a material change to a reusable skill or high-impact rule, compare representative tasks before and after when the project has an evaluation path. Include a task that should trigger, a realistic indirect phrasing, and an adjacent task that should not trigger. Score task outcome and instruction-following; track extra steps, latency, or token cost when available. Repeat stochastic runs when the decision depends on a small difference. Keep small edits lightweight; do not add evaluation infrastructure for a one-off documentation fix.

For capability-coaching skills, compare against a no-skill baseline, especially after model upgrades. For workflow or preference skills, check whether the result still follows the team's verified process; model capability alone does not make a real policy obsolete.

During relevant work or a requested audit, remove rules whose source has changed, whose behavior is enforced elsewhere, or whose scope no longer exists. Do not use line count alone as a quality score: check whether instructions cause conflicts, unnecessary actions, wrong routing, or measurable task cost. If evaluation data exists, compare task success and quality alongside extra steps, runtime, or token use. Recheck guidance after meaningful model or harness upgrades because effective scaffolding can change; avoid assuming model-specific instructions transfer unchanged across agents.

## Research notes

Read [research.md](research.md) for the evidence behind these practices, study limitations, and source links. The snapshot was checked on 2026-09-26; refresh vendor guidance and research before making a material policy decision.
