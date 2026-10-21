---
name: ux-view-clarity
description: Use for new views, changed task flows, or visual regression work. Skip local spacing/copy edits, non-UI work, and standalone audits; use ux-task-audit for audits.
---

# AuraVibes UX view clarity

Use this skill only when the request includes changing the experience a user sees. Keep the reasoning about goals, information, choices, view boundaries, states, and recovery independent of Dart, Flutter, and component libraries. For a standalone evaluation of an existing task journey, use [`ux-task-audit`](../ux-task-audit/SKILL.md); for an accessibility-only review, use accessibility guidance.

## Choose the depth

Local spacing, labels, and state messages do not require loading this skill. Apply this brief check directly:

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

## Responsive and foldable screens

For an all-screen responsive pass, inspect the current route matrix and the shared widgets, sheets, and dialogs used by those routes before changing individual screens. Use each view's available constraints rather than device labels or orientation. Check the compact and expanded navigation states, content bounds after side insets, keyboard-visible height, and whether long content can scroll to every action.

Keep the screen surface full bleed when needed; apply safe insets to interactive content at the app layer and only on the affected edges. Check light and dark themes for readable text, controls, system indicators, focus, and selection. Size dialogs and sheets from their available parent constraints, not the full window when they live in a narrower pane.

Use deterministic route captures for each requested posture and theme, then inspect the captures for clipping, lost actions, and inconsistent alignment. Add native fold-region handling only after live-device evidence shows an occlusion that layout constraints and safe insets do not expose.

For screenshot golden tests, capture each baseline on the same Flutter renderer and OS that will run it. If verified rasterization differences remain between platforms, keep platform-specific baselines and verify each on its target platform; do not replace one platform's image with another's.

Do not replace app architecture, visual design, or accessibility guidance with this skill.
