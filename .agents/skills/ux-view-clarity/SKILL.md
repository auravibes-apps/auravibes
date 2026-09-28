---
name: ux-view-clarity
description: Use for every AuraVibes user-visible UI edit, including screen, dialog, form, navigation, copy, state, layout, or shared-component changes. Check task clarity for small edits and write a view/flow brief for new or reworked experiences. For standalone evaluation of an existing flow, use ux-task-audit instead. Skip non-UI and accessibility-only work.
---

# AuraVibes UX view clarity

Use this skill only when the request includes changing the experience a user sees. Keep the reasoning about goals, information, choices, view boundaries, states, and recovery independent of Dart, Flutter, and component libraries. For a standalone evaluation of an existing task journey, use [`ux-task-audit`](../ux-task-audit/SKILL.md); for an accessibility-only review, use accessibility guidance.

## Choose the depth

For a local change such as spacing, a label, or a state message:

1. Identify the task and state affected from the request or nearby product context.
2. Check that the change keeps the purpose, next action, and result understandable. Check that it does not hide needed information, change a consequence, or break an existing recovery path.
3. Continue with the requested scope. If no task-level issue appears, do not produce a full audit or redesign.

For a new view or a substantial change to a task path, write a short view/flow brief before implementation:

- User goal, starting context, and observable completion result.
- Each proposed view's purpose, essential information, main action, and how the user knows what happened.
- Why related information and decisions stay together or move to another view. Consider whether any choice can be deferred or removed without hiding information needed for a safe decision.
- Relevant waiting, empty, error, partial, success, permission, and recovery states.
- A realistic scenario that could show whether the task is clear.

Treat missing user evidence as an assumption or question. Do not invent a persona, behavior, or requirement. Fewer views is not automatically simpler; preserve context when users need to compare or use information together.

Do not replace app architecture, visual design, or accessibility guidance with this skill.
