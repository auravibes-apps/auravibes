# Prioritized findings and delivery roadmap

[Audit index](README.md) · [Validation plan](11-validation-plan.md)

## Priority rules

P1 corresponds to high severity, P2 to medium, and P3 to low. Priorities assess likely task impact using source evidence; they are not observed incidence, estimated revenue, or implementation effort. Confidence is medium unless noted. No critical incident is claimed.

There are **8 high, 19 medium, and 5 low** findings. Exact behavior involving navigation history, draft exits, and visual hierarchy still needs runtime verification. A source-confirmed renderer or missing action is stronger evidence than a hypothesis about how frequently it confuses people.

## Complete finding register

Findings are ordered by severity, then stable ID. The delivery phases below account for dependencies and related small fixes.

| ID | Priority/severity | Confidence in task impact | Problem | Main evidence | Proposed outcome | Detailed finding |
| --- | --- | --- | --- | --- | --- | --- |
| UX-01 | P1 / high | Medium | Generic More hides core setup; seven unrelated-level entries | E01, E02 | Explicit task destinations | [02](02-navigation-audit.md#ux-01--a-generic-hub-hides-core-setup-and-exposes-advanced-tasks-too-early) |
| UX-02 | P1 / high | Medium | App and workspace/account scopes mixed | E03, E13 | Clearly separate app/workspace/account scope | [02](02-navigation-audit.md#ux-02--app-wide-and-workspace-scoped-settings-are-presented-as-one-scope) |
| UX-03 | P1 / high | Medium | Credential types called Credentials on arrival | E02, E20, E21 | Types and saved values distinguishable | [02](02-navigation-audit.md#ux-03--credential-definitions-lose-their-identity-on-arrival) |
| UX-06 | P1 / high | Medium | Cloud-first offer lacks account entry | E06, E10 | Actionable cloud-first journey or honest local-first copy | [03](03-onboarding-chat.md#ux-06--first-run-cloud-choice-has-no-matching-account-entry) |
| UX-07 | P1 / high | Medium | Ready and setup completion do not hand off to chat consistently | E06–E08 | Truthful readiness and origin-aware completion | [03](03-onboarding-chat.md#ux-07--ready-and-setup-completion-do-not-reliably-mean-ready-to-chat) |
| UX-18 | P1 / high | Medium | Missing type message has no prerequisite action | E15 | Create type then resume credential/skill | [05](05-connections-tools.md#ux-18--missing-credential-type-is-a-prerequisite-message-without-an-action) |
| UX-25 | P1 / high | Medium; low for untested exits | Draft guards missing/inconsistent | E15, E20, E25 | Safe draft contract across all exits | [07](07-editors-credential-authoring.md#ux-25--draft-protection-is-inconsistent-across-editors-and-navigation-exits) |
| UX-31 | P1 / high | Medium | Route gates blank/framework failure states | E04 | Loading/status/recovery without weakening checks | [09](09-content-states-accessibility.md#ux-31--route-gates-can-leave-loading-or-failures-without-task-recovery) |
| UX-04 | P2 / medium | Medium | Integration health and tools split | E14, E16 | Linked connection/tool lifecycle | [02](02-navigation-audit.md#ux-04--integration-identity-and-tool-availability-are-managed-in-separate-destinations) |
| UX-05 | P2 / medium | Medium; low for untested history | Shell context/reset/return unclear | E01, E07 | Stable orientation and task return | [02](02-navigation-audit.md#ux-05--navigation-establishes-weak-destination-context-and-inconsistent-task-return) |
| UX-08 | P2 / medium | Medium | Main guidance covers only no-provider state | E08, E09 | Correct next action for each chat blocker | [03](03-onboarding-chat.md#ux-08--readiness-guidance-is-centered-on-no-providers-not-the-full-prerequisite-state) |
| UX-09 | P2 / medium | Medium | Workspace switching tied to New Chat/manager | E05, E08 | Consistent shell switching with draft protection | [03](03-onboarding-chat.md#ux-09--workspace-switching-is-easier-to-discover-in-new-chat-than-elsewhere) |
| UX-11 | P2 / medium | Medium | Child chat does not explicitly explain parent/read-only role | E04, E11 | Parent relationship and return clear | [03](03-onboarding-chat.md#ux-11--child-conversation-needs-explicit-parent-and-read-only-orientation) |
| UX-12 | P2 / medium | Medium | Workspace opening competes with cloud discovery/admin | E10 | Open-first manager, secondary connect subtask | [04](04-workspaces-cloud.md#ux-12--workspace-opening-and-cloud-discovery-share-a-busy-lifecycle-surface) |
| UX-13 | P2 / medium | Medium | Mixed bulk deletion has different consequences | E10 | Itemized local/cloud outcome | [04](04-workspaces-cloud.md#ux-13--bulk-deletion-combines-different-consequences-behind-one-action) |
| UX-15 | P2 / medium | Medium | Auth titles/development recovery instructions obscure task | E13 | Account/verification stages and usable delivery guidance | [04](04-workspaces-cloud.md#ux-15--authentication-headers-and-recovery-copy-expose-implementation-steps) |
| UX-16 | P2 / medium | Medium | Static Signed in differs from expired-session guidance | E10, E13 | Consistent verified/expired/unknown health | [04](04-workspaces-cloud.md#ux-16--account-health-is-expressed-differently-across-screens) |
| UX-17 | P2 / medium | Medium | Filter mixes type, auth, and health | E14 | Independent task/type and health selection | [05](05-connections-tools.md#ux-17--one-filter-control-mixes-object-type-auth-mechanism-and-health) |
| UX-19 | P2 / medium | Medium | Contextual setup still exposes unrelated types | E15, E19 | Origin-specific setup with expert alternative | [05](05-connections-tools.md#ux-19--contextual-setup-still-asks-the-person-to-reconsider-unrelated-connection-types) |
| UX-21 | P2 / medium | Medium | Agent/skill relationship requires navigation inference | E02, E17, E18 | Shared destination and dependency links | [06](06-agents-skills.md#ux-21--related-agents-and-skills-have-independent-management-entries-with-little-relationship-guidance) |
| UX-22 | P2 / medium | Medium | Enabled/visibility/readiness can be conflated | E17 | Separate availability and dependency status | [06](06-agents-skills.md#ux-22--enabled-visibility-and-capability-readiness-can-be-mistaken-for-one-status) |
| UX-23 | P2 / medium | Medium | Skill child authoring appears only after first save/return | E18 | Explicit staged creation and configure-next action | [06](06-agents-skills.md#ux-23--new-skill-authoring-changes-available-sections-after-the-first-save-without-explaining-the-stage) |
| UX-24 | P2 / medium | Medium | Access/context/enablement status language fragmented | E18, E19 | Qualified readiness and Add/Use now clarity | [06](06-agents-skills.md#ux-24--access-enablement-and-conversation-context-readiness-need-a-consistent-vocabulary) |
| UX-26 | P2 / medium | Medium | Markdown Save applies draft, not parent persistence | E22 | Apply changes versus Save object | [07](07-editors-credential-authoring.md#ux-26--save-in-the-markdown-editor-applies-a-draft-rather-than-persisting-the-parent) |
| UX-29 | P2 / medium | Medium | Schema dependencies explained mainly at conflict | E21 | Up-front usage and effect preview | [07](07-editors-credential-authoring.md#ux-29--dependency-effects-become-clearest-only-when-a-schema-action-fails) |
| UX-30 | P2 / medium | Medium | Local/cloud unsupported controls need explanation | E16, E23 | Capability-aware entry and alternative | [09](09-content-states-accessibility.md#ux-30--capability-differences-surface-as-hidden-or-generic-unavailable-controls) |
| UX-32 | P2 / medium | Medium | Comparable load errors lack comparable recovery | E14, E20, E21, E27 | Retry/reconnect/parent actions | [09](09-content-states-accessibility.md#ux-32--load-error-recovery-differs-between-comparable-management-screens) |
| UX-10 | P3 / low | Low | Several AI status controls require interpretation | E11, E24 | Plain active-task summary with details retained | [03](03-onboarding-chat.md#ux-10--ai-activity-needs-a-single-plain-language-summary) |
| UX-14 | P3 / low | Medium | Add-account chooser duplicates auth choice | E13 | One clear auth entry | [04](04-workspaces-cloud.md#ux-14--the-account-chooser-repeats-a-decision-that-can-sit-on-the-login-screen) |
| UX-20 | P3 / low | Medium | Generic edit title omits connection identity | E15 | Named connection, type, and scope | [05](05-connections-tools.md#ux-20--generic-edit-title-does-not-identify-the-service-or-access-being-changed) |
| UX-27 | P3 / low | Medium | Resource action says Save skill | E20 | Save resource | [07](07-editors-credential-authoring.md#ux-27--resource-save-action-names-the-wrong-object) |
| UX-28 | P3 / low | Low | Preview can be interpreted as working service | E20 | Sample render versus execution boundary | [07](07-editors-credential-authoring.md#ux-28--request-preview-should-explain-what-has-and-has-not-been-validated) |

## Phase 0 — Establish live evidence and task contracts

**Scope:** capture the present behavior against the inventory before implementing broad merges. Record visual states, navigation history, draft behavior, and capability/role differences. Test the glossary and proposed grouping with representative tasks.

**Depends on:** a pinned Flutter environment, isolated dev app, deterministic local data, and a controlled cloud/service backend for relevant tasks.

**Exit conditions:** all S01–S27 have a current capture or named blocker; representative create/edit/read-only states are covered; first-run cloud and setup-return behavior is reproduced; claims about actual failures are updated to reflect results. Do not wait for a large research study to fix source-confirmed misleading labels or blank error branches.

## Phase 1 — Repair task blockers and trust gaps

**Scope:** UX-03, UX-06, UX-07, UX-18, UX-25, UX-31. Bring forward UX-15, UX-26, UX-27, and UX-32 where they touch the same task boundaries.

**Work:** truthful cloud-first path or corrected promise; origin-aware AI/credential completion; direct missing-type recovery; dirty-draft coverage; user-facing route recovery; explicit draft/save nouns. English and Spanish copy ship together.

**Depends on:** correct persistence and permission contracts; runtime reproduction for draft/history details.

**Exit conditions:** a first-time person can reach usable chat; contextual credential setup resumes the initiating task; no tested dirty exit loses work silently; missing route data provides an explanation and recovery. Existing secret verification and child-parent checks continue to hold.

## Phase 2 — Introduce navigation and scope grouping

**Scope:** UX-01, UX-02, UX-04, UX-05, UX-09, UX-17, UX-19, UX-21.

**Work:** explicit Chats / Agents & skills / Connections destinations; shared workspace selector; separate app/workspace settings; nested credential types; linked integration/tool views; independent health filters. Prefer adapting entry points before rewriting every URL.

**Depends on:** Phase 1 safe-return/draft contract, glossary validation, and per-old-route mapping.

**Exit conditions:** task-first navigation tests improve or remain clear for both first-use and expert participants; old deep links work; selected state and parent context are correct; local/cloud/role restrictions remain enforced.

## Phase 3 — Make configuration and runtime readiness coherent

**Scope:** UX-08, UX-11, UX-12, UX-13, UX-16, UX-22, UX-23, UX-24, UX-29, UX-30. Complete smaller UX-14, UX-20, UX-28 changes if validated.

**Work:** readiness summaries, child/parent orientation, staged skill authoring, open-first workspace manager, account health, itemized consequences, dependency overview, capability-aware control entry.

**Depends on:** authoritative health/readiness data and policy resolver behavior. Do not infer Ready solely from enabled or stored records.

**Exit conditions:** participants can explain current status and scope before acting, repair a missing dependency, and predict local/cloud destructive effects. Unknown and partial states remain truthful.

## Phase 4 — Verify visual hierarchy and accessibility

**Scope:** all screens, with UX-10 assessed against live status layouts.

**Work:** keyboard/focus, screen-reader names/state changes, reflow/text scaling, target sizing, contrast across supported themes/accent settings, reduced motion, Spanish expansion, and modal/editor escape paths.

**Depends on:** current screenshots and runtime controls. Accessibility-critical failures found earlier should be fixed immediately rather than deferred to this phase.

**Exit conditions:** documented target-specific test results, fixed actionable failures, and named limits. A screenshot set alone is insufficient for accessibility sign-off.

## Suggested work packages

| Package | Appropriate ownership | Required review focus |
| --- | --- | --- |
| Copy and scope contracts | Product/design with localization review | Task names, type/value distinction, scope, truthful readiness |
| First-use/task return | App routing and relevant feature owners | Draft, origin, direct entry, cancellation, workspace isolation |
| Navigation grouping | Product/design and app shell owner | Old links, selected state, responsive container, expert retrieval |
| Integration lifecycle | Models/tools/service-connections owners | Verification, source identity, native/skill tools, secret semantics |
| Reusable capability UX | Agents/skills owners | Independent objects, availability, context, effective permission |
| Cloud lifecycle | Accounts/workspaces owners | Role restrictions, identities, local/cloud removal, ownership |
| Accessibility validation | Design/QA and shared UI owner | Runtime behavior, target-specific evidence, meaningful remediation |

These are suggested ownership areas, not assigned people or externally created tickets.

## Measurement after validation/instrumentation

Potential measures: first usable message completion, correct first navigation choice, successful setup return, time to recover a broken integration, ability to explain permission scope, and unintended discard/removal reports. Establish baselines before claiming improvement. Instrument only the needed state transitions; exclude message contents, prompts, and secrets.

No numeric targets or effort estimates are supplied because usage data, team capacity, and backend/runtime constraints were not available.
## Implementation checkpoint

Tasks 1 and 2 are verified and reviewed. The patch protects active drafts, provides visible route recovery, replaces the primary More entry with explicit destinations, splits app/workspace settings and groups related lists with retained context. Exact MCP source links refresh saved names and permissions while preserving the expanded list.

All Task 3 subdivisions are verified and reviewed, including cloud lifecycle, authentication/recovery and first-use/chat repairs. Tasks 4–6 also pass their approved repairs. Task 7's final-source capture, aggregate and Linux virtual-display run pass; the native/device and participant limits are explicit in [progress.md](progress.md). [Execution evidence](14-execution-evidence.md) records failed attempts, repairs, and exact runtime identities.

## Task 7 validation checkpoint

Tasks 1–6 are implemented, reviewed and verified, including the final I1/I2/I3 repairs. Task 7 records actual 29-screen/35-endpoint rendering, all 17 scenario dispositions, eight fixtures, 78 accepted capture cases, passing aggregate validation and a current-source Linux journey. The whole-change review and documentation checks pass. External validation boundaries remain in [current coverage](15-validation-coverage.md#final-current-source-validation-2026-10-01), [progress](progress.md) and [execution evidence](14-execution-evidence.md#task-7-final-source-linux-smoke-and-capture).
