# UX audit implementation plan

[Progress and evidence](progress.md) · [Approved consolidation](08-screen-consolidation.md) · [Validation contract](11-validation-plan.md)

The user has authorized finishing the audit plans. This plan orders that work and records its interfaces. It does not close findings by itself. The original audit describes source at `c0527f8`; implementation results belong in the progress file and linked closure notes.

## Global constraints

- Preserve local and cloud workspace ownership, child/parent conversation identity, read-only built-ins, permission choices, and capability enforcement.
- Preserve every existing deep link and contextual query, including credential definition and app skill IDs. Validate new and existing task return paths against the current workspace.
- Never present a saved connection, stored account, or prepared instruction as proof that remote access works.
- Confirm an active draft before persisting a workspace change. Cancellation keeps the current route, draft, focus, staged media, and saved workspace. Hidden branch drafts must not cause unrelated prompts.
- Keep repository and SDK calls below UI. Reuse existing usecases and providers. Add no database migrations for presentation changes.
- Localize all user-facing additions in English and Spanish. Run generators for generated sources; never edit generated files by hand.
- Use meaningful regression tests for behavior changes. Record commands, outcomes, durations, and failures. Participant results and native device checks require real evidence.
- Keep `progress.md` and the audit files. Do not publish, push, merge, send messages, or mutate production accounts as part of this work.

## Task 1: Shared draft exits and route recovery

User goal: leave or switch context without silently losing work, and recover from a loading or failed route.

Files: `lib/router/workspace_route.dart`, existing editor screens in agents, skills, service connections and workspaces; existing workspace switcher; new shared guard/state widgets only where multiple callers need them. Package root is `apps/auravibes_app/`.

Produces: one active-route draft confirmation contract that shell navigation and workspace switching can call before mutation; route `onExit` protection for editors; visible loading, unavailable and retry states for workspace and child-conversation gates. Preserve the existing skill-tool guard API or migrate all callers together.

- [x] Reproduce route replacement and workspace-switch draft losses in focused tests. The route-loss and failed-focus red results are recorded in [14-execution-evidence.md](14-execution-evidence.md).
- [x] Protect agent, skill, resource, tool, credential type, connection and workspace-creation drafts, including in-flight save and reverted-clean states.
- [x] Keep Back, router replacement and shell navigation consistent without double confirmation.
- [x] Confirm before workspace selection persistence; preserve debounce, queue, failure and retry behavior.
- [x] Replace blank/framework route states with localized loading, retry and safe return actions while retaining identity checks.
- [x] Verify the changed route, guard, editor and switcher tests and record the shared API for Task 2.

Findings: UX-25, UX-31, shared part of UX-32. Review focus: hidden routes, saving races, cancellation before selection persistence, and child identity.

Task 1 execution is verified, including the late imperative Markdown exit repair. [Final evidence](14-execution-evidence.md#task-1-verified-handoff) records focused tests, a zero-diagnostic strict scan and scoped review approval. Native device and participant limits remain explicit in Task 7.

## Task 2: Navigation, scope and contextual destinations

User goal: find chats, agent/skill configuration and connections directly, and understand which workspace a change affects.

Files: sidebar and responsive drawer wrappers, typed workspace routes, settings screens, workspace selector, Agents/Skills and Connections/Tools list widgets. Consumes Task 1's active-route guard.

Produces: Chats, Agents & skills, Connections as primary destinations; shared workspace control; app/workspace/account scope separation; related local navigation. Keep More as a compatibility directory and Models as an alias.

- [x] Classify selected destinations from the actual route, including child editors and direct entry.
- [x] Keep old URLs while removing misleading More page stacks beneath core destinations.
- [x] Add shared workspace header actions and split workspace compaction from app appearance settings.
- [x] Group Agents/Skills and Connections/Tools through related views; put credential types under saved credentials.
- [x] Preserve workspace-specific search/filter/sort/page context through edit and return.
- [x] Add reciprocal agent/skill links and source-specific tool repair links.
- [x] Verify typed locations, selected semantics, old deep links, settings persistence and 959/960 layouts.

Findings: UX-01 to UX-05, UX-09, UX-21, part of UX-30. Review focus: no cross-workspace object IDs, source identity, meaningful Back, and scoped settings.

Execute this task in two reviewed subdivisions. Task 2a establishes route classification, primary destinations, the shared workspace control and guarded workspace settings. Task 2b adds the related list views, retained search/filter/page state, accurate compatibility wording and reciprocal/source links. The original Task 2 checklist closes only after both pass.

Both subdivisions are verified and reviewed. [Task 2a handoff](14-execution-evidence.md#task-2a-verified-handoff) and [Task 2b handoff](14-execution-evidence.md#task-2b-verified-handoff) record passing focused checks, zero-diagnostic strict scans and approved repairs. Task 7's current-source route captures are accepted; exhaustive route variants and native/participant results remain limited.

## Task 3: Onboarding, workspace and account tasks

User goal: create or connect a workspace, add an account, configure AI and reach chat with truthful status.

Files: Intro, create-workspace forms/screens, cloud-account forms/screens/providers, cloud workspace providers/screens, workspace manager and conversation orientation widgets.

- [x] Make cloud-first onboarding executable using shared auth forms while no workspace exists.
- [x] Preserve typed workspace names across account detours and validate auth/task return paths.
- [x] Give provider setup an origin-aware return; distinguish workspace created, connection saved, authorization pending and chat ready.
- [x] Show child conversation/parent/read-only context and truthful current activity.
- [x] Separate opening connected workspaces from discovering available ones in the existing manager.
- [x] Itemize local deletion versus cloud mirror removal and retain partial-failure reporting and safe active-workspace fallback.
- [x] Remove the duplicate auth chooser from normal entry; clarify registration/reset stage, target email and success feedback.
- [x] Include canonical server origin in cloud account/workspace query identity and report verified, expired, checking and unknown health accurately.
- [x] Verify local and fake-cloud journeys, cancellation, auth errors, account-origin isolation and bulk consequences.

Findings: UX-06 to UX-08, UX-10 to UX-16. Review focus: zero-workspace routing, unsupported production email delivery, account/server identity and OAuth pending state.

Production email delivery is a known external blocker: the server only logs codes in development. UI work must not claim production email has been configured.

Execute this task in reviewed subdivisions. Task 3a establishes origin-aware cloud identity and health, connected/discovery management, bulk consequences and workspace detail. Task 3b1 uses those interfaces for shared authentication, exact-account recovery, validated returns and typed failed-workspace recovery. Task 3b2 uses the reviewed auth callbacks for zero-workspace onboarding, retained creation intent, truthful setup handoff and conversation orientation. Task 3a is verified after its reviewed repair, 172 passing cases and zero-diagnostic final scan; see the [handoff](14-execution-evidence.md#task-3a-verified-handoff). Task 3b1 is verified after 33 affected passing cases, zero-diagnostic final scan and clean scoped review; see the [auth handoff](14-execution-evidence.md#task-3b1-verified-handoff). Task 3b2 is verified after 55 covering cases, final Intro 13/13, zero-diagnostic final scan and a scoped review approving both repairs; see the [first-use handoff](14-execution-evidence.md#task-3b2-verified-handoff). All three subdivisions pass, so the original Task 3 implementation checklist is closed. Actual email delivery and final visual/native/participant validation remain separate unfinished requirements.

## Task 4: Connections, tool sources and prerequisites

User goal: find the right connection, repair its access, or create the required credential type and resume the task.

Files: service connection screens/widgets/providers, credential-type creation result, model-provider widget and tool-source list.

- [x] Separate connection kind from health; apply contextual type choices without making users choose an unrelated kind first.
- [x] Add a missing-type action that returns the exact created type and resumes the parent draft.
- [x] Preserve requested definition and skill identity; never substitute a different type for a skill requirement.
- [x] Use specific edit titles and source repair actions, with parent list state retained.
- [x] Explain local/cloud/platform restrictions beside affected controls.
- [x] Add retry/return recovery for loading, list and editor failures without exposing secrets.
- [x] Verify mixed connection fixtures, staged prerequisites, draft retention and source identity.

Findings: UX-17 to UX-20, remaining UX-04, UX-30, UX-32. Review focus: context query preservation, disabled/missing definitions, masked secrets and actual platform support.

Task 4 and fix round 1/5 are verified: all seven requirements have passing controlled evidence, zero-diagnostic final strict analysis and approved scoped review with zero open findings. `SkillCredentialDefinitionEditRoute(returnCreated: true)` preserves the exact persisted prerequisite result; default completion remains unchanged. Final visual/native/participant validation remains separate. [Verified handoff](14-execution-evidence.md#task-4-verified-handoff).

## Task 5: Agents, skills and nested authoring

User goal: understand availability, save a skill and continue configuring it, and apply nested Markdown changes to the correct draft.

Files: agent/skill detail and list screens, skill create route completion, conversation skill picker, Markdown launcher/editor, resource and tool editors/previews.

- [x] Distinguish saved/enabled/available roles and show missing or disabled dependencies beside the affected controls.
- [x] Continue first-save skill creation into its detail editor with tools/resources available.
- [x] Qualify credential/instruction availability separately from chat context readiness; retain Add and Use now semantics.
- [x] Give Markdown editors contextual titles, Apply changes, a parent-draft hint and guarded Cancel.
- [x] Use resource-specific save labels and truthful persistence feedback.
- [x] Label sample-input previews and state that they do not send a request or verify remote access.
- [x] Verify first-save continuation, picker readiness combinations, read-only built-ins, resource guards and Markdown limits/undo/preview.

Findings: UX-22 to UX-24, UX-26 to UX-28. Review focus: no false access promises, parent draft versus persisted object, and disabled dependent objects.

Task 5 and fix round 1 are verified: separate availability/access/context states, first-save continuation, contextual draft-only Markdown, guarded Cancel, resource feedback and sample-preview explanations have reviewed controlled evidence. Both retained-data refresh findings are addressed; final strict/hash checks and scoped review pass. Current visual/native/participant validation remains separate. [Verified handoff](14-execution-evidence.md#task-5-verified-handoff).

## Task 6: Credential type usage and schema safety

User goal: see affected credentials, skills and tools before changing a credential type and avoid silently detaching dependencies.

Files: credential definition detail/provider/model/usecase, local/cloud repositories and definition mutation usecases, schema diff logic and safety tests.

- [x] Query usage metadata, including disabled objects, without decrypting credential values.
- [x] Show Used by before editing and link to related objects while retaining the schema draft.
- [x] Explain actual schema changes and impacts, including newly added required fields.
- [x] Enforce the same authoritative dependency checks for local and cloud deletion, even with zero saved credentials.
- [x] Verify disabled/reference-only fixtures, required-field additions, secret-free usage reads and rejected unsafe mutations.

Finding: UX-29. Review focus: complete usage counts, cloud/local parity, mutation-time checks and no secret reads.

Task 6 is verified after two repair rounds: all I1–I4 are addressed with zero open/new/deferred findings. Final server safety passes 20 cases; exact app identity retains its strict/test evidence. Disabled/reference-only metadata, supported legacy skill usage, retained parent links, actual schema impact and authoritative local/cloud writes are reviewed. Final joined-task/capture/native/participant validation remains separate. [Verified handoff](14-execution-evidence.md#task-6-verified-handoff).

## Task 7: Validation, evidence and audit closure

User goal: review exactly what changed and which checks still require a person or native platform.

- [x] Run focused regression commands after each task. Final-source `validate:quick` passes exit 0/393.910s on `4aac0aa43f3aa9f53f735f14698b4f091ce3382000e8ff0bed8e7ff1ebd66866`; generated-output inventory and 426-input parity are reviewed without hand edits. Exact result: [final aggregate](evidence/final-aggregate-after-review.json).
- [x] Build deterministic local/cloud, disabled/dependent, child-conversation and mixed-connection fixtures; record all 29 current screens and 35 endpoints. The final 78-case matrix has 76 accepted images; eight fixture dispositions are in [15](15-validation-coverage.md#final-current-source-validation-2026-10-01).
- [x] Verify representative reflow at narrow/wide sizes, 959/960, English/Spanish and enlarged text with actual production widget evidence. Settings overflow and Skills/Tools sort squeeze have red-to-green repairs; all-screen/every-variant and native keyboard behavior remain outside this claim.
- [x] Obtain the final whole-change reviewer verdict on the frozen source and reconciled audit handoff; spec and quality both pass, with zero open/new/deferred findings. The reviewer report is [here](evidence/final-whole-change-review.md).
- [x] Reconcile every audit file and status row; the documentation link/source-anchor check and `git diff --check` pass.
- [x] Record actual participant, production email/catalog, production email-delivery, native macOS/iOS keyboard/assistive-technology checks as blocked by absent prerequisites; stop the overall goal as blocked after local work and review close.

## Execution contract review

This review records shared files and interfaces before the dependent tasks begin. Tasks 1–6 have passed scoped spec/quality reviews; the final reviewer handoff is listed in Task 7.

| Tasks | Producer and consumer | Check / decision |
| --- | --- | --- |
| 1 / 2 | Active-route guard, workspace switcher and typed routes -> shell, shared selector and workspace policy form | Navigation consumes the existing preflight API. The switcher owns confirmation before persistence. |
| 1 / 3 | Drafted workspace creation, New Chat and route gates -> onboarding and account detours | Preserve guard ownership and staged media; do not duplicate confirmation or clear a draft during auth. |
| 1 / 4 | Connection draft scopes -> contextual creation and repair | Prerequisite child routes return to the retained parent; replacing a kind needs guarded draft handling. |
| 1 / 5 | Agent, skill, tool and resource scopes -> authoring and readiness | New save destinations may clear approval only after persistence. Markdown applies a field draft. |
| 1 / 6 | Credential type draft scope -> usage and schema impact | Usage links push related routes; destructive changes still pass authoritative usecase checks. |
| 1 / 7 | Guard/gate fixtures -> final integration checks | Preserve failure, focus, identity and lifecycle regressions in the final patch. |
| 2 / 3 | Shared selector, workspace settings and account destinations -> first-use and manager flows | Opening, creating, connecting and account health stay distinct; preserve old URLs. |
| 2 / 4 | Connections local views and retained list state -> independent kind/health filters | Task 4 updates filter semantics in the existing state owner; it does not add a duplicate list workflow. |
| 2 / 5 | Agents/Skills local views and reciprocal links -> authoring continuation | Reuse typed routes and retained list state. Do not infer complete agent usage from a paginated list. |
| 2 / 6 | Credential types under saved credentials -> schema usage links | Labels distinguish values from types; every related object remains workspace scoped. |
| 2 / 7 | Route classifier, settings and shell fixtures -> layout/compatibility checks | Test actual selected destination, old paths, direct entry and 959/960 behavior. |
| 3 / 4 | Account health, provider setup and task return validator -> connection readiness/repair | Stored or saved state cannot prove access. Validate contextual return paths in both flows. |
| 3 / 5 | New Chat readiness and conversation activity -> skill access/context status | Access availability and loaded context are separate; preserve approval and queue behavior. |
| 3 / 6 | Origin-aware cloud clients/sessions -> cloud metadata usage | Use the owning account origin. Usage queries must remain metadata only. |
| 3 / 7 | Controlled auth/workspace fixtures -> first-use and account tests | Fake delivery establishes UI behavior only; real production delivery remains a separate prerequisite. |
| 4 / 5 | Exact credential prerequisite result -> skill readiness and setup | A skill's requested type cannot be satisfied by creating a different type. |
| 4 / 6 | Credential type creation result and connection links -> usage/schema impact | Return the actual persisted type ID. Both editors reuse the existing guard. |
| 4 / 7 | Mixed connection and repair fixtures -> capability/recovery checks | Keep source IDs, transport restrictions, redaction and disabled controls covered. |
| 5 / 6 | Skill/tool dependency settings -> complete credential type usage | Count disabled references and effective tool overrides; visibility is not a dependency filter. |
| 5 / 7 | Nested editor and readiness fixtures -> persistence/read-only checks | Preserve Markdown limits, undo, preview, built-ins and resource-specific persistence. |
| 6 / 7 | Local/cloud mutation and metadata fixtures -> safety verification | Test zero-credential references, added required fields and secret-free reads. |

| Task | Internal requirements checked | Result |
| --- | --- | --- |
| 1 | Dirty detection, confirmation, pending save, route recovery and listed regression scope | Consistent. Retained same-URL pages need instance-aware registration, as the active regression demonstrates. |
| 2 | Presentation destinations versus existing router branches, old paths, list state and policy draft | Consistent. Presentation indexes must not be used as router branch indexes. |
| 3 | Zero-workspace auth, origin identity, staged readiness and production delivery evidence | Consistent with a separate email-transport blocker. Local/fake-cloud work remains executable. |
| 4 | Contextual kinds, exact prerequisite identity, parent draft and platform restrictions | Consistent. Creating a type returns the persisted result to its parent. |
| 5 | Identity-stage first save, nested Apply changes and actual resource save | Consistent. Field application and persistence need different labels and feedback. |
| 6 | Disabled metadata, usage preview and authoritative mutation safety | Consistent. Fix reference-only deletion and added-required-field classification in both stores. |
| 7 | Focused checks, one final broad check/review, all-screen evidence and external prerequisites | Consistent. Blocked native or participant work is recorded as unfinished, never as an automated pass. |

Review focus: no task hidden by a file-level completion label, no unsupported runtime claims, and complete evidence links.
