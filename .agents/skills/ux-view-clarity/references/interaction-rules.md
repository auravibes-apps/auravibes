# AuraVibes interaction rules

Read only sections relevant to the requested change. These are app design defaults, not permission to redesign adjacent features. Distinguish a reported problem from a verified code or visual defect.

## Navigation: destinations have routes

- Inspect [the route tree](../../../../apps/auravibes_app/lib/router/workspace_route.dart), its caller, and the matching shell before proposing navigation. Reuse typed routes and existing branch navigation, nested navigator, and draft-exit patterns. Respect workspace and entity identifiers, redirects, and permission boundaries.
- A destination has its own location or task: list, detail, creation, settings. Navigate through the router. Do not create an enum, boolean, provider, `IndexedStack`, or conditional body as a parallel destination stack. An existing router-owned stateful shell may legitimately use an indexed stack.
- Local state is appropriate for expanded help, selected filters, draft values, or a panel within the same task. A tab representing an app destination follows the router; a tab changing one view's local presentation need not create a route. Put shareable/restorable filter state in the existing URL pattern when required.
- A menu selects an action. An inline disclosure reveals optional content. A dialog or sheet handles a short bounded interruption; it must have clear completion and dismissal. Use a route for work that needs independent navigation or persistent location. Reuse the established modal/navigation helper rather than forcing every popup into a route.
- Specify entry, selected destination, Back versus close, post-save result, and where context returns. Choose push versus replacement from existing behavior; do not assume either always fits.
- Check platform Back and gestures, browser Back/Forward, direct URL and refresh when relevant. Selection and draft state must survive the transitions required by the task. Reuse existing dirty-draft guards; do not silently discard work or add duplicate confirmation owners.

## Content, creation, and configuration

- Establish the surface's main job before arranging controls. A browsing or working surface normally opens on its content, not a permanent creation form or a stack of schema, access, and administrative controls. Expose those secondary tasks through clear entry points. Dedicated setup, configuration, and data-entry screens, or unavoidable prerequisites, are explicit exceptions.
- Distinguish working with content from changing the structure or administration of that content. Implementing a capability does not require displaying its controls continuously. Keep essential status, safety information, and context needed for the current decision visible even when configuration lives elsewhere.
- For an empty collection, explain what belongs there and offer the next useful action. Do not fill the empty state with every future setup option. Inline creation is appropriate when rapid entry is the actual task; justify it from that workflow rather than from the convenience of placing a form above a list.
- Review the whole affected surface as features accumulate. Individually correct fields, buttons, and panels can still form a confusing screen. Preserve its main job and attention order instead of turning each implementation slice into another permanent block of controls.

## Contextual commands and minimal creation

- Make the primary action's target predictable from the current task or container. A command affecting a different scope must identify that scope explicitly. A plus icon is one possible presentation, not a universal requirement; keep its accessible name and result clear.
- If multiple relevant creation types are available, let the person choose among supported, permitted options without exposing placeholder features. Explain a relevant unavailable capability when that helps recovery or access discovery; do not expose restricted information or replace authorization checks with UI hiding.
- Ask only for information needed to create a valid result now. Defer optional configuration while preserving necessary consent and consequential choices. Choose inline editing, a bounded form, a sheet/dialog, or a route from task size, navigation needs, and available constraints; do not require one container for all creation flows.
- After success, make the created result identifiable: open it, select/reveal it, or confirm it in a repeated-entry workflow. Preserve the originating context and unfinished work. If active filters hide the result, explain that or reveal it without silently discarding deliberate filters. Failure keeps entered values and offers recovery.

## Item actions and selection

- Give each repeated item or row a predictable primary interaction appropriate to its task, such as opening details or selecting an option. Keep that behavior consistent across equivalent items. Secondary controls must not accidentally invoke the row's primary action or make its target ambiguous.
- Group occasional management actions near their item in a contextual menu or equivalent house pattern. Keep frequent essential actions directly available when useful. Neither a menu on every row nor hiding every secondary action is a universal rule.
- Default bulk controls to an explicit selection mode: provide discoverable entry, clear selected state, selection count/scope, relevant actions, and an exit that returns to ordinary work. Define whether selection covers specified items, a page, or a larger result set; do not let a changing query silently expand the action's target.
- Provide touch and keyboard entry/exit and preserve focus and browsing context. Long-press, right-click, and shortcuts can supplement a discoverable control; none should be the only access path. Selection mode is local interaction state, not a parallel screen-navigation stack.
- A selection-heavy task may keep checkboxes and bulk tools visible when that supports its primary workflow. Do not force an extra mode switch or shrink individual targets merely to make the screen look cleaner.

## Hierarchy and progressive disclosure

Classify each control by its role in the current task before placing it:

| Role | Default placement | Guardrail |
| --- | --- | --- |
| Main next action and required input | Visible in the task surface | One clearly dominant next action per task region; comparison or bulk-work surfaces can have several meaningful actions. |
| Frequent supporting action | Visible, with lower emphasis | Do not bury common work merely to reduce button count. |
| Occasional item action, such as rename or duplicate | Nearby overflow/context menu | Use recognizable triggers, accessible names, and stable action labels. Touch and keyboard users need access too. |
| Advanced optional configuration | Labeled disclosure or dedicated settings destination | Show active non-default choices in a summary when they affect the result. |
| Optional explanation | Short hint or expandable help | Keep information needed for a correct decision outside the disclosure. |
| Consequential action or AI permission | Appropriate action surface with clear consequence | Cost, access, destructive scope, ongoing status, stop/cancel, and recovery must remain understandable. Follow the feature's actual authorization contract. |

Prefer a nearby flat menu for a few occasional actions. Add a submenu only when a real grouping makes it easier to find the action; do not create deep menu chains to make a screen look empty. Use an action sheet or other house pattern when a compact touch menu cannot fit. Never make hover, right-click, a gesture, or an unlabeled icon the only access path.

Do not put a long form inside an action menu. Let the menu open an appropriate editor. Keep main navigation discoverable across layouts; desktop rail/sidebar and compact navigation should identify the same current destination.

## Forms and space

- Reuse [Aura UI](../../../../packages/auravibes_ui/STYLE_GUIDE.md) components and [interaction contracts](../../../../packages/auravibes_ui/INTERACTION_CONTRACTS.md), including existing input, button, popup-menu, and focus behavior. Inspect component defaults before wrapping them in extra decoration or spacing.
- Use `AuraSpacing` through the [theme-owned scale](../../../../packages/auravibes_ui/lib/src/tokens/aura_theme.dart) and existing spacing widgets. The standard scale is `xs=4`, `sm=8`, `md=16`, `lg=24`, `xl=32` logical pixels; subtree themes can rescale it. Do not hardcode a second spacing system.
- Starting point when no local pattern fits: `sm` between closely related controls, `md` between field groups and before the action row, `lg` between distinct sections. Keep label/help/error close to its input. These are composition defaults, not universal minimums: compact input-plus-send controls and button groups need their established pattern.
- Judge both visual gap and actual hit regions. Avoid overlapping targets; do not shrink target size to create whitespace. Flutter logical pixels, Apple points, Android dp, and web CSS pixels are different platform measures; inspect the rendered control and applicable platform guidance.
- Preserve touch-friendly house target sizes and keyboard focus. WCAG 2.2 AA SC 2.5.8 uses a 24 by 24 CSS pixel target or specified exceptions; 44 by 44 CSS pixels belongs to enhanced SC 2.5.5 (AAA), not a blanket AA requirement. A minimum conformance floor is not the recommended size for every app control.
- Use persistent labels; placeholders do not replace labels. Ask only for what is required now. Keep related fields together and arrange them in a predictable reading/focus order. Prefer a single column for compact forms; add columns only when the relationship and available width support them.
- Preserve typed values after validation/network errors. Identify the field and recovery; reveal an invalid field inside a collapsed group and bring it into view. Show submission progress, prevent duplicate submission, and communicate the resulting item or destination.
- Keep actions reachable above or through the keyboard and within a scrollable surface. Sticky actions must not obscure focused inputs or errors. Do not disable paste or remove useful autofill without a task-specific reason.

## Information density and language

State the screen's purpose and next useful action in plain language. Show essential context, current result/status, and required decisions first. Defer secondary metadata, repeated explanations, and advanced configuration. Do not expose MCP, provider wiring, JSON, or implementation terms unless the person needs them for the requested technical task.

Prefer grouping and hierarchy over nested cards around every field. If details compete with the main task, summarize or move them to a meaningful destination. Preserve information needed for comparison, consent, safety, or recovery; neither a fixed control count nor a universal one-screen/one-question rule measures simplicity.

Reuse current typography, semantic colors, icons, and components. Do not import font bans, randomized layouts, oversized marketing headlines, cinematic reveals, or perpetual animation from website inspiration. Motion should explain feedback or continuity, respect reduced motion, and never delay a frequent task.

## Adaptive behavior: same task, appropriate composition

- Use available parent constraints after shell/pane/insets, not device names or orientation. Inspect existing breakpoints and shell behavior; use `LayoutBuilder` where local constraints matter. Do not introduce new breakpoints simply because a reference uses them.
- Compact: prioritize the main task, stack related inputs, preserve readable labels, and expose optional controls through clear entry points. Expanded: bound form/text width; use list-detail or supporting panes when comparison benefits. Do not stretch every input across the window or reveal every setting because space exists.
- Preserve selected entity, current route, draft, and scroll/focus context as required when resizing. A detail pane that becomes a compact destination still needs coherent Back behavior; resizing must not invent a second navigation source of truth.
- Touch, mouse, trackpad, and keyboard can coexist at any width. Provide visible focus, predictable Tab/Shift+Tab order, appropriate Enter/Escape behavior, and focus return to the opener. Context menus and shortcuts supplement discoverable controls.
- Check relevant compact, intermediate, and expanded widths, short height/keyboard, text scaling, long English/Spanish labels, light/dark themes, and empty/loading/error states. For an app-wide pass, map all affected routes and shared sheets/dialogs first; a local change needs only its affected matrix.

## Evidence required for a UI change

Review code for ownership and behavior; inspect before/after renders for composition. With approved runtime controls, exercise the main task plus the relevant navigation, disclosure, and recovery paths. Record sizes, states, and captures actually inspected. If capture/runtime access is unavailable, mark visual and interaction verification pending and name the missing check. Never replace a failed visual assertion with a weaker assertion solely to pass CI.

A blank or stalled capture can reflect the wrong window, focus, or automation state. Check the observed surface and seek a reproducible app failure before proposing a routing or rendering fix; a control-tool failure alone is not a product defect. Keep approved plans, implemented code, and verified behavior distinct when reviewing prior sessions or transitional work.

Sources and adoption rationale live in [UX skill research](../../../../docs/research/2026-10-23-ux-skills.md). Read it for guidance maintenance, not every UI task.
