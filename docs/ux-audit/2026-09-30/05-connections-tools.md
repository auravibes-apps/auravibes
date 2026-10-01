# Connections, model providers, and tools

[Audit index](README.md) · Screens S15–S18 · Findings UX-17–UX-20

## Goal and mental model

Connect access to an AI or external service, confirm what is usable, and configure the actions available in a workspace. A connection provides access. A model is a choice supplied by an AI provider. A tool is an action that may come from an integration, a skill, or the app itself. A credential type defines fields; a saved credential supplies values.

Grouping these tasks should reduce backtracking while preserving their different identities and consequences. This is a proposed explanation, grounded in current objects, rather than evidence that users already understand it.

## Current service setup paths

| Step | AI provider | Catalog integration | Manual MCP integration | Custom skill credential |
| --- | --- | --- | --- | --- |
| 1 | Intro/New Chat/Connections → New Connection | Connections → Browse MCP catalog | More → Tools → Add MCP | Skill detail/picker or Connections → New Connection |
| 2 | Model Provider form | Search/select service and option | Name, endpoint, transport, auth | Choose definition or app skill |
| 3 | Provider and supported auth flow | Required fields/authentication | Configure access | Enter name and fields/secret |
| 4 | Verify/connect before create where required | Verify, then Install | Test/connect and save | Save |
| 5 | Return to origin or Connections | Return to Connections with success | Tools list | Return to requesting skill/picker or Connections |
| 6 | Choose a usable model in chat | Inspect/enable exposed tools | Inspect/enable exposed tools | Retry skill readiness/use |

Evidence: E14–E16, E19, E26. Backend and OAuth completion were not exercised.

## S15 — Connections

**Current purpose:** unify model providers, skill credentials, app/service credentials, and MCP connections with metadata, health, search, actions, and catalog access.

**Strengths:** this is already a broad consolidation. It has useful connection statuses, targeted reconnect/refresh actions, MCP connection tests, redacted diagnostics, empty/filter/search states, and local model-catalog sync progress/error. Selected test specifications explicitly cover these behaviors; they were not run in this audit.

**Recommendation:** retain the unified destination and make it directly discoverable. Start with task/type views and one Needs attention control. Reveal authentication protocol and transport in detail/advanced views where they matter. Explain the Models alias and avoid inventing a new independent provider-list screen.

### UX-17 — One filter control mixes object type, auth mechanism, and health

- **Task step/view:** find an AI provider, locate a failing service, or find saved skill credentials in S15.
- **Evidence:** E14; the same `_ConnectionFilter` tab selector contains All, Model providers, Skill credentials, MCP servers, OAuth, Failed, Expiring, and Needs auth. Its enum holds a single selected filter.
- **User problem and impact:** someone cannot express “MCP servers needing authentication” in that selector, and sibling labels describe different kinds of category. Eight labels also need responsive verification.
- **Severity:** medium. **Confidence:** medium.
- **Change:** separate object type from health. Use task views such as AI providers, Services, Tools, and Saved credentials; offer All/Needs attention or a health filter within each. Keep auth mechanism as a secondary facet when useful.
- **Preserve:** search, metadata, status distinctions, expiring-token recovery, and a cross-type overview for troubleshooting.
- **Verification:** find one failed MCP service and one healthy AI provider in a mixed list. The participant should combine type and health without guessing which tab takes precedence. Test narrow widths and Spanish text.

## S16 — New connection

**Current purpose:** select Model Provider, Skill Credential, or Service Skill Credential, then render a specialized form. Contextual routes can preselect definition or app skill. Manual MCP setup and catalog setup enter through separate overlays.

**Strengths:** specialized AI-provider auth and verification; contextual credential selection from skills; masked secret fields; loading/disabled-save states; invalidation after save. The type selector is useful when entering from a general management destination.

### UX-18 — Missing credential type is a prerequisite message without an action

- **Task step/view:** choose Skill Credential in S16 when no credential definitions exist.
- **Evidence:** E15; `_NoCredentialDefinitionMessage` renders “Create a credential definition first.” Definition selection and value inputs depend on the definitions result. Definition authoring lives in another More destination.
- **User problem and impact:** the person reaches a blocked setup task and must work out where to create the prerequisite, then resume the original credential/skill task.
- **Severity:** high. **Confidence:** medium.
- **Change:** provide a contextual Create credential type action for custom authoring, preserving the requesting skill and unsaved name. For built-in/service credentials, use their declared fields without asking the person to author a schema.
- **Preserve:** type safety, mandatory secret fields, secret masking, and return context. Do not silently create a schema based on secret values.
- **Verification:** begin custom credential setup with zero types. Create the required type, return to the named credential form, save, and verify the original skill's readiness. A non-author configuring a built-in skill should not encounter schema creation.

### UX-19 — Contextual setup still asks the person to reconsider unrelated connection types

- **Task step/view:** Add credential from a skill, or Connect AI from Intro/New Chat.
- **Evidence:** E15/E19; routes supply initial type/definition/appSkillId, but `_ServiceConnectionCreateBody` still includes the broad type selector. Service Skill Credential and Skill Credential are adjacent labels describing implementation distinctions.
- **User problem and impact:** the person has already chosen the task but can be diverted into a different one. The type names do not explain whether they are adding service access or defining something reusable.
- **Severity:** medium. **Confidence:** medium.
- **Change:** use task-specific titles and lock the relevant setup context by default: “Connect AI,” “Add access for [skill],” or “Connect [service].” Allow Change connection type only from a general creation entry. Default to the origin's task rather than requiring classification.
- **Preserve:** all supported types, dedicated provider forms, and advanced manual connection options.
- **Verification:** from a skill asking for access, the person should identify the service and needed fields without learning the distinction between internal user/app skill credentials. From Connections, they should still be able to intentionally choose any supported setup path.

Dirty-state behavior for this screen is covered by UX-25. Grouping setup is not permission to discard form state when changing type or canceling OAuth.

## S17 — Edit connection

**Current purpose:** load provider, skill credential, generic connection, or MCP state; edit relevant fields; preserve or intentionally replace saved secrets; verify provider changes when required; save.

**Strengths:** existing dirty-pop confirmation, stored-secret placeholders, clear-secret intent, verification invalidation, expiry handling, and focused tests for secret behavior. Treat these as acceptance requirements for any consolidation.

### UX-20 — Generic edit title does not identify the service or access being changed

- **Task step/view:** open S17 from a connection row.
- **Evidence:** E15; `_ConnectionEditAppBar` always uses “Edit Connection,” while the form selects a type-specific implementation and may show provider IDs or stored-secret hints internally.
- **User problem and impact:** when opening from a direct link or returning from authentication, the person must infer which connection and workspace are being edited from the body.
- **Severity:** low. **Confidence:** medium.
- **Change:** name the connection in the title and show its type and workspace. Use explicit “Keep saved secret,” “Replace,” and “Clear” choices where current implicit placeholders are insufficient.
- **Preserve:** current secret protection and verification rules. Do not display a stored secret as a shortcut to greater clarity.
- **Verification:** with two connections to the same provider/service, open each directly. The participant should identify the correct target before editing; unchanged secrets must remain unchanged after a name-only save.

## S18 — Workspace tools

**Current purpose:** inspect grouped tools, enable/configure workspace defaults, add available native tools, add manual MCP, refresh, reconnect failed MCP groups, and reset permissions.

**Strengths:** overview copy explicitly says enable/configure; enabled count; reconnect appears for failed enabled groups; native-tool addition is capability-gated; permission reset has confirmation. These are meaningful controls to retain.

**Recommendation:** move this view into Connections → Tools and give each group a source link. Keep tool enablement and workspace permission defaults separate from connection authentication. Grouping should explain why connected does not automatically mean allowed in every agent/conversation.

**Related finding:** UX-04 covers split recovery. UX-30 covers unsupported conversation tool controls in cloud. A generic “Add tool” action should not ambiguously mean choose a native tool, connect a service, or author a template tool.

## Supporting controls and merge boundaries

| Control | Current role | Recommended role |
| --- | --- | --- |
| AddModelProviderWidget | Specialized provider selection, key/browser/device auth, verification | Keep specialized form within Connect AI task |
| McpCatalogBrowser | Search/select/configure/verify/install services | Guided Connect service entry; preserve verification and unsupported-option feedback |
| AddMcpModal | Manual endpoint/transport/auth setup from Tools | Advanced custom service entry inside the same Connections setup shell |
| AddToolModal | Pick/add known native tools | Tools view, labeled “Add built-in tool” if accurate for all options |
| ToolsManagementModal | Workspace or conversation-related tool selection/policy | Keep scoped near chat; explicitly label target and inheritance |
| ToolPermissionSelector | Ask/allow options | Keep policy meanings; add scope/effective summary where needed |

The catalog and manual setup can share one entry and reusable controls without forcing identical fields. Catalog-specific service metadata and manual endpoint configuration remain distinct modes. Do not remove or weaken verification to reduce visible steps.

## Proposed setup/detail contract

1. Entry states the outcome and workspace: Connect AI, Connect service, or Add saved credential.
2. The form shows only fields relevant to the chosen task; advanced details are reachable.
3. Authentication/testing distinguishes access verified from configuration merely saved.
4. Success says what is now available: model count, tool count, or skill access; do not equate availability with permission.
5. Continue returns to the requesting chat/skill/editor, or opens the relevant detail when initiated from Connections.
6. Failure names a recoverable cause and action; redacted technical details remain secondary.

## Validation priorities

Use controlled services for authentication failures, no-tools results, verification expiry, and unsupported protocol. Test provider creation from Intro and New Chat separately. Check custom credential zero-type recovery. Check that model/secret edits preserve existing values, and that catalog/manual setup do not create unintended duplicate connections.
## Implementation checkpoint for related views

Task 2b groups the existing routes into Connections views. Overview includes every actual connection kind. AI providers, Services and Saved credentials restrict rows to their existing domain kind. Tools retains its route and appears in the same local navigation. Saved credentials links to the advanced Credential types list.

The new query state belongs to a workspace and view. It restores the visible search field and filter after navigation. MCP tool groups push the connection editor using the actual server ID. Returning preserves the list query and expanded group. Native and template tool groups have no fabricated connection link.

Task 2b is verified and reviewed. The 16-case amended Tools suite verifies Save refresh, updated names/permissions and retained query/expansion. The final strict scan has zero diagnostics and scoped review has zero open findings. Task 4 subsequently verifies separate kind/health filters, blocked credential setup, contextual creation, capability guidance and load recovery. [Execution evidence](14-execution-evidence.md#task-2b-verified-handoff) records the checks and their limits. This checkpoint does not replace the original source assessment or establish remote access.


## Task 4 implementation closure

Task 4 and its inset/keyboard repair are verified and reviewed with zero open findings. Connections retains independent kind, health and OAuth facets within each workspace view. Contextual setup fixes the requested identity, offers exact credential-type creation, and returns the actual persisted type without replacing a missing or unknown requirement. Full-query draft preflight protects same-path context replacement.

Connection editors identify the saved connection, kind and workspace, preserve masked secrets, and distinguish missing records from retryable loads. Tools recovery retains source, search and group identity. Controlled local/cloud and simulated platform fixtures verify capability reasons; stored configuration remains distinct from verified remote access.

The 22-case repair suite, final zero-diagnostic strict scan, matching hashes and approved scoped review are in the [verified handoff](14-execution-evidence.md#task-4-verified-handoff). The inspected Linux MCP image passes deterministic layout comparison. Readable current captures, full history/native variants, real authorization and participant comprehension remain final validation work.

## Task 7 validation checkpoint

Actual Tools→named MCP editor→persisted source repair→retained Tools refresh executes while preserving source/group/tool permissions. Two distinct credential chains cover zero-type prerequisite creation and fixed required-type setup from an owning skill; the latter intentionally cannot substitute an unrelated type. Narrow Spanish Tools controls and the cloud empty hint are repaired with regressions. Live reconnect/provider authorization remains unverified. See [current coverage](15-validation-coverage.md#current-implementation-evidence--task-7) and [execution evidence](14-execution-evidence.md#task-7-final-attempt-2-results-and-bounded-correction).
