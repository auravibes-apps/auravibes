# Skills Feature Implementation Plan

**Date:** 2026-05-31
**Status:** Draft

## Summary

Add first-class Skills to AuraVibes. A skill is loadable conversation context plus zero or more dynamically exposed tools. Skills can be app-defined or user-defined, native or templated. User templated skills can call URL APIs through stored templates, runtime inputs, and encrypted credentials without exposing secrets in skill content.

## Success Criteria

- Users can manage skills from the More section.
- Users can create, edit, disable, duplicate, and delete user skills and their templated URL tools.
- App skills are registered in code, view-only in UI, and can expose native or templated tools.
- Conversations can load and unload eligible skills from UI and from two always-available agent tools.
- Agent context assembly includes skill content as result fragments for loaded, enabled, credential-ready skills.
- Agent tool specs include skill tools only when the skill is loaded, enabled, and credential-ready.
- Templated URL tools resolve inputs and credentials at execution time without storing credentials in template content.
- Missing required credentials block loading and tool execution.
- All user-facing text uses easy_localization.

## Non-Goals

- No plugin marketplace.
- No user-authored native Dart tools.
- No app skill storage in the database.
- No cross-workspace sharing for user skills in the first version.
- No non-URL template type in the first version, but schema must allow future template types.

## Existing Architecture Fit

- Use feature-first structure under `apps/auravibes_app/lib/features/skills/`.
- Keep persistence in Drift tables and repositories under `data/` and `domain/repositories/`.
- Keep business rules in use cases, not widgets or providers.
- Keep notifier state thin and UI-oriented.
- Extend existing tool loading flow from `LoadConversationToolSpecsUsecase`.
- Reuse `ToolSpec` for model-facing tool definitions.
- Reuse existing encrypted credential storage model in `ServiceConnections` where possible.
- Add routes through `workspace_route.dart` and entry tile in `MoreScreen`.

## Domain Model

### Skill

Represents one app or user skill.

Fields:

- `id`: database id for user skills; app identifier for app skills.
- `workspaceId`: user skills only.
- `source`: `user` or `app`.
- `kind`: `template` or `native`.
- `title`.
- `slug`: generated from title; unique per workspace for user skills.
- `description`.
- `content`: content sent to agent when loaded.
- `isEnabled`: workspace-level enablement.
- `createdAt`, `updatedAt`.

Rules:

- User skill title accepts alphanumeric characters and spaces.
- User skill slug is generated and unique per workspace.
- User skill slug is immutable after creation.
- Duplicate title blocks create/update with validation error.
- App skill definitions live in Dart files and cannot be edited or deleted.

### Skill Credential Definition

Defines credential shape for skills.

Fields:

- `id`.
- `workspaceId`: user definitions only.
- `source`: `user` or `app`.
- `slug`.
- `title`.
- `attributesJson`: map of attribute key to description and optional flag.

Rules:

- User skills can reference only user credential definitions.
- App skills can reference only app credential definitions.
- User-created skills cannot reference app credential definitions.
- Optional attributes may be absent during template resolution.
- Credentials are shared by skills that reference the same credential definition id.

### Skill Credential

Concrete encrypted credential values attached to a credential definition.

Preferred storage:

- Reuse `ServiceConnections` with new `kind` values:
  - `skillCredential`.
  - `appSkillCredential`.
- Store non-secret metadata in `metadataJson`.
- Store encrypted attribute map in `encryptedAuthValue`.
- Continue using `workspaceId`, `name`, `keySuffix`, and `isEnabled`.

Alternative:

- Add dedicated `skill_credentials` table if `ServiceConnections` becomes too generic or migration risk is high.

Tradeoff:

- Reusing `ServiceConnections` avoids duplicate encryption and credential UI plumbing.
- Dedicated table gives stronger type safety and simpler queries for skills.

### Skill Template Tool

Represents one user or app templated tool.

Fields:

- `id`.
- `skillId` or app skill identifier plus tool slug.
- `title`.
- `slug`.
- `templateType`: first value is `url`.
- `templateJson`: URL, method, headers, query, body, timeout, response mapping.
- `inputsJson`: map of input key to description, type, optional flag.
- `credentialDefinitionRef`: optional.
- `isEnabled`.

Rules:

- Template text can include `{input:key}` and `{credential:key}`.
- Required input placeholders must exist in generated JSON schema.
- Required credential placeholders must resolve from selected credential.
- Optional credential placeholders remove containing header/query/body field when absent.
- Credentials never appear in prompt content or persisted tool definitions.
- Non-JSON bodies do not support optional placeholder field removal.

### Conversation Skill

Tracks skill load state per conversation.

Fields:

- `id`.
- `conversationId`.
- `workspaceSkillId`: nullable, user skill.
- `appSkillIdentifier`: nullable, app skill.
- `isLoaded`.
- `createdAt`, `updatedAt`.

Rules:

- Exactly one of `workspaceSkillId` or `appSkillIdentifier` is set.
- Cascade delete when conversation or user skill is deleted.
- Disabled skills are treated as unloaded.

## Drift Tables

Add tables:

- `skills`.
- `skill_credential_definitions`.
- `skill_template_tools`.
- `conversation_skills`.

Potentially extend:

- `ServiceConnectionKindTable` with skill credential kinds.

Migration:

- Increment `schemaVersion` from 4 to 5.
- Create new tables in `onUpgrade` when `from < 5`.
- Add enum migration handling for `ServiceConnections.kind` only if reused.
- Add DAO classes for each aggregate.

Cascade rules:

- `skills.workspaceId -> workspaces.id ON DELETE CASCADE`.
- `skill_credential_definitions.workspaceId -> workspaces.id ON DELETE CASCADE`.
- `skill_template_tools.skillId -> skills.id ON DELETE CASCADE`.
- `conversation_skills.conversationId -> conversations.id ON DELETE CASCADE`.
- `conversation_skills.workspaceSkillId -> skills.id ON DELETE CASCADE`.

## Repositories

Add domain interfaces:

- `SkillsRepository`.
- `SkillTemplateToolsRepository`.
- `SkillCredentialDefinitionsRepository`.
- `ConversationSkillsRepository`.

Add data implementations:

- `SkillsRepositoryImpl`.
- `SkillTemplateToolsRepositoryImpl`.
- `SkillCredentialDefinitionsRepositoryImpl`.
- `ConversationSkillsRepositoryImpl`.

Repository responsibilities:

- Query workspace skills merged with app skill registry.
- Persist user skill CRUD.
- Persist user credential definition CRUD.
- Persist user template tool CRUD.
- Persist conversation load state.
- Return credential readiness for a skill without exposing secret values.

## App Skill Registry

Add:

- `services/skills/app_skill_registry.dart`.
- `services/skills/models/app_skill_definition.dart`.
- `services/skills/models/app_skill_tool_definition.dart`.
- `services/skills/native_skill_service.dart`.

First app native skill:

- `skills_manager`.

Tools:

- `create_user_skill`.
- `update_user_skill`.
- `create_skill_template_tool`.
- `update_skill_template_tool`.
- `create_skill_credential_definition`.

Rules:

- Registry is code-only.
- App skills can be disabled by user workspace preference.
- App skill disablement is scoped to one workspace.
- Native tools are built through Riverpod providers so repositories are injected at execution time.

## Use Cases

### Skill Management

- `CreateSkillUsecase`.
- `UpdateSkillUsecase`.
- `DeleteSkillUsecase`.
- `DuplicateSkillUsecase`.
- `DisableSkillUsecase`.
- `ListWorkspaceSkillsUsecase`.
- `ValidateSkillTitleUsecase`.
- `CreateSkillTemplateToolUsecase`.
- `UpdateSkillTemplateToolUsecase`.
- `DeleteSkillTemplateToolUsecase`.
- `CreateSkillCredentialDefinitionUsecase`.
- `UpdateSkillCredentialDefinitionUsecase`.
- `DeleteSkillCredentialDefinitionUsecase`.

### Conversation Enablement

- `LoadConversationSkillUsecase`.
- `UnloadConversationSkillUsecase`.
- `ListLoadableConversationSkillsUsecase`.
- `ListLoadedConversationSkillsUsecase`.
- `BuildSkillPromptMessagesUsecase`.
- `BuildSkillToolSpecsUsecase`.

Rules:

- Load use case rejects disabled skill.
- Load use case rejects missing required credentials.
- Unload use case is idempotent.
- Prompt builder skips disabled or credential-blocked skills.

### Template Execution

- `BuildTemplateToolSpecUsecase`.
- `ResolveSkillTemplateToolUsecase`.
- `RunSkillTemplateToolUsecase`.
- `ResolveTemplatePlaceholdersUsecase`.

Rules:

- Tool spec adds runtime input fields from `inputsJson`.
- Tool spec adds `credentialId` enum only when the skill has more than one eligible credential.
- Execution loads credential by id and validates it matches skill definition.
- URL request uses existing `dio` dependency; no new HTTP package needed.
- Resolver removes optional header/query/body fields when optional credential or input is absent.
- Resolver throws typed domain exceptions for missing required values and invalid template shape.

## Agent Integration

Modify `LoadConversationToolSpecsUsecase` to merge:

1. Existing workspace/conversation tool specs.
2. Always-available `load_skill` tool.
3. Always-available `unload_skill` tool.
4. Tool specs from loaded eligible skills.

Add native always-available specs:

- `load_skill`
  - Description lists loadable skill title, slug, source, and description.
  - Input schema has enum of loadable skill slugs.
- `unload_skill`
  - Description lists loaded skill title, slug, source, and description.
  - Input schema has enum of loaded skill slugs.

Modify agent iteration context assembly:

- Add loaded skill content as result fragments before recent conversation messages.
- Render each skill fragment with XML tags containing the skill name and content.
- Do not include credentials or template internals in prompt context.

Modify tool execution:

- Route skill management native tools through `NativeToolService` or a new skill-aware resolver.
- Route templated skill tools through `RunSkillTemplateToolUsecase`.
- Resolve `load_skill` and `unload_skill` by updating `ConversationSkills`.

## UI Plan

### Routing

Add routes:

- `/workspaces/:workspaceId/more/skills`.
- `/workspaces/:workspaceId/more/skills/new`.
- `/workspaces/:workspaceId/more/skills/:skillId`.
- `/workspaces/:workspaceId/more/skills/:skillId/tools/new`.
- `/workspaces/:workspaceId/more/skills/:skillId/tools/:toolId`.
- `/workspaces/:workspaceId/more/skill-credential-definitions/new`.
- `/workspaces/:workspaceId/more/skill-credential-definitions/:definitionId`.
- `/workspaces/:workspaceId/more/credentials/new`.

Add More tile:

- Title key: `more_screen_skills_title`.
- Subtitle key: `more_screen_skills_subtitle`.
- Icon: `Icons.psychology_alt_outlined` or closest existing Material icon.

### Screens

Add under `features/skills/screens/`:

- `skills_screen.dart`: list skills with source, kind, enabled state, credential readiness.
- `skill_detail_screen.dart`: edit user skill; view app skill.
- `skill_tool_edit_screen.dart`: edit URL template tool.
- `skill_credential_definition_screen.dart`: edit credential definitions.
- `add_skill_credential_screen.dart`: select credential type, definition, name, and attributes.

Modify:

- Provider/model screen naming later if current model provider UI becomes generic Credentials screen.

### Widgets

Add under `features/skills/widgets/`:

- `skill_list_tile.dart`.
- `skill_source_badge.dart`.
- `skill_kind_badge.dart`.
- `skill_enabled_switch.dart`.
- `skill_credential_readiness_hint.dart`.
- `skill_tool_list.dart`.
- `skill_tool_editor.dart`.
- `skill_template_input_list.dart`.
- `skill_credential_attribute_list.dart`.
- `conversation_skill_selector_modal.dart`.

Conversation UI:

- Add skill selector button near tool controls in chat input or chat header.
- Modal shows loaded and available skills.
- Toggle updates same `ConversationSkills` table used by agent tools.

### UI Rules

- Use `auravibes_ui` components where available.
- If modifying `packages/auravibes_ui`, read `packages/auravibes_ui/STYLE_GUIDE.md` first.
- Do not put business logic in widgets.
- Use `TextLocale` for text widgets.
- Use `.tr()` only for non-widget string contexts.
- Use `AsyncValue` switch expressions, not `.when()`.

## Localization

Add keys in:

- `apps/auravibes_app/assets/i18n/en.json`.
- `apps/auravibes_app/assets/i18n/es.json`.

Generate:

- `fvm dart run melos run generate`

If generator prompts in non-TTY shell, fallback:

- `cd apps/auravibes_app`
- `fvm dart pub run easy_localization:generate -S assets/i18n -f keys -O lib/i18n -o locale_keys.dart --skip-unnecessary-keys`
- `fvm dart format lib/i18n/locale_keys.dart`

## New Packages

No new runtime package required for first version.

Already available:

- `dio` for URL execution.
- `drift` for persistence.
- `easy_localization` for UI text.
- `hooks_riverpod` and `riverpod_annotation` for state wiring.
- `freezed_annotation` for entities/state.
- `go_router` and `go_router_builder` for routes.

Consider later:

- JSON path package only if response extraction needs structured selectors.
- Template parser package only if placeholder syntax grows beyond simple token replacement.

## Phased Implementation

### Phase 1: Data Model and Readiness

Goal:

- Store user skills, credential definitions, template tools, and conversation load state.

Tasks:

1. Add Drift tables and DAOs.
2. Add entities and repositories.
3. Add migration to schema version 5.
4. Add validation use cases for title, slug, source rules, and credential readiness.
5. Add focused repository and use case tests.

Verification:

- `fvm dart run build_runner build --delete-conflicting-outputs` in `apps/auravibes_app`.
- `fvm flutter test test/data test/domain --no-pub` in `apps/auravibes_app`.
- `fvm dart run melos analyze`.

### Phase 2: App Skill Registry and Agent Load/Unload

Goal:

- Agent can see load/unload skill tools and loaded skill content.

Tasks:

1. Add app skill registry.
2. Add `ConversationSkillsRepository`.
3. Add load/unload use cases.
4. Add dynamic `load_skill` and `unload_skill` tool spec builders.
5. Add prompt context builder for loaded skills.
6. Wire builders into agent iteration context and tool specs.

Verification:

- Unit tests for loadable/loaded enum generation.
- Unit tests for disabled and missing-credential filters.
- Focused chat use case tests for prompt message inclusion.

### Phase 3: Templated URL Tool Execution

Goal:

- Loaded skill template tools execute URL requests with resolved inputs and credentials.

Tasks:

1. Define URL template JSON model.
2. Add placeholder resolver.
3. Add input JSON schema builder.
4. Add credential selection logic.
5. Add `RunSkillTemplateToolUsecase` using `dio`.
6. Wire skill template execution into tool resolver.

Verification:

- Unit tests for URL, header, query, and body placeholder resolution.
- Unit tests for optional placeholder field removal.
- Unit tests for missing required credential/input typed exceptions.
- Mocked `dio` execution tests.

### Phase 4: Skills Management UI

Goal:

- User can manage skills, definitions, credentials, and template tools.

Tasks:

1. Add routes and More tile.
2. Add skills list screen.
3. Add user skill create/edit screen.
4. Add app skill view screen.
5. Add skill tool editor screen.
6. Add credential definition screen.
7. Add add credential screen.
8. Add localization keys and regenerate `LocaleKeys`.

Verification:

- Widget tests for list, edit, missing credential hint, and app read-only mode.
- `fvm dart run melos run generate`.
- `fvm dart run melos analyze`.

### Phase 5: Conversation Skill Selector

Goal:

- User can load and unload conversation skills manually.

Tasks:

1. Add conversation skill selector button.
2. Add selector modal with loaded and available sections.
3. Wire toggles to same load/unload use cases used by agent tools.
4. Add empty and missing-credential states.

Verification:

- Widget tests for modal sections and toggle actions.
- Use case tests confirming UI and agent paths share `ConversationSkills`.

### Phase 6: Native Skills Manager App Skill

Goal:

- App-provided native skill can create/edit user skills and tools via agent tools.

Tasks:

1. Add `skills_manager` app skill definition.
2. Add native tools for skill CRUD and template tool CRUD.
3. Inject repositories through Riverpod providers.
4. Add permission and validation checks.

Verification:

- Unit tests for native tool request validation.
- Tool resolver tests for injected native skill tools.

## Risks and Decisions

### Credential Storage

Decision needed:

- Reuse `ServiceConnections` or add dedicated `skill_credentials`.

Recommendation:

- Reuse `ServiceConnections` for first pass if existing encryption service supports encrypted JSON maps.

Risk:

- Existing model-provider UI names may leak into skill credentials. UI should become generic Credentials screen before exposing skill credentials broadly.

### Template Body Field Removal

- For JSON bodies, parse body as JSON, resolve values, and remove object fields with absent optional placeholders.
- For non-JSON text bodies, do not support optional placeholder removal. Reject optional placeholders in raw text bodies.

Risk:

- Removing fields from raw XML or arbitrary text is ambiguous.

### Dynamic Tool Naming

- Use composite ids:
  - `skill__user__<skillSlug>__<toolSlug>`.
  - `skill__app__<appSkillSlug>__<toolSlug>`.
- User skill slugs are immutable after creation.

Risk:

- Slug immutability means title changes do not change model-facing tool ids.

## Open Questions

1. Should skill result fragments use a new message fragment type or reuse existing tool-result fragment plumbing?
2. Should app skill workspace disablement live in a new table or reuse a generic workspace app settings table?
3. Should raw non-JSON bodies be blocked only when optional placeholders exist, or blocked from all placeholders in v1?
