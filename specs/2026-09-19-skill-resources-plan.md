# Skill Resources

**Date:** 2026-09-19
**Status:** Revised after `origin/main` merge

## Decision

Add one-level child content to skills as **Skill Resources**.

- **Skill**: parent instructions and tools.
- **Skill Resource**: child text content such as policies, examples, or reference documents.
- **Skill Resource Summary**: resource `slug`, `title`, and short `description`.
- Parent runtime command: `activate_skill`.
- Child runtime command: `load_skill_resource`.

Avoid “sub-skill”, “skill file”, and generic “resource”; those names hide the parent relationship or conflict with other workspace resources.

## Runtime contract

The current parent-loading contract is `activate_skill`. Keep its existing XML result and add a resource catalog beside the existing tools and credentials sections:

```xml
<skill_content slug="skill-slug" title="Example" revision="...">
  <![CDATA[skill instructions]]>
  <skill_tools>...</skill_tools>
  <skill_credentials>options[...]{credentialId,displayName}: ...</skill_credentials>
  <skill_resources>resources[1]{slug,title,description}:
refund-policy,Refund policy,Rules for refunds and exceptions.
  </skill_resources>
</skill_content>
```

Encode resource summaries with TOON, matching the existing credential integration. Sort by slug and XML-escape the encoded text. Resource summaries do not appear in the initial `<skill_catalog>`, agent skill messages, `SkillManifest`, or `list_skills`. The agent learns them only after successful parent activation.

Add:

```text
load_skill_resource({ "skill": "skill-slug", "resource": "resource-slug" })
```

Return the full resource content as a bounded XML result in the thread:

```xml
<skill_resource skill="skill-slug" slug="refund-policy" title="Refund policy">
  <![CDATA[resource content]]>
</skill_resource>
```

Use a typed result alongside the existing `SkillActivationResult` so the server's existing bounded-content path handles both. Escape XML attributes and protect `]]>` inside content with the same CDATA helper. This command does not modify conversation skill state. There is no `unload_skill_resource`; the content is a normal tool result and remains part of the conversation transcript.

Keep the existing parent `activate_skill` revision check. Resource loading does not need a second revision argument in v1; the resource catalog is authoritative after activation and writes still use optimistic revisions.

## Persistence

### Local

Add a `SkillResources` Drift table referencing `Skills`:

- `id`
- `skillId`
- `title`
- `slug`
- `description`
- `content`
- `createdAt`
- `updatedAt`

Enforce unique `skillId + slug`, keep slugs immutable after creation, and cascade deletion from skill to resources. Add the schema migration, DAO, repository mapping, and generated Drift output. Reuse the existing skill slug and validation rules rather than adding a second slug system.

### Cloud

Add a dedicated Serverpod `SkillResource` table and CRUD endpoint. Store workspace scope, parent skill id, content fields, revision, timestamps, and deletion state. Use optimistic revisions for edits and publish workspace invalidation events.

Cloud skills currently live in `WorkspaceResource`, so the resource table references the existing skill with `(workspaceId, skillId)`. Validate that the parent is an active skill in the same workspace in the same transaction. Do not migrate parent skills to a new storage model.

Delete child resources when a cloud parent skill is deleted. Do not store resources inside the skill JSON or generic workspace-resource payload.

App/file-defined skills expose static `AppSkillResourceDefinition` entries on `AppSkillDefinition`. They are runtime-readable and UI-viewable, but read-only and do not create database rows. `clone_app_skill` must copy those definitions into the new user skill's resource rows.

## Agent management tools

Keep skill creation and resource creation separate:

```text
list_skill_resources(skillSlug)
get_skill_resource(skillSlug, resourceSlug)
create_skill_resource(skillSlug, title, description, content)
update_skill_resource(skillSlug, resourceSlug, title, description, content)
delete_skill_resource(skillSlug, resourceSlug)
```

Do not add a nested `resources` field to `create_user_skill`. The agent creates the parent first, then creates resources independently. Update the Skills Manager instructions and metadata to describe this sequence. Management tools operate on user-owned skills; app-defined resources reject mutations.

## UI

Add a **Resources** section to the skill detail screen:

- List title and description.
- View full content.
- Create and edit user resources.
- Show app/file-defined resources as read-only.
- Reuse the existing Markdown editor and preview.
- Generate the resource slug on create and keep it read-only afterward.
- Add resource list, create, and detail/edit routes.

Keep this product-specific UI in the app package. No new UI-package or A2UI work.

## Validation and defaults

- Description limit: 240 characters.
- Content limit: reuse the existing 50,000-character bounded tool-result ceiling; do not inherit the generic workspace JSON 16,000-character limit for the dedicated table.
- Maximum resources per skill: 100.
- Text/Markdown only.
- One resource level only; no nested resources.
- Catalogs sorted deterministically by slug.
- Runtime loading validates workspace, skill availability, enabled state, parent ownership, and resource ownership.
- Skill and resource slugs are stable after creation.
- Duplicating a skill copies its resources.
- Resource changes do not change the parent skill manifest/catalog revision in v1; activation returns the current catalog after the existing parent revision check.

Defer binary files, external URLs, resource search, pagination, and blob storage until the text-resource flow proves useful.

## Verification

- Engine tests cover the new command, XML/TOON serialization, CDATA escaping, and absence of resource metadata from initial context.
- App tests cover local CRUD, uniqueness, cascade deletion, duplication, manager tools, and load-result construction.
- Server tests cover table migration, authorization, revision conflicts, parent validation, deletion cleanup, and resource loading.
- UI tests cover create, edit, view, and app-resource read-only behavior.
- Run focused engine/app/server tests, generated-code review, analyzers, and migration checks.

## Post-merge recommendations

1. Use `activate_skill` consistently for the parent operation. Reserve `load_skill_resource` for one-shot content retrieval; do not rename the new current XML contract back to JSON.
2. Add `<skill_resources>` to `buildSkillActivationResult` rather than extending `SkillManifest` or `SkillCatalogEntry`. This preserves the new catalog-first prompt design and ensures resources remain undiscoverable until activation.
3. Reuse the current `SkillCredentialOption`/TOON pattern for a small `SkillResourceSummary` type. Keep full content out of TOON; only the slug, title, and description belong there.
4. Share one resolver for local user rows, cloud rows, and static app definitions. UI, activation, and `load_skill_resource` must not each implement source-specific lookup rules.
5. Treat app-skill cloning as a resource migration: copy static resources at clone time so the resulting user skill remains self-contained.
6. Use the dedicated cloud table for persistence and direct CRUD calls, with workspace invalidation events. Do not route resource content through `WorkspaceResource.data` merely to reuse the existing state protocol.
7. Measure activation and resource-result token size after implementation. If 50,000 characters is too expensive, lower the shared limit or add pagination/blob storage then; do not add pagination to v1 spec now.
