---
name: ux-task-audit
description: Use when asked to audit or simplify AuraVibes UX, when a flow has too many views or unclear next steps, or when an existing task journey needs evaluation. Trace the task across current views and report evidence-backed findings and testable simplifications. Skip visual-only and accessibility-only critiques.
---

# AuraVibes task-flow audit

Audit how well an existing AuraVibes experience helps a person complete a task. Follow the user's goal from entry through completion, including the view changes, decisions, system states, and recovery along the way. This is a product-level review, independent of Dart, Flutter, and component libraries.

## Audit procedure

1. State the user goal, context, and success result. Separate supplied facts, observed evidence, and assumptions.
2. Inspect the current flow. Use current screenshots or a running product when available; use routes, code, and tests to understand behavior that cannot be observed. Do not present source inspection as proof of user behavior.
3. Map the normal route and relevant alternatives from entry to result. Record each view, decision, required information, action, transition, and recovery point.
4. Look for unclear purpose or next step; unnecessary or repeated decisions; information split across views when it must be compared; unrelated tasks crowded together; avoidable navigation or backtracking; unexplained states or consequences; terminology users may not recognize; and AI capability, status, permission, or correction that users cannot understand.
5. Consider keep together, split, merge, defer, remove, or clarify. Explain why the leading change fits the task. Do not optimize for the fewest screens, shortest path, or visual emptiness alone.
6. Give each recommendation a realistic scenario and observable result that could confirm or reject it. If users were not observed, call the result a heuristic or code-based assessment and name the validation gap.

## Finding format

Report findings in priority order. For each include:

- Task step and current view/state.
- Evidence and its source: observed product, screenshot, code/test, user report, analytics, or hypothesis.
- User problem and likely task impact.
- Severity: **critical** if the task is blocked or a consequential wrong action is likely; **high** if a core task is likely to fail or need costly recovery; **medium** if users face avoidable confusion or effort with a workaround; **low** if impact is limited.
- Confidence: **high** for directly observed behavior or repeated user evidence; **medium** for clear product evidence without user observation; **low** for an untested inference.
- Specific proposed change, what necessary context or control it preserves, and a verification scenario.

Do not invent users, behavior, severity, frequency, or analytics. A screenshot supports claims about visible content only. Do not claim accessibility conformance from visual review. Use accessibility guidance for a dedicated accessibility audit, and do not implement changes unless the user requested implementation.
