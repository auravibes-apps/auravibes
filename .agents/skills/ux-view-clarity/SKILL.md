---
name: ux-view-clarity
description: Use automatically before any AuraVibes UI implementation, including feature requests that create screens, forms, menus, navigation, widgets, or adaptive layouts without mentioning design. Covers visual hierarchy, typography, spacing, polish, and UI fixes. Use ux-task-audit for review-only work. Skip non-UI changes.
---

# AuraVibes UX view clarity

Use this skill when changing the experience a user sees in the app, shared UI package, or Widgetbook. Ground decisions in [target users](../../../docs/product/target-users.md) and the [product brief](../../../docs/product/product-brief.md): everyday people, clear language, useful outcomes, and advanced configuration when relevant. For a standalone evaluation, use [`ux-task-audit`](../ux-task-audit/SKILL.md); for an accessibility-only review, use accessibility guidance.

Do not wait for the user to request design, polish, or this skill by name. Creating or changing a visible surface is the trigger, including the UI portion of a larger feature. Keep UX reasoning and implementation in the same task; a local edit does not need a separate design approval or a second skill. Non-visual logic and pure harness/documentation maintenance do not trigger this skill merely because they mention UI.

Read the relevant [interaction rules](references/interaction-rules.md) when changing navigation, browsing/editing surfaces, creation, item actions, selection, forms, spacing, density, or adaptive behavior. They cover content-first opening states, contextual commands and minimal creation, predictable item actions, and selection-mode exceptions alongside existing routing and components. Do not substitute a web marketing layout, new design system, or animation library for established app patterns.

## Visual-quality baseline for every UI change

Make the screen feel composed as well as functional. Give each visual choice a task-based reason:

- Establish attention order: main task or result, needed context, then supporting actions. Reduce competing emphasis before enlarging the main element.
- Default browsing/work surfaces to content; expose creation and configuration on demand unless setup or data entry is the actual task. Make commands act in a clear context and reveal their result.
- Group by meaning: related content sits closer together; distinct sections have a clearer gap. Align shared text edges and repeated rows.
- Start with Aura typography, spacing, color, radius, and interaction tokens. Keep equivalent roles consistent across screens; propose a shared-system or identity improvement when existing choices demonstrably hinder the task.
- Keep body text, labels, errors, focus, and selected states legible. Create calmness with hierarchy and disclosure, not tiny text or faint controls.
- Use surfaces, icons, borders, and motion only when they clarify grouping, meaning, feedback, or continuity. Avoid adding decoration to fill available space.
- Adapt the composition to available space and input methods while preserving the task, current location, and state. A wide window is not permission to expose every setting.

For a new or recomposed surface, or changes to layout, typography, color, icons, surfaces, or visual polish, read [visual design rules](references/visual-design-rules.md). For a small change, read only its relevant section. For copy-only edits, the baseline and short path are enough. These rules explain the perceptual logic and the visible checks; do not replace them with an “award-winning designer” persona.

## Improve the system when needed

Existing components and identity are the starting point, not a reason to preserve a demonstrated UI/UX flaw. Improve local composition within the requested task. When a shared component causes the problem, inspect its consumers and fix the shared source if that belongs to the authorized task; avoid per-screen workarounds. Follow [package architecture](../package-architecture/SKILL.md) when public APIs or ownership change.

Propose UI-package, token, or identity changes when they would better serve the task. State the problem, why existing choices do not suffice, the smallest alternative, affected screens/themes/platforms, and how to verify it. Broader identity work remains a concrete proposal unless included in the requested scope; do not silently rebrand the app during a local fix.

Use Apple Settings to calibrate familiar forms/navigation and Linear to calibrate hierarchy and interaction care. Borrow those qualities, not their branding, exact layouts, or desktop density. AuraVibes remains an everyday-user product. See [reference calibration](references/visual-design-rules.md#reference-calibration-and-system-improvements).

## Choose the depth

For local spacing, labels, state messages, and routine component examples, use this short path without a full audit or flow brief:

1. Identify the task and state affected from the request or nearby product context.
2. Apply the visual-quality baseline to the affected region. Check purpose, next action, result, grouping, alignment, and interaction space. Preserve needed information, localization, consequences, accessible targets, and recovery. Read only the relevant reference sections.
3. Continue with the requested scope. If no task-level issue appears, do not produce a full audit or redesign.

For a new view or a substantial change to a task path, write a short view/flow brief before implementation:

- User goal, starting context, and observable completion result.
- Each proposed view's purpose, essential information, main action, and how the user knows what happened.
- Why related information and decisions stay together or move to another view. Consider whether any choice can be deferred or removed without hiding information needed for a safe decision.
- Navigation contract: destination versus local state, existing route/shell owner, entry, Back/close behavior, and relevant deep-link, refresh, or draft preservation behavior.
- Control hierarchy: what stays visible, what belongs in a labeled menu or disclosure, and why. Name the essential fields and the information intentionally deferred.
- Visual composition: attention order, content groups and alignment, existing type roles, emphasis, and compact/expanded arrangement. State only decisions that affect this task; do not create a new design system or a large design report.
- Relevant waiting, empty, error, partial, success, permission, and recovery states.
- A realistic scenario that could show whether the task is clear.

Treat missing user evidence as an assumption or question. Do not invent a persona, behavior, or requirement. Fewer views is not automatically simpler; preserve context when users need to compare or use information together.

Before implementation, inspect the target, callers, existing route pattern, shared components, and relevant tests. Reuse theme-owned spacing and house controls. Local state may expand content, change a filter, or edit a draft; it must not replace route navigation to an independent destination.

## Responsive and foldable screens

For an all-screen responsive pass, inspect the current route matrix and the shared widgets, sheets, and dialogs used by those routes before changing individual screens. Use each view's available constraints rather than device labels or orientation. Check the compact and expanded navigation states, content bounds after side insets, keyboard-visible height, and whether long content can scroll to every action.

Keep the screen surface full bleed when needed; apply safe insets to interactive content at the app layer and only on the affected edges. Check light and dark themes for readable text, controls, system indicators, focus, and selection. Size dialogs and sheets from their available parent constraints, not the full window when they live in a narrower pane.

Use deterministic route captures for each requested posture and theme, then inspect the captures for clipping, lost actions, and inconsistent alignment. Add native fold-region handling only after live-device evidence shows an occlusion that layout constraints and safe insets do not expose.

For deterministic app screenshots, reuse the route fixture and command in the [UX audit procedure](../ux-task-audit/SKILL.md#audit-procedure), and keep its JSON sidecar with each PNG. For golden updates, follow the [responsive shell and UI goldens guide](../../../docs/testing/responsive-shell-goldens.md).

For screenshot golden tests, capture each baseline on the same Flutter renderer and OS that will run it. If verified rasterization differences remain between platforms, keep platform-specific baselines and verify each on its target platform; do not replace one platform's image with another's.

Use architecture guidance when ownership changes and accessibility guidance for dedicated compliance reviews. This skill owns the shared UI/UX decision process, including visual composition; specialists supplement it without competing styling systems.

## Review before handoff

Check the requested task end to end, not only its first rendered frame. For changed navigation, exercise entry, Back, and relevant browser history/deep-link behavior. For forms or menus, check open, edit, error, submit, cancel, and focus return. For selection, check entry/exit, primary versus secondary item actions, and the exact bulk target. For layout, inspect relevant compact and expanded constraints and the transition between them, keyboard visibility, enlarged text, and long localized content. Inspect the whole affected composition for attention order, grouping, alignment, readable type, and visual-state consistency in before/after captures using only user-approved controls; report unavailable visual checks instead of claiming visual success from code.

Use the affected behavior test or Widgetbook example where appropriate. A screenshot cannot prove navigation, keyboard behavior, or user comprehension. Do not add generic tests for copy-only edits. Report what changed, evidence checked, and remaining gaps.

When shared UI behavior changes, run regression tests for each affected direct consumer in addition to shared-widget tests. For changes spanning screens or packages, use the [local CI parity guide](../../../docs/agents/ci-local-parity.md) to choose broader checks; it describes which hosted gates remain separate.

If approved rendering controls are unavailable, finish the scoped implementation and available code/behavior checks; explicitly mark visual verification pending and name the missing capture or interaction check. Do not claim visual success, invent screenshots, or require an extra design-approval round merely because rendering is unavailable. Report actual build or behavior failures separately; unavailable visual verification does not turn a failing check into a pass.

For skill maintenance, use [Markdown review scenarios](references/review-scenarios.md); for source selection and rationale, see [UX skill research](../../../docs/research/2026-10-23-ux-skills.md). These references are not required reading for ordinary UI edits.
