---
name: ux-task-audit
description: Use automatically for review-only AuraVibes UI/UX critiques, including ugly or unbalanced screens, weak hierarchy, inconsistent typography/spacing, clutter, confusing navigation, or task friction. Give specific evidence and rationale. Use ux-view-clarity for UI implementation. Skip accessibility-only and non-UI reviews.
---

# AuraVibes task-flow audit

Audit how well an existing AuraVibes experience helps a person complete a task. Follow the user's goal from entry through completion, including the view changes, decisions, system states, and recovery along the way. Ground the task in [target users](../../../docs/product/target-users.md); use the relevant sections of [interaction rules](../ux-view-clarity/references/interaction-rules.md) for navigation, control placement, forms, density, and adaptive behavior. A single-screen critique can stay scoped to that screen and its entry/exit; it need not become an app-wide audit.

For appearance, balance, hierarchy, typography, or polish critiques, read [visual design rules](../ux-view-clarity/references/visual-design-rules.md). Tie each finding to a visible relationship and its effect: competing emphasis, ambiguous groups, broken alignment, weak readability, or inconsistent states. “Looks generic” and “not premium” are not actionable findings. A visual-only review does not need a full journey map; trace behavior only where the finding depends on it.

Do not exempt an existing Aura component or identity rule from critique. When it causes the problem, propose the smallest shared-UI or identity improvement, explain affected consumers and trade-offs, and give a verification scenario. Use Apple Settings and Linear only for the calibrated qualities described in [reference calibration](../ux-view-clarity/references/visual-design-rules.md#reference-calibration-and-system-improvements); do not prescribe a copied brand or new app-wide aesthetic for a local finding.

## Audit procedure

1. State the user goal, context, and success result. Separate supplied facts, observed evidence, and assumptions.
2. Inspect the current flow. Use current screenshots or a running product when available; use routes, code, and tests to understand behavior that cannot be observed. Do not present source inspection as proof of user behavior.
3. Map the normal route and relevant alternatives from entry to result. Record each view, decision, required information, action, transition, and recovery point.
4. Look for unclear purpose or next step; unnecessary or repeated decisions; information split across views when it must be compared; unrelated tasks crowded together; avoidable navigation or backtracking; unexplained states or consequences; terminology users may not recognize; and AI capability, status, permission, or correction that users cannot understand.
   Check whether a screen change uses the real route/shell rather than a second state-owned screen stack. Check whether creation/configuration displaces the main content, commands have a clear current target, and creation reveals its result. Check predictable item actions, selection-mode entry/exit and bulk scope, control prominence, menu discoverability, form grouping, and context across layout transitions. Apply the task-specific exceptions in the interaction rules: many controls alone are not evidence of poor UX, and hiding frequent actions can make it worse.
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

For skill maintenance, use [Markdown review scenarios](../ux-view-clarity/references/review-scenarios.md). For an audit followed by requested changes, hand findings to [ux-view-clarity](../ux-view-clarity/SKILL.md); do not run two duplicate audits.
