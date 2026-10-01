# AuraVibes screen and navigation audit

Date: 2026-09-30. Source revision: `c0527f8cca74871826b46478007a2c607b5fd4fc`.

**Recommendation: organize the app around Chats, Agents & skills, and Connections; move workspace management into the workspace selector; distinguish App settings from Workspace settings.** Consolidate related management destinations while retaining focused editors, authentication recovery, and separate permission scopes.

The strongest consolidation opportunity is the setup and management journey. A person currently needs to understand how Connections, Tools, Skills, Agents, Credential Definitions, Cloud accounts, Workspaces, More, and Settings relate. Several of those concepts are useful, but their navigation and labels do little to explain the relationships.

## Scope and evidence limits

This is a **source-based heuristic UX audit**, supplemented by current-source visual captures and a Linux journey, not a participant usability study. It covers all **27 original screen implementations**, the shared workspace creation form, **34 original route data classes**, and the supporting overlays listed in the inventory. The route count includes a workspace redirect, the Models compatibility redirect, and create/edit variants that reuse a screen; it is not a count of 34 independent screens.

Task 2a adds a named Workspace settings screen and route. Task 3b1 adds a shared authentication wrapper used by existing auth routes. The current implementation has 29 screen files and 35 route data classes; the inventory tracks both additions separately from the original audit.

The original source audit inspected route definitions, screen composition, English/Spanish localization files, capabilities and selected test specifications at the revision above. That assessment read tests without executing them. The implementation phase added focused regressions and a final current-source visual matrix, aggregate validation, Linux journey and independent whole-change review. Results and limits are in [progress.md](progress.md), [14-execution-evidence.md](14-execution-evidence.md) and the [final review](evidence/final-whole-change-review.md). All feasible local work is complete; the overall goal remains blocked by production email, live provider/catalog access, native macOS/iOS keyboard and assistive technology, and participant comprehension checks. No user sessions, analytics or support cases were available.

Flutter, Dart and FVM were absent during the original source audit, so it captured no current screenshots. The implementation phase installed the unchanged pinned Flutter 3.47.5 / Dart 3.13.4, completed the baseline, ran focused widget and persistence tests, and captured the current source. Contrast and named widget-level accessibility checks have bounded results. Physical keyboard and native screen-reader behavior, production email delivery, live provider/catalog access and participant comprehension still require their recorded validation work.

The repository's [UX task audit skill](../../../.agents/skills/ux-task-audit/SKILL.md) permits routes, code, and tests to support an assessment when a running product is unavailable. The Product Design audit skill was also consulted; its screenshot-based audit requirements remain unmet. This deliverable completes the source and information architecture review; the [validation plan](11-validation-plan.md) specifies how to complete the visual and interaction review.

## Read the audit

| File | What it answers |
| --- | --- |
| [01 — Screen inventory](01-screen-inventory.md) | Which screens and route variants exist, and what should happen to each? |
| [02 — Navigation audit](02-navigation-audit.md) | Where do people enter tasks, lose context, or encounter unclear scope? |
| [03 — Onboarding and chat](03-onboarding-chat.md) | Can a person reach their first usable chat and understand AI activity? |
| [04 — Workspaces and cloud](04-workspaces-cloud.md) | Can people distinguish local/cloud work, account identity, and destructive actions? |
| [05 — Connections and tools](05-connections-tools.md) | Where should AI providers, service access, tools, and recovery live? |
| [06 — Agents and skills](06-agents-skills.md) | How should reusable behavior, skills, availability, and permissions be explained? |
| [07 — Editors and credential authoring](07-editors-credential-authoring.md) | Which editing screens should stay separate, and where are save/recovery gaps? |
| [08 — Consolidation proposal](08-screen-consolidation.md) | What should be merged, grouped, deferred, retained, or removed? |
| [09 — Content, states, and accessibility](09-content-states-accessibility.md) | How can every screen explain its purpose, scope, status, and next action? |
| [10 — Prioritized roadmap](10-prioritized-roadmap.md) | What should change first, with which dependencies and acceptance conditions? |
| [11 — Validation plan](11-validation-plan.md) | How can the recommendations be confirmed or rejected? |
| [12 — Evidence register](12-evidence-register.md) | Which current sources support the findings? |
| [13 — Implementation plan](13-implementation-plan.md) | Which ordered changes and shared contracts implement the recommendations? |
| [14 — Execution evidence](14-execution-evidence.md) | Which tests, review results and limitations support each implementation checkpoint? |
| [15 — Validation coverage](15-validation-coverage.md) | Which screens, routes and tasks have executed evidence, and which specific checks remain? |
| [Progress](progress.md) | What is the current status of every task, finding, screen, route and validation item? |

## Main findings

1. **Management tasks are hidden behind More.** Its seven tiles mix everyday setup with advanced authoring and app-wide account management. Replace the hub with explicit destinations and scoped workspace/account controls. See UX-01 and UX-02.
2. **Credential types and saved credentials have overlapping names.** The More tile says “Credential Definitions,” but the destination says “Credentials” and “New Credential.” Put types under an advanced entry inside Connections and keep saved values clearly separate. See UX-03 and UX-18.
3. **First-run cloud setup is promised without a matching action.** Intro embeds the workspace form without its add-account callback. With no accounts, it offers local creation and a cloud hint, but no first-run cloud authentication path. See UX-06.
4. **Setup completion does not consistently return to the user's original task.** Intro opens connection creation through route replacement, whereas New Chat pushes it. Intro completion can leave the person in Connections rather than ready to send a message. See UX-07.
5. **Connections and Tools share parts of the integration lifecycle.** Connection identity and authentication belong together; tools and permission policies should remain distinct views within that shared management area. See UX-04 and UX-17.
6. **Some editing and route states lack comparable recovery.** Resource editing and connection creation lack the explicit dirty-state protection used by other editors. Workspace session and sub-agent route gates can render blank or framework error states. See UX-25 and UX-31.

## What should merge, and what should stay focused

| Decision | Scope |
| --- | --- |
| Replace More | Direct access to Chats, Agents & skills, Connections; workspace controls in the header; App settings in the footer. |
| Group Agents and Skills | One management destination with separate lists and focused details. Preserve different objects and runtime behavior. |
| Group Connections and Tools | One setup destination with service identity, authentication, exposed tools, and workspace defaults linked together. |
| Nest Credential Definitions | Advanced “Credential types” within Connections, reachable contextually from skill/tool authoring. |
| Remove the account-choice interstitial | Default to Log in with a Create account alternative; retain verification and reset-password steps. |
| Keep rich editors | Agent instructions, skill content, resources, template tool definitions, and credential schemas still need focused editing space. |
| Keep conversation controls | Conversation skills, tool approvals, and conversation overrides retain their local task context. |
| Keep Models as a compatibility alias | It already redirects to Connections; do not recreate a separate Models management screen. |

This proposal simplifies where people look, not the number of capabilities they can use. It does not assume that a smaller route count alone improves UX.

## Journey health at a glance

These are source-based judgments. “At risk” means a specific high-priority recovery or clarity gap; “needs clarification” means the path exists but asks the person to infer relationships or consequences.

| Step | Task | General health | Detailed report |
| --- | --- | --- | --- |
| 1 | Create the first workspace | At risk for cloud entry; local path exists | [03](03-onboarding-chat.md) |
| 2 | Connect AI and choose a model | At risk for task return and prerequisite recovery | [03](03-onboarding-chat.md), [05](05-connections-tools.md) |
| 3 | Send the first message | Needs clarification of readiness and optional controls | [03](03-onboarding-chat.md) |
| 4 | Find and continue a chat | Needs clarification; recent chats and View all already exist | [03](03-onboarding-chat.md) |
| 5 | Understand approvals and delegated work | Needs clarification; important controls already exist | [03](03-onboarding-chat.md) |
| 6 | Switch or manage workspaces | Needs clarification of scope and lifecycle | [04](04-workspaces-cloud.md) |
| 7 | Connect cloud, register, or recover access | Needs clarification; return-path support already exists | [04](04-workspaces-cloud.md) |
| 8 | Connect a service and inspect its tools | Needs clarification of ownership and setup paths | [05](05-connections-tools.md) |
| 9 | Create or choose an agent | Needs clarification; required-field guidance is a strength | [06](06-agents-skills.md) |
| 10 | Enable, configure, or use a skill | Needs clarification of readiness and authoring prerequisites | [06](06-agents-skills.md) |
| 11 | Edit content, resources, tools, or credential types | At risk for inconsistent save and exit behavior | [07](07-editors-credential-authoring.md) |
| 12 | Change appearance or workspace conversation behavior | Needs clarification of setting scope | [02](02-navigation-audit.md), [09](09-content-states-accessibility.md) |

## How to use the priorities

There are 32 uniquely numbered findings. Severity is a heuristic assessment of likely task impact, not measured incidence. Confidence in task impact is medium unless a finding explicitly says low; source facts can be directly confirmed independently.

- **High:** a core task or safe recovery is at risk. Address before broad navigation migration.
- **Medium:** avoidable confusion, backtracking, or ambiguity with an existing workaround.
- **Low:** a bounded clarity or presentation issue.

No critical incident or proven conversion effect is claimed. The roadmap uses P1/P2/P3 to correspond to high/medium/low severity, with dependency order sometimes bringing a small change forward.

## Completion status

All original inventory entries have a screen-level assessment and a disposition. The reports include journeys, alternatives, merge boundaries, proposed copy, source citations and validation scenarios. The source audit is complete.

The source audit and implementation plan are complete. Tasks 1–6 and their repair rounds pass focused tests, strict scans, frozen-hash checks and scoped reviews. On the final `4aac0aa4` source, all 78 capture cases pass, all 76 screenshots are accepted, `validate:quick` passes, and an isolated Linux virtual-display run completes local workspace creation, setup return and primary navigation. The earlier real-browser route run is preserved with its pre-repair source identity. [Progress](progress.md), [execution evidence](14-execution-evidence.md) and [current coverage](15-validation-coverage.md) record the exact evidence and limits. The overall goal remains blocked by production email/catalog access, native device/assistive-technology checks and participant sessions.
