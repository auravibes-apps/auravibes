# Screen inventory and coverage

[Audit index](README.md) · [Evidence register](12-evidence-register.md)

## Counting rules

The app has 27 files named `*_screen.dart`, one additional shared `create_workspace_form.dart`, and 34 route data classes. Of the route classes, WorkspaceRoute redirects to New Chat and ModelsRoute redirects to Connections. The other 32 route variants reuse 26 screen implementations; MarkdownEditorScreen opens through an imperative editor path rather than the typed router. MyShellRouteData supplies the shell and is not counted as a destination.

The route table in [workspace_route.dart](../../../apps/auravibes_app/lib/router/workspace_route.dart#L56) and [intro_route.dart](../../../apps/auravibes_app/lib/router/intro_route.dart#L3) is the authority for this inventory. Counts describe the inspected revision, not telemetry or the number of steps a person must complete.

## Every screen

“Keep” can include moving the entry point, clarifying copy, or adding recovery. “Group” means a shared destination with local views, not concatenating all forms.

| ID | Screen implementation | Current purpose and scope | Main next action | Health | Proposed disposition | Assessment |
| --- | --- | --- | --- | --- | --- | --- |
| S01 | `IntroScreen` / `intro_screen.dart` | Explain workspaces, create first workspace, enter AI setup | Create workspace / Connect AI | At risk | Compress explanatory slides; make local/cloud choice actionable | [03](03-onboarding-chat.md#s01--intro) |
| S02 | `NewChatScreen` / `new_chat_screen.dart` | Compose in the active workspace; choose model/agent | Send message | Needs clarification | Keep as the empty state of Chats; add setup readiness | [03](03-onboarding-chat.md#s02--new-chat) |
| S03 | `ChatsListScreen` / `chats_list_screen.dart` | Browse workspace history; import local archives | Open a chat / New chat | Needs clarification | Keep a full history view under Chats; reuse sidebar list patterns | [03](03-onboarding-chat.md#s03--chat-history) |
| S04 | `ChatConversationScreen` / `chat_conversation_screen.dart` | Read, send, approve, and inspect conversation activity | Send / resolve pending action | Needs clarification | Keep; add readable effective setup and child-run orientation | [03](03-onboarding-chat.md#s04--conversation-and-sub-agent-variant) |
| S05 | `MoreScreen` / `more_screen.dart` | Dispatch to seven management areas | Choose a tile | At risk | Replace with explicit navigation; retain old route as compatibility entry | [02](02-navigation-audit.md#s05--more) |
| S06 | `SettingsScreen` / `settings_screen.dart` | App appearance plus workspace compaction | Change theme / save compaction | At risk for scope clarity | Split app preferences from workspace conversation settings | [02](02-navigation-audit.md#s06--settings) |
| S07 | `WorkspaceManagementScreen` / `workspace_management_screen.dart` | Local, connected, and available cloud workspace lifecycle | Open / create / connect | Needs clarification | Keep one manager, opened from workspace header; separate available cloud discovery | [04](04-workspaces-cloud.md#s07--workspace-management) |
| S08 | `CreateWorkspaceScreen` / `create_workspace_screen.dart` | Name and create local/cloud workspace | Create workspace | Needs clarification | Reuse the shared form and preserve its draft across cloud authentication | [04](04-workspaces-cloud.md#s08--workspace-creation) |
| S09 | `CloudWorkspaceDetailScreen` / `cloud_workspace_detail_screen.dart` | Cloud connection, members, invitations, ownership, deletion | Connect / manage members | Needs clarification | Keep workspace detail; expose role and consequence groups | [04](04-workspaces-cloud.md#s09--cloud-workspace-detail) |
| S10 | `CloudAccountsScreen` / `cloud_accounts_screen.dart` | App-wide cloud identities, removal, deletion | Add / reconnect / account action | Needs clarification | Move entry to account/workspace context; show verified health | [04](04-workspaces-cloud.md#s10--cloud-accounts) |
| S11 | `CloudAccountAddScreen` / `cloud_account_add_screen.dart` | Choose login versus registration | Log in / Create account | Minor friction | Absorb into the authentication entry; preserve explanation and return path | [04](04-workspaces-cloud.md#s11--add-cloud-account) |
| S12 | `CloudAccountLoginScreen` / `cloud_account_login_screen.dart` | Authenticate a cloud identity | Log in | Needs clarification | Keep default auth view; retain contextual return | [04](04-workspaces-cloud.md#s12--cloud-login) |
| S13 | `CloudAccountRegisterScreen` / `cloud_account_register_screen.dart` | Email/password then verification code | Send code / finish registration | Needs clarification | Share auth shell; keep verification as a distinct state | [04](04-workspaces-cloud.md#s13--cloud-registration) |
| S14 | `CloudAccountForgotPasswordScreen` / `cloud_account_forgot_password_screen.dart` | Email reset request then code/new password | Send reset code / Reset password | Needs clarification | Keep dedicated recovery state within auth shell | [04](04-workspaces-cloud.md#s14--password-recovery) |
| S15 | `ServiceConnectionsScreen` / `service_connections_screen.dart` | Models, saved credentials, MCP health, catalog entry | Add / reconnect / inspect | Needs clarification | Make Connections a primary management destination; separate type and health filters | [05](05-connections-tools.md#s15--connections) |
| S16 | `ServiceConnectionCreateScreen` / `service_connection_create_screen.dart` | Model provider, user-skill credential, or app-skill credential setup | Test/connect / Save | At risk | One contextual setup shell; preserve specialized forms and guard drafts | [05](05-connections-tools.md#s16--new-connection) |
| S17 | `ServiceConnectionEditScreen` / `service_connection_edit_screen.dart` | Type-specific editing with stored-secret and verification handling | Save changes | Minor clarity gaps | Keep detail/editor; name the service and type | [05](05-connections-tools.md#s17--edit-connection) |
| S18 | `ToolsScreen` / `tools_screen.dart` | Workspace tools, defaults, integration reconnect | Add / enable / configure | Needs clarification | Move into Connections → Tools; retain source links and workspace permission scope | [05](05-connections-tools.md#s18--workspace-tools) |
| S19 | `AgentsScreen` / `agents_screen.dart` | Find, create, enable, and expose reusable agents | Choose / create agent | Needs clarification | Agents view within Agents & skills; retain independent list filters | [06](06-agents-skills.md#s19--agents-list) |
| S20 | `AgentDetailScreen` / `agent_detail_screen.dart` | Name, usage description, system prompt, skills, overrides | Create / Save agent | Needs clarification | Keep a focused editor with linked capability summaries | [06](06-agents-skills.md#s20--agent-detail-and-create) |
| S21 | `SkillsScreen` / `skills_screen.dart` | Built-in and custom skill discovery, status, bulk actions | Enable / open / create | Needs clarification | Skills view within Agents & skills; reveal readiness and ownership | [06](06-agents-skills.md#s21--skills-list) |
| S22 | `SkillDetailScreen` / `skill_detail_screen.dart` | Skill instructions, credentials, resources, template/native tools | Configure / Save / Enable | Needs clarification | Keep a detail workspace; group instructions, access, resources, tools | [06](06-agents-skills.md#s22--skill-detail-and-create) |
| S23 | `SkillResourceEditScreen` / `skill_resource_edit_screen.dart` | Create/edit custom resources or view built-in resources | Save resource | At risk | Keep child editor; add dirty guard and correct action noun | [07](07-editors-credential-authoring.md#s23--skill-resource) |
| S24 | `SkillToolEditScreen` / `skill_tool_edit_screen.dart` | Define request templates, inputs, credentials, preview | Preview / Save tool | Needs clarification | Keep advanced focused authoring; preserve route-exit guard | [07](07-editors-credential-authoring.md#s24--template-tool) |
| S25 | `SkillCredentialDefinitionsScreen` / `skill_credential_definitions_screen.dart` | List credential schemas, not saved values | Create / inspect type | At risk for naming | Nest under Connections → Credentials → Credential types | [07](07-editors-credential-authoring.md#s25--credential-types-list) |
| S26 | `SkillCredentialDefinitionEditScreen` / `skill_credential_definition_edit_screen.dart` | Define secret/metadata fields and constraints | Save type | Needs clarification | Keep advanced editor; show affected credentials, skills, and tools | [07](07-editors-credential-authoring.md#s26--credential-type-editor) |
| S27 | `MarkdownEditorScreen` / `markdown_editor_screen.dart` | Edit and preview a parent form's Markdown draft | Apply changes to parent | Needs clarification | Keep reusable editor; distinguish draft application from persistence | [07](07-editors-credential-authoring.md#s27--markdown-editor) |

The complete source paths and evidence anchors are in [12](12-evidence-register.md). Each filename above is under `apps/auravibes_app/lib/features/<feature>/screens/` with the feature matching its row.

## All route variants

Paths below use `W = /workspaces/:workspaceId`. Query parameters provide initial connection type, credential definition/app skill, or cloud return destination; they are not extra independent screens.

| Route data class | Current path | Screen/mode | Recommendation |
| --- | --- | --- | --- |
| `IntroRoute` | `/intro` | S01, four internal slides | Keep first-run entry, shorten explanations |
| `WorkspaceRoute` | `W` | Redirect to `W/chat/new` | Preserve workspace resolution |
| `NewChatRoute` | `W/chat/new` | S02 | Chats empty/new state |
| `ChatsRoute` | `W/chats` | S03 | Chats history |
| `ConversationRoute` | `W/chats/:chatId` | S04, interactive | Keep deep links |
| `SubAgentConversationRoute` | `W/chats/:chatId/sub-agents/:subAgentConversationId` | S04, composer hidden, parent relationship checked | Keep child identity and parent return |
| `MoreRoute` | `W/more` | S05 | Compatibility navigation entry after migration |
| `SettingsRoute` | `W/settings` | S06 | Preserve links while separating scopes |
| `WorkspaceManagementRoute` | `W/more/manage-workspaces` | S07, list and inline name editing | Workspace header management entry |
| `WorkspaceCreateRoute` | `W/more/manage-workspaces/create` | S08 | Shared creation flow |
| `CloudWorkspaceDetailRoute` | `W/more/manage-workspaces/cloud/:cloudAccountId/:cloudWorkspaceId` | S09 | Workspace detail |
| `CloudAccountsRoute` | `W/more/cloud-accounts` | S10 | App account management |
| `CloudAccountAddRoute` | `W/more/cloud-accounts/add` | S11 | Absorb into auth entry |
| `CloudAccountLoginRoute` | `W/more/cloud-accounts/login` | S12 | Default auth view |
| `CloudAccountRegisterRoute` | `W/more/cloud-accounts/register` | S13, registration/code states | Keep distinct state |
| `CloudAccountForgotPasswordRoute` | `W/more/cloud-accounts/forgot-password` | S14, request/code states | Keep recovery |
| `ModelsRoute` | `W/more/models` | Redirect to ServiceConnectionsRoute | Preserve alias; already consolidated |
| `ServiceConnectionsRoute` | `W/more/service-connections` | S15 | Primary Connections destination |
| `ServiceConnectionCreateRoute` | `W/more/service-connections/new` | S16, three type-specific forms | Contextual setup |
| `ServiceConnectionEditRoute` | `W/more/service-connections/:connectionId` | S17, provider/credential/generic/MCP forms | Type-aware detail/editor |
| `ToolsRoute` | `W/more/tools` | S18 | Connections → Tools |
| `AgentsRoute` | `W/more/agents` | S19 | Agents & skills → Agents |
| `AgentCreateRoute` | `W/more/agents/new` | S20, create | Same focused object editor |
| `AgentDetailRoute` | `W/more/agents/:agentId` | S20, edit | Same focused object editor |
| `SkillsRoute` | `W/more/skills` | S21 | Agents & skills → Skills |
| `SkillCreateRoute` | `W/more/skills/new` | S22, create | Stage related authoring after saving identity |
| `SkillDetailRoute` | `W/more/skills/:skillId` | S22, user-editable or built-in/read-only | Keep mode distinctions |
| `SkillResourceCreateRoute` | `W/more/skills/:skillId/resources/new` | S23, create | Child resource editor |
| `SkillResourceEditRoute` | `W/more/skills/:skillId/resources/:resourceId` | S23, edit/view | Child resource editor |
| `SkillToolCreateRoute` | `W/more/skills/:skillId/tools/new` | S24, create, onExit guard | Child advanced editor |
| `SkillToolEditRoute` | `W/more/skills/:skillId/tools/:toolId` | S24, edit, onExit guard | Child advanced editor |
| `SkillCredentialDefinitionsRoute` | `W/more/skill-credential-definitions` | S25 | Nested advanced type list |
| `SkillCredentialDefinitionCreateRoute` | `W/more/skill-credential-definitions/new` | S26, create | Advanced type editor |
| `SkillCredentialDefinitionEditRoute` | `W/more/skill-credential-definitions/:definitionId` | S26, edit | Advanced type editor |

## Supporting views included

These are task states or overlays, not 27 additional screens. They are included because merging route destinations without reviewing them could remove important control or context.

| View | Source | Why it matters | Report |
| --- | --- | --- | --- |
| Shared workspace form | `workspaces/screens/create_workspace_form.dart` | Intro and later creation use different callbacks | 03, 04 |
| Responsive drawer and workspace header | `widgets/app_with_responsive_drawer.dart`, `aura_sidebar_wrapper.dart` | Entry points, scope, and selected destination | 02 |
| Recent chats and View all | `chats/widgets/sidebar_conversations_widget.dart` | History entry already exists | 03 |
| Model selector | `models/widgets/compact_workspace_model_selector.dart` | Select model, search, recent models, loading/error | 03, 05 |
| Agent selector | `agents/widgets/compact_agent_selector.dart` | Optional reusable behavior selection | 06 |
| Add AI provider form | `models/widgets/add_model_provider_widget.dart` | Specialized verification and OAuth must survive grouping | 05 |
| MCP catalog browser | `service_connections/widgets/mcp_catalog_browser.dart` | Discover → configure → verify → install | 05 |
| Manual MCP setup | `tools/widgets/add_mcp_modal.dart` | Separate setup entry currently under Tools | 05 |
| Native-tool picker | `tools/widgets/add_tool_modal.dart` | Add existing native tools, rather than create a service | 05 |
| Tool manager in chat | `tools/widgets/tools_management_modal.dart` | Same heading with workspace/conversation parameters | 03, 05, 09 |
| Conversation skill picker | `skills/widgets/conversation_skill_selector_modal.dart` | Add versus Use now, credentials, context readiness | 06 |
| Agent skill manager and permission manager | Private widgets in `agent_detail_screen.dart` | Assignment and scoped overrides | 06 |
| Tool approval card | `chats/widgets/chat_tool_approval_card.dart` | Once/conversation/skip/stop are distinct consequences | 03 |
| Active delegated-agent view | `chats/widgets/active_sub_agent_status_widget.dart` | Child activity and parent context | 03 |
| Tool response/details | `chats/widgets/tool_call_response_modal.dart` | Detailed inspection should remain secondary | 03 |
| Checkpoint history | `chats/widgets/compaction_checkpoint_history_dialog.dart` | Inspect and restore conversation context | 03, 09 |
| Rename/delete/import/export chat actions | Chat list/sidebar widgets and archive feedback | Lifecycle, identity, local/cloud availability | 03, 09 |
| Workspace inline rename and confirmations | Private widgets in `workspace_management_screen.dart` | Saving, leaving, bulk removal consequences | 04 |
| Cloud registration/reset forms | `cloud_accounts/widgets/` | Multi-step verification and error recovery | 04 |
| Cloud member/invite/ownership dialogs | Private widgets in `cloud_workspace_detail_screen.dart` | Consequential role and data actions | 04 |
| Markdown preview/link dialog | `markdown/widgets/` | Draft editing and accessible field context | 07 |
| Unsaved changes confirmation | `widgets/unsaved_changes_dialog.dart` and local dialogs | Consistent recovery across navigation exits | 07 |
| Theme/accent/version and compaction sections | `settings/widgets/` | App-wide versus workspace-scoped behavior | 02, 09 |

## Coverage boundary

The inventory covers app screen implementations and the important supporting controls traced in the named journeys. It does not claim every private Flutter widget or every backend response was exercised. Server/admin tooling and Widgetbook component catalog pages are outside this end-user app screen audit. A live review must add screenshots and actual interaction outcomes against this inventory.

## Implementation-added screen and route

The tables above preserve the original 27-screen and 34-route audit at `c0527f8c`. Task 2a adds one focused screen and route. Task 3b1 adds a shared authentication wrapper behind the four existing auth URLs. The working implementation inventory now has 29 screen files and 35 route data classes. The wrapper and zero-workspace first-use integration are verified; final captures and native/participant validation remain.

| ID / route | Purpose and scope | Disposition and evidence |
| --- | --- | --- |
| S28, [WorkspaceSettingsScreen](../../../apps/auravibes_app/lib/features/settings/screens/workspace_settings_screen.dart) | Edit the named workspace's conversation compaction policy and model budgets. App appearance stays in S06. | Keep a guarded editor. Controlled tests verify A-only persistence, dirty/invalid buffer retention, failed refresh with Retry and save/reset behavior. |
| S29, [CloudAccountAuthScreen](../../../apps/auravibes_app/lib/features/cloud_accounts/screens/cloud_account_auth_screen.dart) | Shared route wrapper for Login, Add account, registration and password recovery, with callback-owned reusable content. | Verified in Task 3b1. Exact identity, safe returns, failed-session routing and delayed active/hidden completion pass reviewed checks. Existing URLs and first-use integration pass reviewed checks; captures/native and actual email delivery remain. |
| `WorkspaceSettingsRoute`, `W/workspace-settings` | Stable direct entry with one route-owned guard and workspace identity | Sibling of App settings in router branch 2; it has no App settings sidebar selection. Native/history/capture checks remain. |

[Task 2a evidence](14-execution-evidence.md#task-2a-verified-handoff) and [Task 3b1 evidence](14-execution-evidence.md#task-3b1-verified-handoff) record passing checks and approved reviews. [Task 3b2 evidence](14-execution-evidence.md#task-3b2-verified-handoff) verifies the first-use integration. [Progress](progress.md) tracks both additions alongside every original entry. Future implementation additions must extend the inventory and capture coverage.

## Task 7 validation checkpoint

Current fixtures render all 29 implementations through all 35 typed endpoints, including actual full chat history, typed tool create/edit, the added workspace-policy editor and shared authentication wrapper. The original27-screen/34-route source inventory remains unchanged. Final image acceptance and native/browser results are tracked separately. See [current coverage](15-validation-coverage.md#current-implementation-evidence--task-7) and [execution evidence](14-execution-evidence.md#task-7-final-attempt-2-results-and-bounded-correction).
