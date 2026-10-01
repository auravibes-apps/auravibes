# Screen understanding, states, and accessibility verification

[Audit index](README.md) · Findings UX-30–UX-32

## Purpose

Every screen should explain what it is for, which object/scope it affects, what is ready, what is missing, and what happens next. This report provides proposed language and state requirements for the consolidation work. Source evidence establishes some risks; visual and assistive-technology outcomes remain unverified.

## Shared vocabulary

| Current concept | Proposed user-facing name | Explanation or boundary |
| --- | --- | --- |
| More | Explicit destinations | Chats, Agents & skills, Connections; avoid a generic management label |
| App/global preferences | App settings | Appearance and app information |
| Workspace compaction settings | Workspace settings → Conversation context | Automatic summarization/context policy; advanced model budgets separately |
| Agent | Agent | Reusable instructions, skills, and behavior for chats or delegation |
| Skill | Skill | Reusable instructions/capabilities available to agents and conversations |
| App/User skill source | Built-in/Custom, if accurate | Ownership and whether content can be edited |
| Model provider | AI provider | Supplies available models; choose the model in chat |
| Service Connections / Connections | Connections | Access to AI and services in this workspace |
| MCP server | Service integration; MCP in details | Technical protocol remains visible for configuration/diagnosis |
| Credential Definition | Credential type | Fields a saved credential must contain; no secret values saved here |
| Skill Credential | Saved credential / Access for [skill] | Named saved access values used by a skill/service |
| Service Skill Credential | Connect [service] / Service access | Use the intended task rather than internal category as the main label |
| Enabled | Enabled in this workspace | Does not alone guarantee access, context preparation, or tool permission |
| Ready | Qualified status | Access ready, Ready in context, or Ready to chat; avoid one universal promise |
| Visible in / Agent type | Available in | Chat selection, delegated tasks, or both |
| Markdown Save | Apply changes | Returns edited text to the parent draft |
| Resource Save skill | Save resource | Persists the resource only |

These names are recommendations to test. Domain IDs/enums need not change to match them. Update both English and Spanish intentionally; literal word substitution is not enough.

The Spanish `more_screen.title` currently reads “Configuración,” while English reads “More,” and Intro's Spanish skip guidance directs people to “Más.” The destination therefore changes meaning across labels/locales. Include this in UX-01/UX-02 remediation and review the full navigation vocabulary together. Credential type/value ambiguity also exists in Spanish.

## Proposed screen descriptions

| Screen/destination | One-sentence purpose | Main action examples |
| --- | --- | --- |
| Chats with no usable AI | “Connect AI and choose a model to start a conversation in [workspace].” | Connect AI / Choose model |
| Agents list | “Reuse instructions and skills across chats.” | Create agent / Use in chat |
| Agent editor | “Describe when this agent should be used and how it should respond.” | Create agent / Save agent |
| Skills list | “Manage reusable instructions and capabilities for this workspace.” | Open skill / Create custom skill |
| Skill detail | “Configure this skill's instructions, access, resources, and tools.” | Save skill / Set up access |
| Connections | “Connect AI and services, and fix access that needs attention.” | Connect AI / Connect service / Reconnect |
| Workspace tools | “Choose available actions and permission defaults for [workspace].” | Add built-in tool / Review source |
| Saved credentials | “Manage named access used by your skills and services.” | Add credential |
| Credential types | “Define the fields used by saved credentials; values are added separately.” | Create credential type |
| Manage workspaces | “Open a local or cloud workspace, or connect another one.” | Open / Create / Connect |
| Cloud accounts | “Manage cloud identities used by this app.” | Log in / Reconnect |
| Workspace settings | “Conversation behavior for [workspace].” | Save context settings |
| App settings | “Appearance and information for this app.” | Change theme |
| Resource/tool editor | “Edit [object] for [skill].” | Save resource / Save tool |
| Child Markdown editor | “Edit [field] in the [object] draft.” | Apply changes |

Do not display all descriptions permanently if they become redundant for experienced use. Use first-use guidance, empty states, concise subtitles, and contextual help. Preserve target/scope information on consequential controls.

## State contract

| State | Required information | Action | Avoid |
| --- | --- | --- | --- |
| Loading | What is loading; prior safe content if available | Cancel/retry when appropriate | Blank destination with no explanation |
| Empty | What belongs here and whether anything is required | Create/connect appropriate object | Empty text reused as a normal navigation subtitle |
| No search matches | Query/filter context | Clear search/filter | Suggesting the workspace itself has no data |
| Prerequisite missing | Exact dependency and task it unlocks | Direct setup that returns here | “Create X first” with no link |
| Partial readiness | Which parts work and which do not | Fix missing access/context | One Ready badge that promises all tools work |
| Permission required | Operation, scope, consequence, target | Once / this chat / skip / stop as applicable | Collapsing different permission scopes |
| Unsupported capability | What is unavailable in this workspace/build | Supported alternative or explanation | Active control followed by a generic dead end |
| Error | Task failed; preserved state; recoverable cause | Retry / reconnect / return to parent | Raw error/framework screen or text-only dead end |
| Success | What changed and what is now possible | Continue original task | Generic success that leaves the user to navigate manually |
| Dirty draft | Which object is unsaved | Keep editing / Save / Discard | Treating child text application as final persistence |
| Destructive action | Scope, affected names/counts, local/cloud consequences | Explicit confirmation | Ambiguous Delete for mixed consequences |

### UX-30 — Capability differences surface as hidden or generic unavailable controls

- **Task step/view:** cloud chat customization or workspace tools.
- **Evidence:** E23; local supports native tools and conversation tool overrides, while cloud disables both. E16 gates native-tool addition, but ToolsManagementModal receives a support flag and can display only “This feature is not available in this workspace.” Chat entry code can still construct the modal.
- **User problem and impact:** someone moving between local and cloud workspaces can interpret a missing control or generic message as broken setup rather than an intentional capability boundary.
- **Severity:** medium. **Confidence:** medium; actual visible entry conditions need live checks.
- **Change:** capability-aware entry and contextual explanation, with a supported alternative when one exists. State the specific unavailable action and workspace scope. Avoid inventing a cloud tool-policy feature that the server does not implement.
- **Preserve:** enforcement, native-tool boundaries, OAuth capabilities, workspace identity, and accessible reasons for disabled controls.
- **Verification:** compare the same tasks in local/cloud, including model auth, native tools, conversation overrides, attachments, and offline operation. Verify the actual build/platform limits as well as the workspace capability enum.

### UX-31 — Route gates can leave loading or failures without task recovery

- **Task step/view:** open a workspace session or delegated conversation through a direct route.
- **Evidence:** E04; `_WorkspaceSessionGate` renders `SizedBox.shrink()` on loading and `ErrorWidget(error)` on error. `_SubAgentConversationView` renders `SizedBox.shrink()` for both loading and error, and plain not-found text for mismatched/missing data.
- **User problem and impact:** no visible status can look like a blank/broken app, and a framework error or unqualified not-found state gives no practical recovery for an important entry path.
- **Severity:** high. **Confidence:** medium; branches are confirmed, occurrence/duration are unknown.
- **Change:** user-facing loading, typed failure, Retry, and Return to parent/workspace controls. Preserve distinction between missing data, authentication required, transient network failure, and a forbidden/mismatched relation.
- **Preserve:** workspace session isolation and child-parent checks; do not expose a child whose relation fails validation simply to avoid an error.
- **Verification:** inject loading, network/auth failure, missing workspace, missing child, and mismatched parent. The person should know what is happening and recover without guessing an unrelated route.

### UX-32 — Load-error recovery differs between comparable management screens

- **Task step/view:** load Connections, credential types, resource detail, or an agent list.
- **Evidence:** E14/E20/E21/E27; Connections and credential types have text-only load-error renderers; resource load/not-found states also lack a local recovery action. Agents offers reload/load-more recovery. AppErrorWidget has an optional action, which callers must supply.
- **User problem and impact:** comparable transient failures require different workarounds; people may leave a task to retry or re-enter without knowing their data is preserved.
- **Severity:** medium. **Confidence:** medium.
- **Change:** a shared failure contract with task-specific Retry/Reconnect/Return, preserving safe state. Missing/deleted objects should offer parent navigation rather than endless retries.
- **Preserve:** localized typed errors, redacted diagnostics, list pagination, and prior loaded data when safe.
- **Verification:** fail each relevant provider once, recover it, and use the proposed action. Confirm correct scope, no duplicated mutations, and no loss of draft or selection.

## Accessibility: supported observations and unresolved tests

This is not a WCAG conformance report. Screenshots, computed colors, hit targets, and assistive-technology output were not available. Source confirms some semantic intent and likely review points, not successful accessible interaction.

| Lens | Source-grounded observation | Required live test | WCAG-relevant area |
| --- | --- | --- | --- |
| Navigation names/selection | Sidebar items provide semantic labels; conversation selection is handled separately | Read names and selected state with screen reader at both shell widths | 2.4.6, 4.1.2 |
| Workspace status | Switch loading has a status semantic role; focus/retry logic exists | Verify announcement, focus restoration, and canceled switch | 2.4.3, 4.1.3 |
| Icon actions | Many have tooltips/semantic labels; other simple back/save controls rely on shared components | Inspect runtime accessible names for back, close, save, add, bulk actions | 4.1.2, 2.5.8 |
| Form errors | Required-field and typed/localized error text exist | Verify field association, announcement, focus order, password-manager behavior | 3.3.1, 3.3.2, 3.3.3 |
| Modal interaction | Several overlays unfocus before opening and some return focus | Keyboard-only trap/escape/return tests for each overlay and nested setup | 2.1.1, 2.1.2, 2.4.3 |
| Tab versus editor input | Markdown handles Tab for list indentation | Ensure keyboard users can leave the editor and reach toolbar/save | 2.1.1, 2.1.2 |
| Status badges | Connection status includes text as well as color | Measure contrast for all themes/accent hues, verify label announcements | 1.4.1, 1.4.3, 4.1.3 |
| Responsive reflow | Shell changes at 960; connection selector has eight labels | Narrow viewport, text enlargement, landscape, keyboard, and Spanish expansion | 1.4.4, 1.4.10 |
| Motion/live output | Loading, streaming, retry, and drawer transitions exist | Reduced motion and announcement frequency; avoid excessive live-region chatter | 2.2.2 where applicable, 4.1.3 |
| Destructive consequences | Confirmations disclose local/cloud differences | Screen-reader reading order; action distinction; sufficient target separation | 3.3.4 where applicable |

References identify areas to verify, not confirmed violations. Test against the product's chosen accessibility target with the runtime implementation. A screenshot alone would still be insufficient for keyboard, semantic, and screen-reader claims.

## Per-screen verification boundary

The shared checks above apply to all S01–S27. Prioritize screens with high-impact actions: onboarding/creation, connection setup, dirty editors, cloud members/ownership/deletion, tool approvals, and workspace switching. Then cover list search/filter/selection, text editing, settings, and read-only child/resource states. Record a named blocker for any screen that cannot be captured or exercised.

## Implementation checkpoint

The source assessment above describes revision `c0527f8`. Workspace and child-conversation gates now show localized loading, Retry and relevant return actions. Controlled tests cover recovery from a failed workspace gate, exact child/workspace/parent identity checks and read-only child rendering. Retained workspace data keeps the shell mounted during refresh. Failed workspace selection restores the draft and focus; retries require fresh consent.

[Execution evidence](14-execution-evidence.md) records these behavior checks and the approved Task 1 repair review. Task 3b1 also verifies failed-session auth reachability, exact-account recovery and permanent malformed/missing-workspace recovery while preserving data-route gates. Task 3b2 verifies truthful model prerequisites and child/activity orientation. UX-31 still needs the final screen/route and native checks. Task 4 verifies comparable connection/tool retry, typed missing-record recovery and local/cloud/platform capability guidance. Its narrow drag/inset regression passes controlled widget checks. UX-32 and UX-30 still require the final coverage reconciliation; rendered accessibility, real native keyboard/screen-reader checks and participant observations need their own evidence. The passing widget checks do not establish WCAG conformance.


Task 5 adds reviewed availability/access/context vocabulary and contextual nested-editor save boundaries in English and Spanish. Its retained-data refresh repair preserves independent parent drafts after setup. This is controlled behavior evidence; current visual, contrast, target, focus and assistive-technology acceptance remains tracked in Task 7. [Authoring handoff](14-execution-evidence.md#task-5-verified-handoff).

Task 6 adds recoverable metadata-only usage before schema editing and localized consequence previews. Its two repair rounds verify local ownership, supported legacy skill references and current-schema cloud mutation safety, including direct and secret-write paths. This provides controlled dependency evidence; current layout, reading order, focus/target and participant checks remain in Task 7. [Credential safety handoff](14-execution-evidence.md#task-6-verified-handoff).

## Current measured validation checkpoint

Task 7 executes all 29 current screen implementations and35 typed endpoints, actual older-history/approval/parent-return/capability actions and representative bilingual reflow. Source-based observations above remain attached to the original revision. Current named contrast/target/focus measurements and their precise limits are recorded in [15](15-validation-coverage.md#current-responsive-and-accessibility-evidence).

Actual pixels expose and repair narrow Skills/Tools sort controls and workspace-policy overflow. Cloud empty Tools now explains the service alternative while preserving enforced native-tool restrictions. Neutral badges use the correct surface background: actual light/dark text contrast improves from 1.724092:1/1.0:1 to15.89277:1/17.31302:1. Named NewChat controls pass measured contrast,48×48 targets, selected semantics and Tab/Enter navigation. These results do not establish native screen-reader output, live announcement quality, every overlay's keyboard behavior, every accent or WCAG conformance. The complete captured-source acceptance, browser/Linux results and fresh whole-change review remain active.
