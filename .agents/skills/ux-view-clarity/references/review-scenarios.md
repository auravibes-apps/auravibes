# UX skill review scenarios

Use Markdown review cards and actual artifacts, not JSON eval files. These are acceptance scenarios, not proof that a model followed the skill.

## How to review a skill change

1. Choose one direct request, one indirect symptom, and one adjacent negative request; include the relevant failure cards below.
2. For a routing trial, use a fresh supported host session with normal skill discovery and the same model/toolchain. Ask for a read-only plan or critique; record which skills and references it actually reads. Do not explicitly name the desired skill in the trial prompt.
3. For a design rehearsal, supply a small wireframe, code excerpt, or approved capture and ask for a proposed change. Inspect the resulting route contract, control placement, spacing, and compact/expanded behavior. Do not treat a fluent explanation as an implemented or visually verified result.
4. Record baseline and candidate head, model/host, prompt, read trace or output path, pass/fail/not-run, failure reason, and extra work. Static harness checks cover links and metadata only. Compare representative outputs before claiming improvement.
5. Fail a candidate that hides necessary controls, bypasses routing, loses drafts, breaks accessibility, expands scope, or misroutes adjacent work. Correct the narrow rule and rerun affected cards. Real user testing remains separate.

Do not add a new runner, snapshots, JSON schema, or evaluation platform for these cards. Use existing host tools when model trials are requested or needed; do not modify app code for a skill rehearsal.

## Migrated routing cases

These preserve all 17 requests from the former two UX JSON files. Expectations now follow the short path for local edits and the edit/audit boundary. Historical trial results from the September plan do not validate the new descriptions.

### ux-view-clarity 1

**Request:** Make the chat composer 8 px taller. Keep the change local.

**Expected:** Loads ux-view-clarity and uses its short path. Keeps the edit local; preserves localization, task clarity, accessible targets, grouping, and recovery. No full audit or flow brief.

### ux-view-clarity 2

**Request:** Change the save button label in service connection creation to say Connect.

**Expected:** Loads ux-view-clarity and uses its short path. Keeps the edit local; preserves localization, task clarity, accessible targets, grouping, and recovery. No full audit or flow brief.

### ux-view-clarity 3

**Request:** Add a view where someone chooses which agent to use before starting a conversation. Plan the experience before implementation.

**Expected:** Loads ux-view-clarity and produces a concise task/view brief with goal, entry, essential information, primary action, exit, relevant states, and a test scenario without inventing unsupported product rules.

### ux-view-clarity 4

**Request:** Add a Widgetbook example for the connection status card.

**Expected:** Loads ux-view-clarity short path; follows existing Widgetbook conventions. Does not invent app navigation or a new component API.

### ux-view-clarity 5

**Request:** Audit color contrast of the primary button against WCAG.

**Expected:** Does not load ux-view-clarity because no UI edit was requested; routes to the accessibility skill.

### ux-view-clarity 6

**Request:** Refactor the provider retry policy without changing visible behavior.

**Expected:** Does not load ux-view-clarity because the task has no user-visible UI change.

### ux-view-clarity 7

**Request:** Fix the typo in the Markdown architecture guide.

**Expected:** Does not load ux-view-clarity because the change is documentation-only.

### ux-view-clarity 8

**Request:** A Flutter screen golden passes on macOS but fails on Linux CI with only text and icon edge pixels changed. Make CI pass without dropping visual coverage.

**Expected:** Loads ux-view-clarity, verifies platform rasterization differences, keeps platform-specific baselines, and validates each on its target platform without dropping the golden assertion or redesigning the screen.

### ux-view-clarity 9

**Request:** Adapt the whole app for iPhone Duo open and closed postures. Audit every route and shared sheet before changing layouts.

**Expected:** Loads ux-task-audit for the explicitly requested audit and ux-view-clarity for the following adaptation. Maps routes and shared surfaces once, uses available constraints and edge insets, checks keyboard/scroll/navigation and both themes, and validates affected routes in requested postures with approved captures.

### ux-view-clarity 10

**Request:** The foldable's inner screen feels cramped. What should change across the app?

**Expected:** Uses ux-task-audit for the existing-flow assessment and proposals; does not edit app UI. Inspects current route and widget coverage, proposes constraint-based adaptations, and avoids assuming native fold-region APIs are required. Uses ux-view-clarity when implementation is requested.

### ux-view-clarity 11

**Request:** Change how foldable device metadata is cached without changing any visible behavior.

**Expected:** Does not load ux-view-clarity because the task is non-visual; follows the relevant data or architecture guidance instead.

### ux-task-audit 1

**Request:** Audit the current service connection creation journey. I lose track of what happens after I save. Do not change code.

**Expected:** Loads ux-task-audit, maps the current task using repository evidence, distinguishes observed behavior from source-based inference, and gives testable findings without claiming user research.

**Evidence targets:** `apps/auravibes_app/lib/features/service_connections/screens/service_connection_create_screen.dart`, `apps/auravibes_app/lib/features/service_connections/screens/service_connections_screen.dart`

### ux-task-audit 2

**Request:** People say there are too many steps before they can start chatting. Find where the task loses clarity and suggest the smallest safe simplification. Do not edit files.

**Expected:** Loads ux-task-audit and maps the existing journey. It treats the report as user evidence supplied by the prompt, cites additional code or current-product evidence separately, ranks issues, and proposes checks rather than claiming an unobserved fix worked.

**Evidence targets:** `apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart`, `apps/auravibes_app/lib/features/chats/screens/chats_list_screen.dart`

### ux-task-audit 3

**Request:** Review this screen for color contrast and keyboard accessibility only.

**Expected:** Does not load ux-task-audit; routes to the accessibility skill because the request is limited to accessibility checks.

### ux-task-audit 4

**Request:** Make the connection card padding smaller.

**Expected:** Uses ux-view-clarity short path for the local UI change; does not run a standalone audit.

### ux-task-audit 5

**Request:** Change the repository retry backoff from 250 ms to 500 ms.

**Expected:** Does not load ux-task-audit because the request is backend behavior and does not ask to evaluate a user task.

### ux-task-audit 6

**Request:** Correct a spelling error in the architecture documentation.

**Expected:** Does not load ux-task-audit because the request is documentation-only.

## Failure cards from October feedback

| Request | Expected decision | Reject |
| --- | --- | --- |
| Add an agent detail destination. Use a selectedScreen provider to show it. | Explain the navigation tradeoff; inspect existing typed routes/shell and propose real route entry, Back, and relevant deep-link/refresh checks. | A parallel state-owned destination stack. |
| Keep the selected filter and expand advanced settings on this screen. | Keep local presentation/draft state local unless the task requires URL restoration. | Turning every accordion, filter, or popup into a route. |
| The inputs and Save button look glued together. Fix only that. | Short path, inspect component spacing, use theme spacing for field/action grouping, preserve hit regions and keyboard reachability. | Full redesign, arbitrary hardcoded scale, shrinking targets. |
| This settings screen shows every option. Make it calmer. | Distinguish required/frequent controls from advanced configuration; use labeled disclosure and summarize active options. | Hiding required inputs, consequential warnings, or the main action. |
| Move rename, duplicate, and archive off every list row. | Consider the house overflow menu; preserve access by touch/keyboard, label and focus return, explain archive consequence. | Hover-only controls or nested submenus without useful grouping. |
| Put all connection fields in the three-dot menu. | Use the menu to open an editor; keep required task fields on the editing surface. | A long form hidden inside an action menu. |
| On desktop show details beside the list; on mobile open details. | Same route-owned selection, bounded widths, coherent compact Back, draft preservation through resize. | An unrelated desktop state stack or a stretched mobile column. |
| Users get lost and this screen has too much information. Review only. | ux-task-audit, scoped task map, evidence/confidence, hierarchy/disclosure findings and verification scenarios; no app edits. | An unrequested redesign or claims of observed user behavior from code. |
| Make the AI connection setup easier for beginners. | Everyday-task language, minimum setup for the result, explicit actual permission/recovery behavior. | Jargon, invented integration availability, hidden consent. |
| A menu looks cleaner when every button is an unlabeled icon. | Preserve recognizable labels, semantics, focus, and findability for infrequent users. | Treating fewer visible words as proof of better UX. |
| Change foldable metadata caching without visual changes. | No UX skill. Use relevant data/state guidance. | Loading all responsive/device skills. |

## Review record for this revision

- Task: improve agent guidance for user-reported navigation, spacing, disclosure, density, and cross-platform UX mistakes; no app UI edits.
- Baseline: `e15aa6a9f`; candidate: current working diff (2026-10-23).
- Static review: compare cards to skill descriptions, root routing, and referenced interaction rules; record command results in the research report.
- Fresh-model routing and before/after design trials: **not run**. No automatic trigger reliability or measured UX improvement is claimed.
- App runtime, screenshots, assistive technology, and representative-user sessions: **not run**; outside this guidance-only task.

## Automatic use and visual-reasoning cards

Do not name a skill in these trial prompts. Check the actual read trace and the proposed artifact, not whether the answer merely repeats design vocabulary.

| Request | Expected decision | Reject |
| --- | --- | --- |
| Add a page for managing workspace members. | Automatically loads ux-view-clarity for the feature's visible surface, plans route ownership and visual hierarchy, and uses existing Aura patterns. | Waiting for the user to request design or invoke a skill. |
| Add an empty state to this Widgetbook story. | Automatically uses the short path, clear next action, existing type/spacing, and relevant visual states. | A full product audit or an unstyled demo because the request never said UX. |
| This screen works but looks messy. Improve it. | Uses ux-view-clarity and the visual reference; ties changes to attention order, grouping, alignment, readability, or state consistency. | Arbitrary gradients, new fonts, or a generic premium-design persona. |
| Review why this screen feels visually unbalanced. Do not edit. | Uses ux-task-audit with the visual reference; gives evidence-backed composition findings without a needless full journey audit. | App edits, subjective adjectives without visible evidence, or duplicate audits. |
| All these forms need the same padding workaround. | Checks the shared input and consumers; proposes or makes the authorized shared-source fix, with affected states and platform checks. | Repeating local overrides or protecting an existing flawed component as immutable. |
| The current brand treatment makes important status text unreadable. | Verifies the condition, proposes the smallest shared color/component or justified identity correction, and explains both-theme/cross-screen impact. | Silently rebranding the app or declining to question identity despite evidence. |
| Use Apple Settings and Linear as quality references. | Applies the approved traits to Aura's task, input methods, and system; verifies actual examples before specific visual comparisons. | Copying either brand or treating a dense desktop layout as the mobile default. |
| Implement this form; approved rendering tools are unavailable. | Completes scoped implementation and available checks, names pending visual verification, and makes no claim of observed visual success. | Invented screenshots, a false all-checks-passed claim, or an unnecessary design-approval gate. |
| Add the repository method behind an existing screen without changing visible behavior. | No UI skill merely because a screen is mentioned. | Blanket UI-skill loading for non-visual work. |
| Improve the instructions that tell coding agents how to design UI. | Uses skill-maintenance guidance; does not treat this as an app UI edit. | Loading the app implementation workflow or modifying app screens. |

Static review of these cards is complete. Fresh-host implicit-routing and generated-artifact trials remain **not run**.

## Content and contextual-control cards

These generalize accepted corrections from the reviewed session. They do not
require a specific destination name, sort order, plus icon, menu structure,
creation container, or selection gesture.

| Request | Expected decision | Reject |
| --- | --- | --- |
| Add creation, sharing, and structure-editing capabilities to this collection browser. | Keeps browsing content primary; provides clear on-demand entry points for secondary tasks and reviews the combined screen. | Permanently stacking every new form above the content. |
| Build a dedicated setup form that must be completed before content can exist. | Treats setup as the actual task, with required inputs and a clear completion result. | Hiding required fields in menus under a blanket content-first rule. |
| Add creation to a nested collection and to an item's child list. | Makes each command's target clear, asks essential fields, and reveals the created result in the correct context. | A global creation action that silently targets another scope. |
| This creation flow adds many entries in succession. Keep it fast. | May use inline/minimal entry with clear success and preserved context when repeated entry is the task. | Navigating away after every entry merely because another feature opens each created item. |
| Add an occasional rename action to a clickable list row. | Preserves the predictable row primary action and accessible contextual management; verifies secondary activation does not open the row. | Ambiguous nested targets, hover-only access, or always exposing every future management action. |
| Add bulk actions to a normal browsing list. | Provides accessible selection-mode entry/exit, visible selected state/count and explicit bulk scope; preserves browsing context. | Always-visible administrative toolbars, long-press-only entry, or actions targeting a changing search implicitly. |
| This review queue's main job is selecting many items and applying one decision. | Allows persistent selection tools when justified by that primary workflow. | An extra mode switch solely to satisfy a universal no-checkboxes preference. |
| A user selects an item, narrows the window, opens details, and returns. | Preserves task location and relevant selection/scroll/draft context through route and layout transitions. | Checking two static widths while missing the transition that resets the destination. |
| Automation captures a blank app after navigation, but focusing the intended window restores it. | Separates capture/control failure from product behavior and seeks a reproducible app defect before proposing code changes. | Declaring a broken router from the blank capture alone. |

Static consistency review covers these expectations and their exceptions.
Model execution and current-app rendering of these scenarios remain **not run**.
