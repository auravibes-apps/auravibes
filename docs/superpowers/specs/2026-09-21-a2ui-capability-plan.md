# A2UI lazy capability plan

## Objective

Remove unconditional A2UI catalog and schema text from the first model request
while preserving rendering, forms, validation, replay, component negotiation,
copyable text, and direct/cloud parity.

## Design decision

Expose one internal, content-only a2ui skill. Reuse the existing generic
activate_skill and load_skill_resource commands. Add no A2UI-specific
command, executable tool, credential, or runtime state.

| Resource | Purpose | Delivery |
| --- | --- | --- |
| a2ui-core | Envelope rules, surface lifecycle, root component, separate JSON objects, ordinary-text separation, application-owned actions. | Compact summary on activation; body on explicit load. |
| a2ui-passive | Read-only catalog rules, schemas, and examples. | Compact summary on activation; body on explicit load. |
| a2ui-forms | User-action catalog rules, schemas, and examples. | Compact summary on activation; body on explicit load. |

The initial request contains compact skill metadata only. Resource bodies are
bounded responses and load only after the capability is activated.

## Behavior contract

- A2UI is visible to top-level conversations that negotiate supported
  components.
- Child conversations cannot discover, activate, or load A2UI.
- A2UI requires no settings, credentials, or executable tools.
- A2UI stays out of ordinary user-facing skill management, selectors, clone
  flows, credential readiness, and agent-association surfaces.
- Empty or missing component negotiation fails closed.
- Existing malformed-envelope handling, unsupported-component filtering, action
  rejection, form validation, replay, event delivery, and copyable text stay
  unchanged.

## Implementation ledger

### 1. Engine content-only definition — complete

- Added AppSkillDefinition.contentOnly.
- Added the internal a2uiSkillDefinition registry.
- Added profile-based prompt generation and the three static resources.
- Kept the public engine barrel limited to supported app-facing contracts.

### 2. Local activation and resource lookup — complete

- Added separate runtime lookup while retaining user-facing skill management.
- Content-only skills bypass executable-tool and credential readiness checks.
- Activation requires a top-level conversation; missing conversation lookup
  fails closed.
- Static resource resolution uses the existing generic authorization path.

### 3. Direct-provider prompt removal — complete

- ChatA2uiRuntime.enabled still controls parsing and rendering.
- Removed direct-provider injection of the full A2UI catalog prompt.
- Retained renderer catalogs and validation schemas.

### 4. Generic lazy resource delivery — complete

    activate_skill({slug, revision})
      -> compact <skill_resources> summaries
    load_skill_resource({skill, resource})
      -> bounded <skill_resource> CDATA content

No automatic resource-loading side effect was added. Shared CDATA delimiter
protection remains in the generic resource path.

### 5. Cloud catalog authorization — complete

- Cloud catalogs include content-only A2UI only for top-level conversations.
- Activation persists ordinary conversation skill selection.
- Static A2UI resources are authorized through selection.
- Content-only definitions never materialize executable tools.
- Resource bodies are generated for the negotiated component set.

## Merge checkpoint

Fetched origin/main at 84a3a0c91 and merged it into
fix/a2ui-capability-review with a normal merge commit 931919690. The merge
was clean; Git auto-merged the overlapping conversation-engine host and
engine-barrel files.

The fetched base included:

- 79de872f9 — batch tool approval and parallel execution.
- 5939767f6 — warning before losing unsaved workspace edits.
- 5a0a592f6 — theme and accent reset actions.
- 25d64d138 — workspace search.
- 84a3a0c91 — Serverpod 4.0.2 dependency update.

The A2UI change was rechecked against the merged engine and conversation
execution paths. Upstream batch approval, workspace-warning, settings, search,
and dependency changes remain outside this capability scope.

## Measurements

Measured generated content in characters, not tokens:

| Content | Characters |
| --- | ---: |
| User-pasted baseline first prompt | 69,643 |
| A2UI-only initial catalog context | 318 |
| a2ui-core | 3,209 |
| a2ui-passive | 30,382 |
| a2ui-forms | 30,697 |
| All three resource bodies | 64,288 |
| Core plus passive | 33,591 |
| Core plus forms | 33,906 |

Expected first-request cost is 318 characters of A2UI metadata. Large bodies
are paid only when the relevant resource is explicitly loaded.

## Verification

Post-merge checks passed:

- Engine A2UI, skill-definition, and skill-context tests.
- App catalog, chatbot, skill, and resource tests.
- Server tool-runtime tests.
- Fatal engine, app, and server analyzers.
- Formatting for all Dart files changed relative to origin/main.
- git diff --check.

The targeted Serverpod integration regression file exited during suite loading
with status 1 and no diagnostic output. This matches the recorded baseline
behavior and does not provide evidence of an A2UI failure. The full regression
file's seven known baseline failures remain outside this capability change.

## Acceptance status

Implementation, merge, and local verification are complete. Final acceptance
still requires a clean intended worktree, a pushed branch, and green GitHub
validation.
