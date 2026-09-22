# A2UI lazy capability plan

## Objective

Remove unconditional A2UI catalog/schema text from the first model request while
preserving rendering, forms, validation, replay, component negotiation,
copyable text, and direct/cloud parity.

## Design decision

Expose one internal, content-only `a2ui` skill. Reuse the existing generic
`activate_skill` and `load_skill_resource` commands. Add no A2UI-specific
command, executable tool, credential, or runtime state.

| Resource | Purpose | Delivery |
| --- | --- | --- |
| `a2ui-core` | Envelope, surface lifecycle, root component, separate JSON objects, ordinary-text separation, application-owned actions. | Summary after activation; body on explicit load. |
| `a2ui-passive` | Passive catalog rules, schemas, and examples. | Summary after activation; body on explicit load. |
| `a2ui-forms` | Form catalog rules, schemas, and examples. | Summary after activation; body on explicit load. |

The initial request contains compact skill metadata only. A2UI bodies are
bounded resource responses, loaded only after capability activation.

## Behavior contract

- A2UI is visible to top-level runtime catalog/activation/resource lookup.
- Child conversations cannot discover, activate, or load A2UI.
- A2UI requires no settings, credentials, or executable tools.
- A2UI stays out of ordinary skill management, selector, clone, credential,
  and agent-association surfaces.
- Direct and cloud paths use the same slugs, generated profile, authorization,
  and resource content.
- Renderer catalogs, payload limits, malformed-envelope handling,
  unsupported-component filtering, action rejection, form validation, replay,
  event delivery, and copyable text remain unchanged.

## Merge checkpoint

The working tree was refreshed with:

```text
git fetch origin main
git merge --ff-only origin/main
```

The final base is `9372d3e96`, equal to `origin/main`. The fast-forward
included:

- `0f50980aa` — response-link pointer cursor.
- `fa0f1acbc` — unsaved-agent-change warning.
- `26ea66b49` — hide actions on non-final responses.
- `ba95c8645` — Redis Docker tag update.
- `9372d3e96` — contributor guidelines and validation guidance.

The only relevant overlap was `chat_messages_widget.dart`: upstream moved
final responses into activity runs and preserved A2UI replay payloads,
copyable text, and retry actions. Post-merge widget tests pass.

## Implementation ledger

### 1. Engine content-only definition — complete

- Added `AppSkillDefinition.contentOnly`.
- Added the internal definition registry and `a2uiSkillDefinition`.
- Added the three static resources and profile-based prompt generation.
- Kept the public engine barrel limited to supported app-facing contracts.

### 2. Local activation and resource lookup — complete

- Added separate runtime lookup while retaining user-facing skill management.
- Content-only skills bypass executable-tool and credential readiness checks.
- Activation requires a top-level conversation; missing lookup fails closed.
- Static resource resolution uses the existing generic authorization path.

### 3. Direct provider prompt removal — complete

- `ChatA2uiRuntime.enabled` still controls parsing and rendering.
- Removed direct-provider injection of the full A2UI catalog prompt.
- Retained renderer catalogs and validation schemas.

### 4. Generic lazy resource delivery — complete

```text
activate_skill({slug, revision})
  -> compact <skill_resources> summaries
load_skill_resource({skill, resource})
  -> bounded <skill_resource> CDATA content
```

No automatic resource-loading side effect was added. Shared CDATA delimiter
protection remains in the generic resource path.

### 5. Cloud catalog and authorization — complete

- Cloud catalogs include content-only A2UI only for top-level conversations.
- Activation persists ordinary conversation skill selection.
- Static A2UI resources are authorized through that selection.
- Content-only definitions never materialize executable tools.

### 6. Preservation and upstream-overlap checks — complete

- A2UI activity-run response rendering still works after the merge.
- A2UI replay payloads remain attached to the response message.
- Non-final responses keep actions hidden; final responses remain copyable.

## Measurements

Measured generated content in characters, not tokens:

| Content | Characters |
| --- | ---: |
| User-pasted baseline first prompt | 69,643 |
| A2UI-only initial catalog context | 318 |
| `a2ui-core` | 3,209 |
| `a2ui-passive` | 30,382 |
| `a2ui-forms` | 30,697 |
| All three resource bodies | 64,288 |
| Core plus passive | 33,591 |
| Core plus forms | 33,906 |

Expected first-request cost is 318 characters of A2UI metadata; large bodies
are paid only after activation and the relevant resource load.

## Verification ledger

Passed at final base `9372d3e96`:

- Engine A2UI/resource tests.
- App skill/catalog/chat tests, including
  `chat_messages_widget_test.dart` and A2UI replay cases.
- Server tool-runtime unit tests.
- Top-level A2UI prompt-removal integration case.
- Content-only activation and static-resource integration case.
- Engine, app, and server fatal analyzers.
- `fvm dart run melos run validate:quick`.
- `fvm dart format --line-length 80 -o none --set-exit-if-changed .`
  (`1906` files, zero changes).
- `git diff --check`.

The full Serverpod regression file still reports seven failures:

- Existing terminal provider-exchange expectation.
- Existing skill-schema/replay assertions.
- Existing tool-call identity mismatch.
- Existing transaction/rollback concurrency failure.
- Existing durable-cancellation timeout.
- Existing child model-selection/tool-decision conflict.

The same failure classes reproduced from a clean `origin/main` baseline
before the A2UI changes; they are outside this capability change. The two
new A2UI integration cases pass, and the cancellation-before-skill-loading
case passes at the final base. Do not loosen those existing assertions as part
of A2UI delivery.

## Acceptance status

Implementation and post-merge A2UI verification are complete. The branch
remains intentionally uncommitted for review. Full Serverpod regression is
not green because of pre-existing failures listed above.
