# Cloud Skill Controls Design

## Goal

Give a fresh cloud conversation the same skill-discovery path as a local
conversation. The model can load or unload a skill, and the next provider
iteration receives the selected skill context and its cloud-executable tools.

## Scope

Expose only `load_skill` and `unload_skill` in the cloud runtime. Keep
`list_skill_credentials` and skill-manager CRUD unavailable: no audited server
executor exists for those operations.

## Design

1. `ServerToolRuntime` synthesizes qualified skill-control specs when there are
   loadable or selected cloud skills. Their schemas use skill slugs and do not
   expose credential secrets.
2. `ServerToolExecutorService` dispatches skill-control descriptors through
   its server-owned control path.
3. That path uses `turn.initiatorUserId`, validates the target skill is
   active/enabled in the workspace, and calls `WorkspaceStateUseCases.patch`
   with deterministic request IDs. It creates or deletes the matching
   `conversationSkillSelection` resource, preserving revision, audit, event,
   and idempotency semantics.
4. The existing continuation loop reloads context and tools after the tool
   result. `ServerConversationEngineHost` then sees the newly selected resource
   through its existing context and materialization paths.

## Safety and verification

- Do not write `WorkspaceResource` rows directly.
- Refuse invalid, disabled, or unavailable skills.
- Keep the tool unavailable in child conversations if the local policy does.
- Add focused server tests for control exposure, audited selection mutation, and
  context/tool visibility on the resumed iteration.
