# Editors, save behavior, and credential type authoring

[Audit index](README.md) · Screens S23–S27 · Findings UX-25–UX-29

## Goal

Change the intended object, know whether a change is only in a draft or persisted, and leave without accidentally losing work. Expert configuration should be reachable without making ordinary service setup look like programming a request schema.

## S23 — Skill resource

**Purpose:** create/edit custom resource content, or view a built-in static resource. **Strengths:** create/edit/view titles, read-only mode, Markdown editing, missing/load states, explicit deletion confirmation, and parent skill identity in the route.

**Recommendation:** retain a focused child editor. Show the parent skill and resource name, protect dirty drafts, and use Save resource. A built-in resource should say why it is read-only; where duplication exists, distinguish cloning a skill from editing the original resource.

### UX-25 — Draft protection is inconsistent across editors and navigation exits

- **Task step/view:** S23 resource editing; S16 connection creation; dirty workspace creation/other editors when leaving through shell navigation.
- **Evidence:** E15/E20/E25; resource editing has controllers and persistence but no explicit dirty-state PopScope/onExit guard. Connection creation similarly has no explicit guard in the screen. Skill tool editing has both a route-exit guard and PopScope; several other editors use PopScope only. Shared workspace creation can invoke an add-account go transition.
- **User problem and impact:** people can reasonably expect comparable protection across forms, but some paths can discard a draft or bypass the mechanism used for Back. Live testing is needed to establish exactly which replacements and branch changes trigger guards.
- **Severity:** high. **Confidence:** medium for missing screen guards; low for unexecuted exit-path outcomes.
- **Change:** define a shared draft contract for Back, close, drawer navigation, branch reset, workspace change, browser history, and external authentication. Add protection or durable drafts where missing; restore the initiating draft after setup detours.
- **Preserve:** intentional save/discard, busy-state restrictions, read-only views, secret privacy, and current guards. Avoid extra confirmation for a clean or reverted form.
- **Verification:** type a resource draft and a connection draft, then exercise each exit path. Cancel leaves the exact content and focus intact; Discard is explicit; Save persists the intended object; returning from authentication restores safe draft context. Use SkillToolEdit's existing all-exit-path test as a specification reference, not proof that other screens pass.

### UX-27 — Resource save action names the wrong object

- **Task step/view:** S23 editable resource → Save.
- **Evidence:** E20; `_SkillResourceActions` uses `LocaleKeys.skills_screen_save`, translated as “Save skill,” although the action persists a resource.
- **User problem and impact:** the action can imply that the parent skill or unrelated instruction edits are saved too.
- **Severity:** low. **Confidence:** medium.
- **Change:** “Save resource,” with a short saved result and return to the parent resource section.
- **Preserve:** current resource persistence, read-only behavior, and deletion semantics.
- **Verification:** edit only a resource and ask which data the action saves. Confirm parent unsaved fields are handled independently.

## S24 — Template tool

**Purpose:** author tool description, HTTP request template, inputs, headers/query/body, credential requirement, enabled state, and optional raw definition JSON.

**Strengths:** structured inputs instead of raw-only authoring; hints and request preview; advanced JSON toggle; dirty-state tracking; both route-level and pop guards; validation/save feedback.

**Recommendation:** keep a dedicated advanced editor with clear parent skill context. Organize Basics, Request, Inputs, Access, and Preview. Defer rare JSON/nested-schema fields behind advanced controls while preserving them for complex tools. Avoid merging this form into ordinary connection setup.

### UX-28 — Request preview should explain what has and has not been validated

- **Task step/view:** S24 → Preview request.
- **Evidence:** E20; preview calls the request renderer with generated preview inputs, then displays method/url/headers/query/body. It is separate from executing an external request.
- **User problem and impact:** a valid rendered request can be interpreted as a working integration, even though access, endpoint behavior, and real input values have not been tested.
- **Severity:** low. **Confidence:** low; the interpretation is a hypothesis.
- **Change:** explain “Preview using sample inputs; no request is sent.” Distinguish template validation from any future controlled test result. Do not add a live execution button without a separately reviewed consequence and permission design.
- **Preserve:** preview usefulness, structured validation, redaction, and no-side-effect preview behavior.
- **Verification:** ask the author what Preview request proves. They should distinguish rendered structure from successful service execution, and understand sample inputs.

## S25 — Credential types list

**Purpose:** list schemas that define fields for credentials. **Strengths:** search, duplicate action, empty/no-match states, field-description help in editing, and a dedicated source entity.

**Recommendation:** move it under Connections → Saved credentials → Credential types (advanced). Keep a direct contextual entry from custom skill/tool authoring. Apply UX-03 to all headings, empty states, search labels, duplication feedback, and destructive copy.

**Do not merge:** the schema list and saved secret values into a single row type. A type may be shared by several saved credentials and skills. A person must know which is being changed before an action.

**State checks:** no types, filtered no matches, load failure, duplicate in progress, duplicate error, type used by credentials, and contextual return after creating a type.

## S26 — Credential type editor

**Purpose:** author title/slug and ordered fields with variable, description, optional/secret flags; validate mandatory secret presence; protect existing usages from incompatible edits/deletion.

**Strengths:** at least one secret field is required; duplicate/empty field-variable validation; field movement semantics/tooltips; schema-conflict and deletion-conflict handling; Manage credentials recovery; dirty protection; slug copy.

### UX-29 — Dependency effects become clearest only when a schema action fails

- **Task step/view:** S26 edit/delete a type already used by credentials, skills, or tools.
- **Evidence:** E21; localized schema/delete conflict messages include affected fields and counts, and conflict feedback offers Manage credentials. The form centers field authoring rather than an up-front usage overview.
- **User problem and impact:** an author may discover shared consequences only after trying a change. Generic “Delete credential” copy compounds the type/value ambiguity addressed in UX-03.
- **Severity:** medium. **Confidence:** medium; proactive absence should be confirmed visually.
- **Change:** show “Used by” credentials/skills/tools before schema editing and a consequence preview for incompatible changes. Link affected objects and preserve a return to the unfinished type task.
- **Preserve:** authoritative conflict enforcement, mandatory-secret validation, immutable usages when blocked, and safe duplication.
- **Verification:** change a field used by saved credentials. The person should predict whether the change is permitted, identify affected objects, and resolve the prerequisite without losing their draft. Attempt deletion with dependencies and confirm no silent detachment.

## S27 — Markdown editor

**Purpose:** edit a parent form's Markdown, preview it, and return the edited text. It is reused by agent prompts, skill descriptions/content, resource content, and tool description editing.

**Strengths:** preview mode; undo/redo/formatting/link controls; dirty guard; character constraints from parent; source selection/focus restoration; keyboard handling for Markdown indentation.

### UX-26 — “Save” in the Markdown editor applies a draft rather than persisting the parent

- **Task step/view:** edit agent instructions or skill/resource content → Markdown Save → parent form.
- **Evidence:** E22; `_save` pops a String result. Parent editor handlers update their controllers; the parent object's Save remains a separate operation. The child title is generically “Markdown editor” and its action tooltip is Save.
- **User problem and impact:** a person may think the object is saved and leave the parent, or be uncertain why another Save is required.
- **Severity:** medium. **Confidence:** medium.
- **Change:** title the field being edited, such as “Edit agent instructions”; label the child action Apply changes or Done, with “Applies to this draft; save the agent to finish” where the distinction remains necessary.
- **Preserve:** reuse, preview, undo/redo, character limits, unsaved confirmation, and keyboard focus. If autosave is considered later, its scope and failure behavior need their own design.
- **Verification:** edit a prompt, apply it, and navigate away without parent Save. The participant should predict the outcome; the app must preserve a draft or offer accurate save/discard recovery.

## Save and exit contract

| Context | Action | Result | Leaving before action |
| --- | --- | --- | --- |
| Child text editor | Apply changes | Parent draft updated | Confirm discard of changed text |
| Agent/skill detail | Save agent / Save skill | Object persisted | Preserve or confirm discard |
| Resource editor | Save resource | Resource persisted, parent section updated | Preserve or confirm discard |
| Template tool editor | Save tool | Definition persisted after validation | Existing onExit/pop protection retained |
| Credential type editor | Save credential type | Schema persisted if dependencies permit | Guard draft and disclose conflict |
| Connection setup | Connect / Save credential | Access/configuration saved with truthful verification status | Guard safe draft; clear transient secrets appropriately |
| Immediate setting | Specific toggle/choice | Applied immediately, visible status | No fictional Save requirement |

## Consolidation decision

Share editor conventions and components, not a giant universal form. Field context, ownership, save result, permission scope, and recovery differ. A sheet can host a short edit; a rich request/schema editor should retain ample space and a deep link or recoverable task identity. Desktop side panels and mobile full-screen editors are acceptable adaptations if their behavior remains the same.

## Implementation checkpoint

The source assessment above describes revision `c0527f8`. The working-tree implementation now shares active-route draft guards across object editors and workspace creation. Embedded provider setup delegates to that same exit owner while its standalone form keeps its own protection. Accepted workspace/entity changes recreate one-time editor state; cancellation retains the original draft. Persisted A/B tests verify that Save updates the intended agent, credential type or connection and retains each connection's stored ciphertext.

The Task 1 scoped review approved both repaired issues and the mechanical cleanup. The final tests and zero-diagnostic strict scan pass. [Execution evidence](14-execution-evidence.md#task-1-verified-handoff) records commands, counts, failure reproductions and limits. UX-25 implementation is verified across shared exits, query-context changes and nested Markdown; its final validation remains open. Task 5 verifies UX-26 to UX-28 and the resource action label. Task 6 owns UX-29 dependency usage and authoritative schema safety. No native device or participant result is claimed by the widget checks.


## Verified nested editor clarity

All six production Markdown launchers now name the edited field, explain the parent-save boundary and use Apply changes. Cancel uses the dirty exit guard; Keep editing retains exact text, selection/composing and editor focus. Existing limits, undo, preview, indentation and completed-close behavior remain intact. Resource actions say Save resource and report successful child persistence from the retained parent without saving its independent draft. Tool previews identify sample inputs and state that no request is sent and remote access is unverified.

Task 5 checks, strict analysis and independent scoped review pass. [Verified handoff](14-execution-evidence.md#task-5-verified-handoff) preserves failed commands and their repairs. UX-29 usage/schema safety is active in Task 6. Current readable captures, native keyboard/assistive technology and participant interpretation remain separate checks.


Task 6 dependency usage and schema safety is verified after two repair rounds. Used by includes disabled/reference-only dependencies without reading secrets, links retain the parent draft, and schema impact includes new required fields. Authoritative local ownership/deletion and current-schema cloud writes protect dependencies; unsupported credential aliases reject while supported legacy skill usage and reads remain. All I1–I4 are approved with zero open/new/deferred findings. Final server safety passes 20 cases, and exact app identity retains strict/test evidence. UX-29 final captures, joined tasks and external validation remain open. [Verified handoff](14-execution-evidence.md#task-6-verified-handoff) records commands, failed history and limits.

## Task 7 validation checkpoint

All six actual Markdown contexts execute English/Spanish title, limit and Apply boundaries; over-limit input remains in the editor and legal input returns to the actual parent draft. Actual resource/tool persistence and Used by→related skill→same dirty schema return execute. Reviewed authoritative local/cloud schema and credential mutation safety is retained. Native editor input, assistive-technology output and participant draft/persistence prediction remain unverified. See [current coverage](15-validation-coverage.md#current-implementation-evidence--task-7) and [execution evidence](14-execution-evidence.md#task-7-final-attempt-2-results-and-bounded-correction).
