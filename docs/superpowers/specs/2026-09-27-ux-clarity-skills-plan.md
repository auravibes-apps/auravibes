# AuraVibes UX clarity skills plan

Research checked: 2026-09-27. Implementation completed for Codex on 2026-09-28: two skills, root routing, eval cases, and read-only pilots. Copilot trigger behavior remains unverified because Copilot CLI is unavailable.

## Goal

Give AuraVibes agents a repeatable way to find and prevent views that make a user work too hard to understand or finish a task. Judge the journey across views: what users are trying to do, what they need to know now, what action comes next, what the system is doing, and how they recover. Keep the guidance independent of Dart, Flutter, and any particular UI component library.

Success means an agent can produce an evidence-backed simplification proposal for an existing journey and a clear task plan for a new or reworked view. A smaller screen count, fewer controls, or a cleaner screenshot alone is not success. Preserve necessary choices, control, and recovery while reducing avoidable decisions and navigation.

## Current project boundary

- The supplied *Investigación UX y arquitectura de skills para agentes de IA* (27 September 2026) surveys a broad eight-part design workflow. It is research input, not an instruction to install those packages or create every module.
- The repository already has app architecture and UI implementation guidance in `.agents/skills/`. This workspace also exposes broad product-design and accessibility skills. The missing project workflow is a task review that asks whether the views and their sequence make sense before debating visual details.
- Existing app areas include service connections, workspaces, agents, chats, tools, and skills. For example, [service connection creation](../../../apps/auravibes_app/lib/features/service_connections/screens/service_connection_create_screen.dart) and [new chat](../../../apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart) have route screens. These files identify candidate journeys; they do **not** establish which journey is confusing. Select pilots from current user feedback or observed task difficulty, then capture current product behavior.
- These are **coding-agent skills** in `.agents/skills/`, distinct from AuraVibes' user-facing skill feature. Use existing app architecture, localization, and accessibility guidance when implementation begins; do not duplicate those rules in UX skills.

## Research translated into decisions

| Evidence | Decision for these skills |
| --- | --- |
| [NN/g task analysis](https://www.nngroup.com/articles/task-analysis/) (2020) begins with a user's goal and observed tasks, including order and cognitive demands. | Audit a complete user task, not an isolated screen. Mark a simulated journey as a hypothesis until observed with users. |
| [GOV.UK design principles](https://www.gov.uk/guidance/government-design-principles) (last updated 2025) prioritize user needs, doing less, and making complex services simple to use. | Ask which information and decisions serve the task; remove product complexity before rearranging it. |
| [NN/g progressive disclosure](https://www.nngroup.com/articles/progressive-disclosure/) (2006) says to show frequent needs first and make advanced options findable. [GOV.UK question-page guidance](https://design-system.service.gov.uk/patterns/question-pages/) also allows related questions together when research supports it. | Choose **keep together, split, defer, merge, or remove** from task evidence. Never treat “one page” or “one question per page” as a universal rule. |
| [NN/g usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) (last reviewed 2024) include system status, recognition over recall, control, recovery, and minimalism. | Inspect what users can infer at each decision and after each action; do not reduce UX to visual polish. |
| [W3C cognitive accessibility guidance](https://www.w3.org/WAI/WCAG2/supplemental/patterns/o1p04-clear-steps/) (2021) calls for clear location, progress, and important prior choices in a multi-step task. | Check orientation and resumption after interruption. Treat this as supplemental usability guidance, not a WCAG conformance claim. |
| [Microsoft HAX guidance](https://www.microsoft.com/en-us/haxtoolkit/ai-guidelines/) (accessed 2026-09-27) covers expectations, interaction, and recovery when AI is wrong; its [capability guideline](https://www.microsoft.com/en-us/haxtoolkit/guideline/make-clear-what-the-system-can-do/) calls for clear expectations. | Apply those principles to AuraVibes agent journeys: check capability, current status, approvals, and how users correct or stop an action. |
| [NN/g usability metrics](https://www.nngroup.com/articles/usability-metrics/) (2001) and [task-scenario guidance](https://www.nngroup.com/articles/task-scenarios-usability-testing/) (2014) evaluate whether people complete realistic tasks. | Validate changes with task scenarios and observed outcomes. Counts of views or taps are diagnostics, not a quality score. |

The two-skill scope below is a project decision inferred from this research and the existing tool inventory. A large orchestrator would duplicate capabilities before there is evidence that routing is failing.

## Shared UX clarity rubric

Each skill uses the same questions, but only for the journey or view named in the task:

1. **Goal:** Who is doing what, in which context? What observable result counts as completion? Separate known facts from assumptions.
2. **Orientation:** Can the user tell where they are, what they have already chosen, what remains, and how to return or resume?
3. **Decision load:** Which choices matter now? Which are defaults, advanced choices, repeated questions, or unnecessary decisions? Keep information needed to make a safe choice visible.
4. **View boundaries:** Which information must be seen together? Where does a view change add context loss or backtracking? Where does a crowded view mix distinct stages?
5. **Language:** Do names, instructions, outcomes, and errors match the user's concepts? Can the user predict the result of the primary action?
6. **State and recovery:** Can users understand waiting, empty, failed, partial, and completed states and the next available action? Can they undo, retry, or resume when appropriate?
7. **Agent control:** Where AI acts, are capability, current status, permissions, consequences, and correction clear without burying the main task?
8. **Inclusion:** Can people complete the task with a different language, limited attention, interruption, assistive technology, or a smaller viewport? Route detailed compliance checks to the existing accessibility skill.

An audit must distinguish **observed behavior**, **code or prototype evidence**, **user feedback or analytics**, and **untested hypothesis**. Screenshots show what was rendered; they cannot prove that people understand a journey. Never infer real user success from a heuristic review alone.

## Skill set and routing

The frontmatter description is routing text: it should match the way a user asks for work and name the boundary that prevents nearby requests from loading the skill. Put the procedure in `SKILL.md`. Use standard `name` and `description` fields only; do not rely on nonstandard trigger metadata.

### `ux-view-clarity`

Trigger for every user-visible UI edit. Run a brief task-clarity check for local changes. For a new view or a substantial flow change, write a task/view brief before implementation. Skip non-UI changes.

Description:

> Use for every AuraVibes user-visible UI edit, including screen, dialog, form, navigation, copy, state, layout, or shared-component changes. Check task clarity for small edits and write a view/flow brief for new or reworked experiences. For standalone evaluation of an existing flow, use ux-task-audit instead. Skip non-UI and accessibility-only work.

### `ux-task-audit`

Trigger for explicit and indirect requests to assess or simplify an existing journey, including reports that users get lost, face too many views, or cannot tell what to do next. Map the current task, label evidence and uncertainty, prioritize findings, and give testable simplifications. Exclude visual-only and accessibility-only reviews.

Description:

> Use when asked to audit or simplify AuraVibes UX, when a flow has too many views or unclear next steps, or when an existing task journey needs evaluation. Trace the task across current views and report evidence-backed findings and testable simplifications. Skip visual-only and accessibility-only critiques.

Add one root `AGENTS.md` routing rule for app UI, the shared UI package, and Widgetbook. Load `ux-view-clarity` for user-visible edits. Load `ux-task-audit` for a standalone audit or simplification of an existing flow; load both only when the requested work includes both an existing-flow audit and a UI edit. This reinforces description-based discovery in Codex and Copilot without loading the full audit procedure on every edit.

Create each skill with a concise, self-contained body. The view skill handles quick checks and new/reworked view briefs. The audit skill handles task maps, findings, severity/confidence, and verification scenarios. Keep guidance platform-neutral; do not duplicate app architecture, localization, visual design, or accessibility instructions. Add `evals/evals.json` in each skill folder using the existing repository format. No scripts, dependencies, or third-party skill installs are needed.

## Output contract for one finding

| Field | Required content |
| --- | --- |
| Task and step | User goal, view/state, and point in the journey |
| Evidence | Current observation, screenshot, code/prototype, user report, or explicit hypothesis |
| Problem | What the user may misunderstand or be unable to do |
| Impact | Blocked task, wrong action, rework, delay, or unnecessary decision |
| Priority | Severity plus confidence; note frequency or risk when known |
| Change | Specific simplification and what important context it preserves |
| Check | Scenario and observable result that could confirm or reject the proposal |

Do not assign a severity score merely because a view contains many controls. A frequent task hidden behind extra navigation may be worse than a denser view with related information together.

## Build, evaluate, and pilot

1. **Complete:** both skill folders pass the local skill-creator validator. The eval JSON parses, IDs are unique, expected fields exist, and relative skill links resolve. `git diff --check` passes. No Dart checks apply to this documentation-only change.
2. **Codex trigger evaluation complete:** representative prompts from both eval files ran in fresh `codex exec --ephemeral --sandbox read-only` sessions; file-read traces confirmed routing. Positives covered a local composer edit, copy edit, proposed view, Widgetbook example, explicit connection-flow audit, and indirect “too many steps” report. Negatives covered accessibility-only, backend-only, and documentation-only requests. One early audit-only run also loaded `ux-view-clarity`; its description and the root routing rule were clarified to distinguish edits from standalone audits. After that change, the audit-only trace loaded `ux-task-audit` without `ux-view-clarity`; accessibility-only work stayed with accessibility guidance. Small UI edits used the brief check without a full flow audit. Codex warned that descriptions were shortened to fit its skill-context budget, so these traces verify combined repository routing (`AGENTS.md` plus descriptions), not description-only selection in isolation.
3. **Service-connection pilot complete; code-based assessment:** traced entry from More, New Chat, skill detail, and onboarding through save and return. The supplied report was “I lose track of what happens after I save.” Source shows successful creation returns through navigation without naming the saved connection; preserved search/filter state can leave the new row out of view. This supports a candidate simplification: confirm the saved item and reveal or clearly explain it when current filters hide it, while preserving deliberate list context. Verify by creating an item excluded by the active filter and checking whether the user can identify the save result without scanning. No running-product observation, analytics, or representative-user session occurred; treat severity and benefit as unvalidated.
4. **Proposed-view pilot complete:** the agent-selection-before-chat brief kept comparison and selection together, defined the goal, entry, primary action, loading/empty/error/availability states, recovery, and a task scenario. It labeled “no silent default selection” and catalog availability as assumptions to confirm. Scenario: compare two agents, select one, start a conversation, and verify the chosen agent is clear in the resulting chat. This is a skill-quality exercise, not a roadmap claim.
5. **Copilot pending:** Copilot CLI is unavailable. Do not claim Copilot trigger success. When a Copilot host is available, reload the skills and run the same routing cases before claiming cross-host verification.

This plan does not set a universal target for screens, taps, or completion time. Set targets per user task after baseline observation. If user testing is unavailable, label the outcome as a heuristic assessment and retain validation as an open item.

## Completion criteria for the skill project

- Both skills have distinct triggers, concise instructions, and a clear handoff between existing-flow audit and new/reworked-view planning.
- The pilot audit maps a whole task, identifies evidence and uncertainty, and prioritizes changes by user impact.
- The pilot view brief states what belongs in each view and why, with entry, exit, state, recovery, and a task-level acceptance scenario.
- A reviewer can trace every recommended simplification to a user problem and a check. No finding asserts observed user behavior without observation.
- Codex prompt cases show intended positive triggers, appropriate use depth, and negative boundaries from actual skill-load traces.
- Copilot behavior stays marked unverified until tested in a Copilot host.

## Source limits

The supplied survey helped identify candidate skill categories; this plan independently checked the primary UX guidance linked above. General guidance cannot establish which AuraVibes view is currently poor. That requires a current build, realistic task, and ideally direct observation with target users. The source list in the supplied survey also labels an Apple Human Interface Guidelines URL as Google guidance; avoid carrying that mismatch into the skills.
