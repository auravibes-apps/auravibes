# Visual design with a reason

Use when composing or polishing a visible AuraVibes surface. Read only the sections relevant to a small edit. Apply the existing system; these rules do not authorize an app redesign.

## Reference calibration and system improvements

Use the user-approved reference directions deliberately:

- **Apple Settings:** calibrate familiar forms, navigation, grouping, and predictable control placement.
- **Linear:** calibrate attention hierarchy, alignment, coherent states, and careful interaction feedback.
- **AuraVibes:** retain everyday-user clarity across mobile, desktop, web, and adaptive layouts. Do not copy another product's branding or adopt desktop power-user density by default.

These are quality references, not exact screenshot targets or new framework requirements. Inspect current examples before making a specific comparison; do not claim this skill's reference selection is itself a rendered comparison or a usability study.

Preserve identity by default, but challenge a component, token, or identity choice when it demonstrably harms legibility, task hierarchy, navigation, accessibility, or consistency. Try a composition fix first when it fully solves the problem. If the shared source owns the defect, propose or implement the scoped shared fix instead of repeating compensating overrides in screens. A justified identity proposal should connect the proposed visual change to the user problem, describe affected surfaces and trade-offs, and state a check that could confirm or reject it. Pure personal preference is not enough.

For example, if a shared input's internal layout clips scaled labels, identify that shared constraint and its consumers rather than shrinking each screen's type. If the available semantic treatment cannot make an important state readable in both themes, propose a consistent token/component correction with its cross-screen impact. Do not assume either defect exists without checking.

## Attention and emphasis

Before building a new composition, identify what the person should notice first, next, and only if needed. Usually the task/result leads, followed by necessary context and supporting controls; urgent failures may need to lead instead. This is an attention order, not a fixed screen template.

Use placement, whitespace, type role, weight, and contrast together. Do not make every label bold, every action filled, or every status an accent badge. When a primary action disappears among competitors, reduce irrelevant emphasis before making that action larger. Reserve strong accents for task-relevant priority and semantic states; do not flatten error/success meanings into one brand color.

**Check:** Can the intended task/result and next action be identified from the rendered screen without scanning every control? Does the visual emphasis still match the task in empty, error, and completed states? This is a heuristic check, not proof that users understand it.

## Grouping, rhythm, and alignment

Spacing communicates relationships. Keep a label/help/error closer to its field than to a neighboring field. Separate distinct task groups more clearly than items within one group. Reuse the spacing choices for equivalent rows and sections; arbitrary gap variation suggests relationships that do not exist.

Use [the existing spacing guidance](interaction-rules.md#forms-and-space) and Aura tokens. Preserve intentional compact groups such as an input and its send control. Do not add equal padding everywhere: proximity within a group and separation between groups serve different jobs.

Align page titles, section headings, fields, and list text to a small set of shared content edges. Align text baselines when mixed-size labels or values need to read together. Repeated rows need consistent leading/trailing alignment, icon footprints, and action positions. Use logical start/end rather than baking in left/right assumptions. Centering fits a short empty state or bounded focal task; long forms and lists usually need a stable reading edge.

Check the visual weight of an icon against its text, not only the center of its bounding box. Prefer an existing icon/component variant; make an optical adjustment only for a visible mismatch and preserve the component's hit target. Do not invent per-row offsets or a second grid to compensate for one bad primitive.

**Check:** Is the intended grouping clear without extra cards? Are equal roles aligned and spaced consistently? Is a gap measured after the component's own padding, so wrapper spacing does not double it?

## Typography and readable density

Choose existing `AuraTextStyle` roles via [Aura text](../../../../packages/auravibes_ui/lib/src/atoms/aura_text.dart) and its theme-owned typography. Establish a small set of meaningful roles for this surface, such as title, body/field label, and supporting text; do not impose a universal font count. Keep the same role consistent across sibling views.

Use type weight, spacing, and semantic emphasis before multiplying font sizes. Preserve comfortable body/label size; simplify or reorganize content before shrinking text. Bound paragraph and form width on expanded layouts. Dense comparison data may need a different composition from prose, not a smaller copy of the mobile form.

Allow useful wrapping for titles, labels, and errors. Ellipsis suits known secondary list content only when the full value remains accessible where needed; never truncate the consequence of a primary action. Do not force fixed heights that clip scaled text, descenders, or Spanish labels. Existing app fonts, line heights, and tracking take priority over imported font bans or CSS recipes.

**Check:** With enlarged text and longer localized content, can the person still read the decision, identify each field, and reach its action? Are the title and button competing for attention? Are metadata and help readable rather than merely faint?

## Color, surfaces, and icons

Use the active Aura semantic colors, surface roles, radii, and interaction states. Read the [UI style guide](../../../../packages/auravibes_ui/STYLE_GUIDE.md) and [interaction contracts](../../../../packages/auravibes_ui/INTERACTION_CONTRACTS.md) before changing shared components. Do not hand-dim resolved interaction colors or replace selected state with a hover effect.

Contrast distinguishes a task, a group, or a state. Give text/control/focus contrast the applicable accessibility check; “subtle” does not justify illegibility. Do not rely on color alone to distinguish selected, failed, pending, and completed states. Pair meaningful color with text, shape, or an established indicator.

Use a surface, border, or elevation when it identifies a real container, layer, interaction boundary, or selected group. Prefer spacing and headings when they already establish the structure. Avoid redundant nested cards and simultaneous border, shadow, tinted background, and badge treatments for the same hierarchy. Neutrality is not a ban on character; existing brand expression can remain where it does not compete with the task.

Use the established icon family, size roles, stroke weight, and placement. Icons must help recognition, not decorate every label. Keep an accessible name on icon-only actions and visible wording when an unfamiliar action needs explanation. Do not add an icon without a semantic job, or swap the icon family for one screen.

**Check:** Does the same meaning look the same in sibling views and both themes? Do active, focused, selected, loading, disabled, and error states remain distinct? Does every container or accent explain something?

## Composition across sizes and states

Balance comes from the distribution of content and visual weight, not mandatory symmetry or filling every blank area. Keep important content anchored consistently between related routes. Use available parent width to decide whether supporting context stays beside the task or moves into a reachable disclosure/destination. Keep forms bounded; use additional panes only when they help the task.

Compose the real states and realistic content, including empty lists, one item, long names, large counts, waiting, errors, and partial results. Preserve stable action locations where practical so validation or loading does not move the target during interaction. Reserve space for necessary feedback where it helps; do not render placeholder UI indefinitely or hide recovery to keep a layout symmetrical.

Use existing feedback and motion tokens when a transition clarifies a change or preserves continuity. Respect reduced motion. Do not add autoplay, shimmer, bounce, or a slower workflow merely to make the screen feel designed.

**Check:** Does compact layout still feel intentional, and expanded layout avoid stretched inputs and scattered actions? Does the person retain location and draft context through resize? Does the error state look composed and explain recovery?

## A small worked decision

For a hypothetical setup form, an overloaded version might give every field its own tinted card, show optional technical configuration immediately, and style Save, Test, Advanced, and Cancel as equal filled buttons. The problem is competing signals and ambiguous grouping, not merely the number of controls.

A quieter composition can keep one title, a short outcome-oriented explanation, related required fields, a labeled advanced disclosure with an active-setting summary, a dominant completion action, and lower-emphasis supporting actions. Keep Test visible if frequent verification is essential; otherwise consider the appropriate secondary surface. Preserve Cancel and necessary permission or failure information. Choose the actual fields and controls from product evidence, not from this example.

The rationale is explicit: fewer competing accents establish hierarchy; proximity groups fields; stable alignment improves scanning; disclosure defers optional decisions. Do not apply this layout to every screen or assume fewer visible controls always means better design.

## Review evidence and sources

Inspect the result at relevant sizes, themes, and states using approved controls. First fix composition problems visible in the same capture, then inspect again; avoid a screenshot after every minor tweak. Record what was actually rendered and exercised. Code review and passing tests cannot establish visual balance or measured usability.

For guidance maintenance, the [research follow-up](../../../../docs/research/2026-10-23-ux-skills.md#follow-up-visual-reasoning-and-automatic-use) records source quality, adoption choices, and limits. These are original project adaptations of visual-design principles, not a copy of a vendor design system or paid skill.
