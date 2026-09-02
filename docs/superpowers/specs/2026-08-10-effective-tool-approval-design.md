# Effective Tool Approval Design

## Goal

Make tool approval behavior identical for local and cloud conversations while keeping the LLM-facing skill schema stable. Approval evaluates the effective tool capability hidden inside `call_skill_tool`, not the wrapper command.

## Decisions

- Newly available skill tools ask on first use per conversation.
- `list_skills` runs without confirmation.
- `load_skill` and `unload_skill` ask on first use per conversation.
- “Allow conversation” grants only the exact effective target.
- Local conversations store and evaluate grants locally.
- Cloud conversations store and evaluate grants on the server; the client only displays pending approvals and submits decisions.
- Malformed, stale, ambiguous, unloaded, or unresolved skill targets fail closed.
- Existing stable LLM tool schemas remain unchanged.

## Problem

AuraVibes exposes a stable `call_skill_tool` schema to preserve LLM prompt-cache compatibility. The command contains the real target in arguments:

```json
{
  "skill": "duckduckgo",
  "tool": "search",
  "args": {"query": "example"},
  "revision": "..."
}
```

Approval attached to `call_skill_tool` is too broad. Granting that wrapper can authorize every loaded skill tool. Local code already performs partial target unwrapping, while cloud execution has separate resolution and pending-state logic. Separate implementations can disagree, auto-run a nested tool, or show approval for the wrong identity.

## Approaches Considered

### Shared engine approval state machine — selected

The engine owns canonical target resolution results, approval outcomes, and pending/resume semantics. Local and server hosts provide storage and execution adapters.

This preserves offline local conversations, keeps cloud policy server-authoritative, and gives both hosts one behavioral contract.

### Separate local and server fixes

Smaller initial patch, but duplicates security-sensitive behavior and allows parity drift. Rejected.

### Route every approval through server

Provides one authority but breaks offline/local-first conversations and adds avoidable latency. Rejected.

## Architecture

### Engine responsibilities

`packages/auravibes_engine` defines host-neutral approval concepts:

- `EffectiveToolCall`: wrapper call plus canonical effective target.
- `EffectiveToolTarget`: exact target identity used for policy lookup and grants.
- `ToolApprovalOutcome`: `allow`, `ask`, or `deny` plus reason.
- approval orchestration: resolve target, query host policy, return execute/pending/rejected disposition.
- pending/resume state transitions and shared contract tests.

Engine code does not read Drift, Serverpod, Flutter, or app repositories.

### Host responsibilities

Local app adapter:

- resolves loaded manifests using local conversation/workspace state;
- stores exact-target grants in local repositories;
- persists pending tool calls in local message metadata;
- executes only after engine outcome is `allow`.

Cloud server adapter:

- resolves loaded manifests from authoritative server state;
- stores exact-target grants in server persistence;
- persists pending approval state before returning control;
- resumes the cloud turn only after an accepted server-side decision;
- never trusts a client assertion that a tool was approved.
- executes callback-backed tools only for built-in registered service skills;
- routes callback HTTP through the same public-URL, DNS/IP, redirect, response-size, timeout, and cancellation controls as URL-template tools;
- never executes user-provided or dynamically persisted Dart callbacks.

Cloud client:

- renders server pending state;
- submits `allowOnce`, `allowConversation`, or `deny`;
- does not independently mark cloud calls executable.

### Server callback execution boundary

Built-in service definitions are trusted application code and may expose either `urlTemplate` or `callback`. Cloud execution supports both through `AppSkillExecutor`, but injects a server-owned `SkillHttpClient`. Every callback-created request is validated at request time: public HTTP(S) syntax, DNS resolution, private-address rejection, redirects disabled, bounded response reads, cancellation checks, and existing server timeouts. Credential-bearing requests require HTTPS.

This does not introduce plugin code execution. User skills remain declarative URL templates; only callbacks compiled into `serviceSkillDefinitions` can run.

## Effective Target Identity

Policy identity is based on canonical resolved tool name, scoped by host storage:

```text
workspace + conversation + skill__<source>__<skill>__<tool>
```

Example:

```text
skill__app__duckduckgo__search
```

The wrapper name `call_skill_tool` is never persisted as permission identity for nested execution.

Control command identities remain exact stable names:

```text
load_skill
unload_skill
```

`list_skills` bypasses persistence because its fixed policy is `allow`.

## Data Flow

### Local nested skill call

1. LLM emits `call_skill_tool` with skill, tool, arguments, and manifest revision.
2. Engine parses command shape.
3. Local resolver validates loaded manifest, revision, unique target, and argument schema.
4. Resolver returns canonical `EffectiveToolTarget`.
5. Local policy adapter checks conversation grant, then workspace policy.
6. `allow` executes target; `ask` persists pending call; `deny` persists rejection.
7. UI decision updates exact-target grant when requested and resumes same call.
8. Executor validates target and revision again before side effects.

### Cloud nested skill call

1. Server receives model tool call.
2. Engine parses command shape.
3. Server resolver validates target against authoritative loaded-skill state.
4. Server policy adapter evaluates exact effective target.
5. `ask` is persisted server-side and streamed to client as pending.
6. Client submits decision referencing message ID and tool-call ID.
7. Server verifies pending state, applies exact-target grant if requested, and resumes execution.
8. Executor revalidates target and revision before side effects.

## Policy Precedence

For an exact effective target:

1. explicit conversation grant or deny;
2. workspace tool policy;
3. default policy.

Defaults:

| Capability | Default |
| --- | --- |
| `list_skills` | allow |
| `load_skill` | ask |
| `unload_skill` | ask |
| newly loaded skill tool | ask |
| unresolved or malformed target | deny |

“Allow once” changes only current pending call. “Allow conversation” grants only exact effective target for current conversation.

## Approval UI

Approval cards show effective target, not only wrapper:

```text
DuckDuckGo Search / search
```

Optional secondary metadata may show transport command `call_skill_tool`, but user decision always names actual capability. Buttons remain:

- Allow once
- Allow conversation
- Deny

Cloud and local cards consume same pending approval presentation model.

## Error Handling and Logging

Fail closed before execution when:

- command JSON is malformed;
- manifest is not loaded;
- manifest revision is stale;
- target is missing or ambiguous;
- permission identity cannot be resolved;
- pending call was already completed;
- cloud approval request is stale or mismatched.

Every denial, pending transition, approval, retry suppression, and execution failure logs structured non-secret fields:

- conversation ID;
- message ID;
- tool-call ID;
- wrapper name;
- effective target name when resolved;
- host (`local` or `server`);
- approval outcome and reason.

Raw arguments, credentials, headers, response bodies, and secrets are excluded or redacted.

## Migration

No DB schema change is required unless server storage lacks exact tool-name permission records. Existing exact native skill permissions continue working.

Broad legacy `call_skill_tool` grants must not authorize nested targets. They are ignored for nested execution rather than migrated, because expanding one broad grant into all current skills would preserve unsafe scope.

Existing exact-target grants remain valid. Missing exact-target records receive default `ask` on first use.

## Testing

### Engine contract tests

- resolves wrapper to exact effective target;
- never evaluates nested execution under wrapper identity;
- returns `ask` for first use;
- exact conversation grant returns `allow`;
- different tool in same skill still asks;
- malformed/stale/unresolved targets deny;
- pending call resumes once only.

### Local app tests

- DuckDuckGo search prompts before execution;
- allowing once executes one call only;
- allowing conversation suppresses later prompt for DuckDuckGo search;
- another DuckDuckGo tool still prompts;
- `list_skills` auto-runs;
- `load_skill` and `unload_skill` prompt first use;
- effective target appears in approval card;
- no network callback runs before approval.

### Server tests

- cloud nested call persists pending state before execution;
- client approval cannot bypass server policy;
- exact server grant resumes matching call;
- stale/mismatched approval is rejected;
- server restart preserves pending state and grants;
- no server executor runs before authoritative allow.
- built-in DuckDuckGo callback executes only after authoritative approval;
- callback HTTP rejects private/loopback destinations and redirects;
- callback response reads remain bounded and cancellation closes the client;
- user/dynamic skills cannot register executable callbacks.

### Parity tests

Run same approval scenarios against local and server host adapters and assert identical outcomes, differing only in persistence location.

## Scope Boundaries

Included:

- skill control and nested skill tool approval;
- shared engine approval contract;
- local and cloud parity;
- approval logging and presentation identity.

Excluded:

- changing LLM-visible tool schemas;
- generic risk classification;
- cross-workspace grants;
- permanent account-wide grants;
- redesigning unrelated MCP approval storage;
- migrating broad wrapper grants into exact grants.

Built-in registered service callbacks are included because cloud execution support was explicitly selected.
