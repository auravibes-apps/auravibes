# Quickstart: Reusable Agents

## Preconditions

- Run commands from repo root unless noted.
- Use `fvm` for all Dart/Flutter commands.
- No new dependency should be added without `fvm flutter pub add` from the package directory.

## TDD Checklist

1. Add failing DAO/repository tests for workspace-scoped agents:
   - create stores name, slug, instructions, workspace id
   - duplicate slug in same workspace fails
   - same slug in different workspace succeeds
   - edit updates name, slug, instructions
   - delete removes agent from selectors and falls conversations back to "No Agent"

2. Add failing domain/use-case tests:
   - creating rejects empty name or instructions
   - selecting an agent rejects agents from another workspace
   - new conversation stores selected agent id
   - existing conversation agent change affects future responses only
   - deleted agent selection resolves to "No Agent"

3. Add failing prompt tests:
   - no agent keeps current prompt behavior unchanged
   - selected agent prepends latest saved instructions
   - edited instructions are used on next response
   - deleted agent does not inject stale instructions

4. Add failing widget/notifier tests:
   - Agents screen empty/list/error states
   - create/edit validation messages
   - duplicate slug error
   - new chat selector defaults to "No Agent"
   - conversation selector reflects and changes selected agent

5. Add failing integration journey tests:
   - create, edit, browse, and delete an agent in one workspace
   - start a new chat with an agent and verify selected-agent behavior
   - change an existing conversation agent and verify future-only behavior
   - delete a selected agent and verify fallback to "No Agent"

6. Record each focused failing test run before implementation for the related phase.

## Implementation Order

1. Add Drift table, DAO, schema version migration, and generated files.
2. Add domain entity and repository interface/implementation.
3. Add feature providers, use cases, and notifiers for agent CRUD and selection.
4. Update conversation entity/repository to support optional `agentId`.
5. Update new-chat flow to pass selected agent id.
6. Update conversation flow to change selected agent.
7. Update prompt composition to inject latest selected-agent instructions.
8. Replace Agents placeholder screen with management UI.
9. Add selector UI to new chat and conversation screens.

## Validation Commands

From repo root:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart run melos analyze
fvm dart run melos format
fvm dart run melos run validate:quick
```

From `apps/auravibes_app`:

```bash
fvm flutter test test/data/database/agents_dao_test.dart --no-pub
fvm flutter test test/data/repositories/agent_repository_impl_test.dart --no-pub
fvm flutter test test/services/chatbot_service/build_prompt_chat_messages_test.dart --no-pub
fvm flutter test integration_test/reusable_agents_management_flow_test.dart integration_test/reusable_agents_new_chat_flow_test.dart integration_test/reusable_agents_conversation_flow_test.dart --no-pub
fvm flutter test --coverage --no-pub
```

## Manual Verification

1. Open a workspace.
2. Open Agents.
3. Create agent named `Reviewer` with instructions.
4. Confirm slug is shown and duplicate `Reviewer` in same workspace is rejected.
5. Start new chat with `Reviewer`; verify future response follows instructions.
6. Edit `Reviewer` instructions; verify next response uses latest instructions.
7. Switch existing conversation to "No Agent"; verify instructions stop applying.
8. Delete `Reviewer`; verify selector no longer shows it and affected conversations fall back to "No Agent".
9. Verify create completes in under 60 seconds.
10. Verify new-chat agent selection and existing-conversation agent changes each take 2 actions or fewer.
11. Verify current conversation agent is identifiable within 3 seconds.
12. Verify an existing agent can be found and edited within 30 seconds when the workspace has at least 10 agents.
