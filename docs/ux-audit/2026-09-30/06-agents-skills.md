# Agents, skills, and capability readiness

[Audit index](README.md) · Screens S19–S22 · Findings UX-21–UX-24

## Goal and object relationships

Reuse useful assistant behavior without reconfiguring it for every chat. Know when an agent or skill is available, what it does, which access it needs, and why a tool will ask for permission.

The current model supports different objects:

- An **agent** supplies reusable instructions, usage description, selected skills, visibility, and tool permission overrides.
- A **skill** supplies reusable content/capabilities, resources, tools, and access requirements. Built-in app skills differ from editable custom skills.
- A **tool** is an action available through the app, a skill, or a connected service.
- A **conversation** can select an agent and add/use skills in its own context.

These relationships argue for shared navigation and linked summaries. They do not justify merging the data objects into one generic “AI thing.”

## Current journeys

| Step | Create reusable agent | Create custom skill | Use skill in a conversation |
| --- | --- | --- | --- |
| 1 | More → Agents | More → Skills | Open Conversation skills |
| 2 | Create agent | Create skill | Find available/loaded skill |
| 3 | Name, When to use, System prompt | Title, description, content, optional credential type | Inspect readiness/context status |
| 4 | Edit prompt in Markdown child editor | Edit content/description in Markdown child editor | If access missing, contextual credential setup |
| 5 | Assign skills; optional availability/permissions | Save before related resources/template tools appear | Return; refresh or retry |
| 6 | Save → list | Add resources/tools, preview/save as needed | Add to context or Use now |
| 7 | Select in chat or allow delegation | Make available/enabled in workspace | Observe result or recovery |

Evidence: E17–E19. Runtime activation and response quality remain unverified.

## S19 — Agents list

**Purpose:** find, create, edit, duplicate, enable, and choose where an agent appears. **Strengths:** search, type/status filters, pagination/load-more recovery, empty-state explanation, skill counts, visibility controls, duplication, and delete consequence copy.

**Recommendation:** keep a separate Agents list within Agents & skills. Show name, When to use, enabled state, visibility, and a concise capability/readiness summary. Preserve expert filters and large-list behavior, but make a default first-use list approachable.

**Copy opportunity:** “Agent type” currently filters Chat selector/Sub-agent list, which are availability locations rather than different agent behaviors. Label it “Available in” or a similarly accurate term. “Visible in” is already used by the editor; align the list and editor.

**Do not merge:** combine agent cards and skill cards into one undifferentiated list. Choosing a behavior profile and configuring reusable skills are different tasks.

## S20 — Agent detail and create

**Purpose:** author reusable instructions and optionally assign skills/permission policies. **Strengths:** required-field count; Name/When to use/System prompt validation; focus on invalid fields; optional advanced settings; selected/disabled/unavailable skill summaries; workspace-default permission option; dirty-state confirmation.

**Recommendation:** keep this focused editor. The current “required fields first; availability and tools optional” guidance is a good pattern to reuse elsewhere. Show effective availability and capability readiness before saving, with links to repair dependencies.

### UX-21 — Related agents and skills have independent management entries with little relationship guidance

- **Task step/view:** S19/S20 agent creation and S21/S22 skill configuration.
- **Evidence:** E02/E17/E18; Agents and Skills are separate More tiles, while agent detail includes skill assignment summaries and a skill manager. Skill detail exposes separate content/resources/tools/credentials.
- **User problem and impact:** the person may confuse writing agent instructions, writing skill instructions, and enabling a capability. Moving between destinations can hide how one object uses the other.
- **Severity:** medium. **Confidence:** medium.
- **Change:** one Agents & skills management destination with distinct Agents and Skills views; use short relationship copy and reciprocal links. Keep focused details and editors.
- **Preserve:** independent identities, sharing/reuse, built-in/custom ownership, and existing list filters/pagination.
- **Verification:** ask a participant to create an agent that uses an existing skill and another to create a reusable skill used by two agents. They should explain which object owns instructions versus reusable capabilities, and changes must not duplicate the skill.

### UX-22 — Enabled, visibility, and capability readiness can be mistaken for one status

- **Task step/view:** configure S20 availability or pick an agent whose selected skill is disabled/unavailable.
- **Evidence:** E17; agents have Enabled and Visible in controls, selected/disabled/unavailable skill summaries, and tool overrides. Copy says disabled agents cannot be selected/delegated and disabled selected skills will not load.
- **User problem and impact:** an enabled agent may be selectable yet unable to use an intended capability. “Both” or a visibility flag does not describe readiness.
- **Severity:** medium. **Confidence:** medium.
- **Change:** distinguish Saved, Enabled, Available in chat/delegation, and Capability needs attention. Summarize missing/disabled dependencies near the agent's action and offer repair without hiding warnings inside management dialogs.
- **Preserve:** intentional disabled skills, independent visibility choices, and workspace enable confirmation. Do not silently enable all dependencies on save.
- **Verification:** select an enabled agent with one disabled skill, then intentionally enable the skill. The person should predict the difference in runtime behavior and the scope of enabling it.

## S21 — Skills list

**Purpose:** manage reusable workspace skills from app or user sources, including search, filters, enablement, sorting, selection, and custom-skill bulk delete.

**Strengths:** built-in versus user ownership is represented; built-in content is read-only; custom deletions have dependency consequence copy; empty/search states exist; list filters separate Source and Status.

**Recommendation:** within Agents & skills → Skills, use understandable source labels such as Built-in and Custom if they accurately cover the existing source enum. Show Ready, Needs access, Disabled, or Status unknown separately from ownership. Reveal Native/Template internals only where that distinction helps selection or authoring.

**Merge boundary:** the conversation skill picker shares the same skill identity and readiness data, but should stay task-focused. The management list edits availability/content; the picker adds/uses capabilities in a specific conversation.

## S22 — Skill detail and create

**Purpose:** create/edit custom skills; view/configure built-in skills; manage access, resources, and tools once the skill exists.

**Strengths:** built-in read-only explanation, create/edit reuse, dirty protection, contextual Add Credential, optional credential explanation, static resource views, template/native tool sections, and duplicate/clone paths. Do not report that credentials have no contextual setup path—the existing detail and conversation picker provide one.

**Recommendation:** structure the detail into Overview/instructions, Access, Resources, and Tools. Show a readiness summary at the top and preserve a clear Save versus immediate-enable distinction. On creation, explain which sections become available after the identity is saved.

### UX-23 — New skill authoring changes available sections after the first save without explaining the stage

- **Task step/view:** S22 create → save → add resources or template tools.
- **Evidence:** E18; related-section helpers return when `detail == null`; the saved detail enables resources and tools. Saving normally returns to the Skills list.
- **User problem and impact:** someone creating a skill with tools cannot see that part of the task initially and must reopen the object after saving. This can make incomplete configuration look like a finished skill.
- **Severity:** medium. **Confidence:** medium.
- **Change:** say “Create the skill, then add resources and tools.” Offer Create and configure next, or remain in detail after creation when advanced authoring intent is clear. Keep simple instruction-only skill creation fast.
- **Preserve:** persisted identity before child records, valid data, and the ability to finish without resources or tools.
- **Verification:** create an instruction-only skill and a skill with a template tool. Both tasks should have explicit completion; the second should continue authoring without searching for the newly created object.

### UX-24 — Access, enablement, and conversation-context readiness need a consistent vocabulary

- **Task step/view:** S21/S22 status versus Conversation skills picker.
- **Evidence:** E18/E19; skill detail supports optional credentials and explains that access-required tools remain unavailable. The conversation picker distinguishes credential Ready/Missing/Unknown from Added/Preparing/Ready in context/Needs context/Context error, and offers Add versus Use now.
- **User problem and impact:** multiple “Ready” concepts can be read as a promise that the skill and all its tools will run. The management list's enabled status does not explain actual conversation readiness.
- **Severity:** medium. **Confidence:** medium.
- **Change:** consistently label Access ready, Added to this chat, Ready in context, and Tool unavailable. Explain Add as preparing capability/context, and Use now as requesting immediate use for the latest task.
- **Preserve:** optional credential loading, unknown/stale metadata handling, context preparation, and distinct Add/Use now behavior.
- **Verification:** test optional access missing, required access missing, access unknown, context preparation failure, and stale skill metadata. The participant should predict which capabilities can run and choose the correct repair/action.

## Supporting managers

| View | Keep | Improve |
| --- | --- | --- |
| Agent skill manager | Selected/available/disabled/unavailable groups and workspace enable confirmation | Identify the target agent and whether choices are draft until parent Save |
| Agent tool permissions manager | Workspace default, ask, allow, deny, missing overrides | Display effective result and source; keep scope-specific policy intact |
| Compact agent selector | Optional No agent and supported choices | Explain that selection affects this conversation; link setup only when appropriate |
| Conversation skill picker | Loaded/available groups, readiness, credential setup, Add/Use now | Show this chat's context and explain the active step in plain language |

The agent copy says conversation settings still win. This audit does not independently prove all permission precedence from the runtime. Before exposing an effective-policy summary, derive it from the authoritative resolver, and verify with representative workspace/agent/conversation combinations. Never invent a simpler precedence merely to improve copy.

## Proposed detail readiness summary

| Object/state | Example explanation | Action |
| --- | --- | --- |
| Agent ready | “Available in chats. Uses 2 skills.” | Use in chat |
| Agent disabled | “Saved, but cannot be selected or delegated to.” | Enable |
| Selected skill disabled | “[Skill] is disabled in this workspace.” | Review/enable skill |
| Required access missing | “[Service] access is needed for this skill.” | Set up access |
| Optional access missing | “Instructions can load; [tool] needs access.” | Add access / continue with limited capability |
| Skill added, context not ready | “Added to this chat; preparing instructions.” | Wait / Retry if preparation fails |
| Missing tool override target | “An override refers to a tool no longer available.” | Review override |

Examples are proposed copy, not current translated strings. Final copy must be authored and reviewed in both English and Spanish.
## Implementation checkpoint for related views

Task 2b groups Agents and Skills under related local tabs while preserving their existing URLs. The existing agent-list provider retains its query and pagination. Skills has workspace-owned search, source, enabled and sort state. The visible search field restores that state when the screen returns.

View skill pushes the selected skill editor from the agent's skill manager. Open workspace agents pushes the agent list from skill context. Neither action derives a complete usage count from a paginated list. Focused tests verify that the dirty parent draft survives both pushes and remains protected after return.

The English and Spanish tab checks pass at 360, 959 and 960 pixels. Task 2b is verified and reviewed, with zero diagnostics in the final strict scan and zero open review findings. Related skill Save refreshes the title while retaining the dirty agent. Task 5 and its refresh repair are verified for readiness, enabled/visibility wording, first-save handoff and nested authoring. [Execution evidence](14-execution-evidence.md#task-2b-verified-handoff) records the checks and limits. Native navigation and participant comprehension remain unverified.


## Verified authoring and access handoff

Task 5 distinguishes saved, enabled and chat/delegation availability, exposes disabled/missing assignments and keeps immediate workspace enablement separate from an unsaved assignment draft. Normal skill creation retains its simple completion; explicit Create and configure opens the actual saved identity and exposes tools/resources. Stored credential/instruction metadata is separate from conversation-context readiness and runtime enforcement.

The reviewed repair gives both credential setup entry points a shared identity-scoped refresh and refreshes the actual tool dependency after a successful repair. Changed-data tests show the retained summary and credential count converge while dirty parent title, Markdown instructions and optional-access choice remain intact. Final fatal analysis has zero diagnostics, all repair hashes match and scoped review has zero open/new findings. [Execution evidence](14-execution-evidence.md#task-5-verified-handoff) records commands, failures and scope. Current readable captures, native interaction and participant comprehension remain validation work.

## Task 7 validation checkpoint

Actual second-agent creation selects an existing shared skill and persists instructions without changing the original agent or skill records. Separate agent availability saving preserves sibling use. Actual staged skill resource/tool create/edit returns refresh the parent while retaining its independent dirty title. Narrow Spanish Skills controls and neutral badge contrast are repaired. Comprehension and exhaustive stale-state permutations remain separate checks. See [current coverage](15-validation-coverage.md#current-implementation-evidence--task-7) and [execution evidence](14-execution-evidence.md#task-7-final-attempt-2-results-and-bounded-correction).
