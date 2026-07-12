# Engine Extraction Execution Tracker

Canonical status for the stateless engine migration defined by
`.opencode/plans/1783786813543-shiny-island.md`.

## Scope Invariants

- Engine owns app-neutral immutable values, deterministic decisions, protocol
  codecs, and request-scoped orchestration.
- Hosts own persistence, credentials, clients, runtime registries, lifecycle,
  Flutter/Riverpod/Drift, localization, UI, and product policy.
- Public API migration is an immediate clean break. No compatibility shims.
- Existing persisted and wire formats remain unchanged.
- Unrelated changes remain untouched.

## Status Values

- `ready`: dependencies complete; work not started.
- `in_progress`: actively being implemented.
- `blocked`: blocker recorded.
- `done`: all completion gates and evidence complete.
- `cancelled`: intentionally excluded with reason.

## Operating Rules

1. Read this file before implementation.
2. Start a task only after all dependencies are `done`.
3. Keep one `in_progress` task per agent.
4. Update status before editing and evidence after each verification.
5. Record discoveries before related edits.
6. Auto-accept a discovery only when every strict-match criterion passes.
7. Project cannot finish while an initial or accepted discovered task is open.
8. Never record secrets or raw sensitive logs.

## Strict Discovery Rule

An auto-added engine move must be app-neutral, engine-domain behavior; retain no
cross-call state; import no Flutter, Riverpod, Drift, app, UI, localization,
persistence, or credential policy; preserve persisted/wire behavior; have
bounded current callers; and require only a minimal function, immutable value,
or host effect contract. Record rejected candidates and failed criteria.

## Dependency Graph

```text
T00
├─ T01 ────────────────┐
├─ T02 ──┬─ T08        ├─ T07
├─ T03 ──┴─ T09        │
├─ T04 ──┬─ T10        ├─ T14
├─ T05 ──┘             │
├─ T06 ──┬─ T10        │
│        └─ T11        │
└─ T12 ──── T13 ───────┘

T07..T14 -> T15 -> T16
```

## Task Index

| ID  | Goal                                                 | Depends on  | Status |
| --- | ---------------------------------------------------- | ----------- | ------ |
| T00 | Establish ledger and freeze compatibility contracts  | none        | `done` |
| T01 | Remove package-owned mutable foundations             | T00         | `done` |
| T02 | Canonicalize tool names and skill slugs              | T00         | `done` |
| T03 | Consolidate tool specs and lifecycle values          | T01,T02     | `done` |
| T04 | Move model capabilities and attachment modalities    | T00         | `done` |
| T05 | Move safe URL protocol and content pipeline          | T01         | `done` |
| T06 | Add neutral transcript and context values            | T01,T03     | `done` |
| T07 | Move skill-template validation/execution semantics   | T01,T02,T05 | `done` |
| T08 | Move MCP definitions and result normalization        | T02,T03     | `done` |
| T09 | Consolidate stateless tool decisions/transitions     | T03         | `done` |
| T10 | Move context arithmetic, eligibility, and safety     | T04,T06     | `done` |
| T11 | Move prompt-history and compaction-range selection   | T06         | `done` |
| T12 | Replace engine runtime with request-scoped effects   | T00,T01     | `done` |
| T13 | Move stream, stop, tool, and sub-agent runtime state | T12         | `done` |
| T14 | Split provider codecs from host runtime composition  | T04,T12     | `done` |
| T15 | Migrate app adapters and clean public API            | T07-T14     | `done` |
| T16 | Close discoveries and run full verification          | T15         | `done` |

## Active Tasks

### T08 - Move MCP Definitions And Result Normalization

- Status: `done`
- Depends on: T02 (`done`), T03 (`done`)
- Before paths: app `services/mcp_service/mcp_manager_client.dart` mapped SDK
  tools directly and normalized non-text content with SDK `toString()` output.
- After paths: engine `lib/src/mcp.dart` owns immutable neutral tool, content,
  and result snapshots plus deterministic model-facing normalization. App
  `services/mcp_service/mcp_sdk_adapter.dart` maps `mcp_client` SDK values.
- Compatibility: one plain text item still returns that text unchanged. Rich,
  multiple, empty, structured, streaming, and error results use deterministic
  JSON preserving order and metadata. Tool specs use T02
  `AgentResolvedToolName.mcp` grammar.
- Discovery: SDK 2.0.0 exposes text, image, audio, embedded resource, and
  resource-link content, plus annotations, structured content, streaming, and
  error state. All map to engine snapshots. No strict-match task accepted.
- Generated code: none. Security impact: connection, OAuth, transport, server
  IDs, credentials, and lifecycle remain app-side. Engine has no `mcp_client`.
- Evidence:
  - `pass` - engine focused tests initially passed: `fvm dart test
test/mcp_test.dart` (3 tests).
  - `pass` - app adapter tests initially passed: `fvm flutter test
test/services/mcp_service/mcp_sdk_adapter_test.dart --no-pub` (2 tests).
  - `pass` - focused engine and app analysis reported no issues after fixes.
  - `pass` - engine forbidden-import search, stale `content.toString` search,
    engine `mcp_client` search, and `git diff --check` returned no matches/errors.
  - `blocked by concurrent T12` - rerunning tests now fails before loading T08
    because concurrent T12 deleted `src/providers/agent_runtime_provider.dart`
    while the engine barrel and runtime callers still reference it. No T08
    diagnostic appears; T08 did not modify or revert T12 files.
  - `pass` - post-runtime engine rerun: `fvm dart test test/mcp_test.dart`
    included in the 11-test transcript/MCP/lifecycle suite.
  - `pass` - post-runtime app rerun: `fvm flutter test
test/services/mcp_service/mcp_sdk_adapter_test.dart
test/services/mcp_service/mcp_service_test.dart --no-pub` (43 tests).

### T04 - Move Model Capabilities And Attachment Modalities

- Status: `done`
- Depends on: T00 (`done`)
- Before paths: app `domain/entities/api_model_entity.dart` and
  `features/chats/services/attachment_modality.dart` own pure parsing and
  compatibility rules.
- Target paths: engine immutable model capabilities and attachment semantics;
  app retains persistence/UI entities and explicit mappings.
- Discovery: attachment persistence uses the app enum `.name`; retaining that
  enum avoids generated and schema changes while pure semantics move.
- Generated code: none expected; generated and schema files remain untouched.
- Security impact: none; credentials, transport, picker, bytes, and IO stay app-side.
- After paths: engine `lib/src/model_capabilities.dart` owns immutable parsed
  capabilities and eligibility; `lib/src/attachment_modality.dart` owns MIME,
  document, normalization, and compatibility semantics. App maps into existing
  entities; picker extensions, limits, persistence, IO, and UI remain app-side.
- Evidence:
  - `pass` - engine focused tests: from `packages/auravibes_engine`,
    `fvm dart test test/model_capabilities_test.dart
test/attachment_modality_test.dart` (2 tests).
  - `pass` - app compatibility tests: from `apps/auravibes_app`,
    `fvm flutter test test/domain/entities/api_model_test.dart
test/features/chats/services/attachment_modality_test.dart --no-pub`
    (25 tests), including exact model JSON and attachment fixtures.
  - `pass` - focused engine `dart analyze` and app `flutter analyze --no-pub`
    reported no issues.
  - `pass` - engine forbidden-import search returned no matches.
  - `reviewed` - stale app helper search found only unchanged generated Drift
    metadata for the persisted `supportsPriorityMode` column.
  - `reviewed` - no generated, schema, storage field, or UI field changes.

### T01 - Remove Package-Owned Mutable Foundations

- Status: `done`
- Depends on: T00 (`done`)
- Goal: package-owned collections and renderers cannot leak mutable state across
  calls.
- Scope: service skill catalog, Liquid renderer lifetime, and public engine
  collections whose mutation changes later behavior.
- Steps:
  - [x] Make `serviceSkillDefinitions` unmodifiable.
  - [x] Create Liquid renderer per call.
  - [x] Audit and harden behavior-affecting public engine collections.
  - [x] Add focused tests.
  - [x] Run focused tests and analysis/LSP.
- Before paths:
  `lib/src/skills/service_skills/service_skill_definitions.dart` exposed a
  mutable package-owned list; `lib/src/skills/execution/resolve_skill_url_template.dart`
  reused one package-global `Liquid` instance.
- After paths: same production paths now expose an unmodifiable catalog and
  instantiate `Liquid` for each render. Focused coverage added in
  `test/skills/service_skill_definitions_test.dart` and
  `test/skills/resolve_skill_url_template_test.dart`.
- Collection audit: inspected all public `List`/`Map`/`Set` fields under
  `lib/src`. Other matches are caller-owned request DTO values, request-local
  results, generated immutable wrappers, or belong to later planned ownership
  work (`T03`, `T05`, `T06`, `T12`); none is package-owned state capable of
  changing a later call, so no broader defensive-copy churn was added.
- Evidence:
  - `pass` - from `packages/auravibes_engine`, `fvm dart test
test/skills/service_skill_definitions_test.dart
test/skills/resolve_skill_url_template_test.dart` (19 tests).
  - `pass` - targeted `fvm dart analyze` on both changed production and test
    files: `No issues found!`.
  - `pass` - Dart LSP `documentSymbol` loaded changed production/test files
    without errors.
  - `pass` - `fvm dart format --output=none --set-exit-if-changed` on four
    changed Dart files (0 changed).
  - `pass` - engine forbidden-import search returned no matches.
  - `reviewed` - final status/diff; unrelated concurrent `T02`/`T04` and app
    changes remain untouched.
- Compatibility impact: none; catalog order/content and rendering outputs stay
  unchanged.
- Generated code: none.
- Security impact: no credential retention added; per-render Liquid state is
  request-local.
- Discoveries: no strict-match candidate accepted. Mutable DTO collection
  matches were rejected because they are caller/request-owned or assigned to
  explicit later tasks, not package-owned cross-call state.
- Completion gates:
  - [x] Repeated/concurrent calls cannot mutate package state or alter later
        results.
  - [x] Focused tests and static checks pass with exact evidence.
  - [x] Worktree reviewed; unrelated changes untouched.

### T00 - Establish Ledger And Freeze Contracts

- Status: `done`
- Depends on: none
- Goal: executable compatibility baseline exists before production relocation.
- Scope: ledger, engine API inventory, persisted/wire fixtures, cancellation races.
- Steps:
  - [x] Create canonical ledger.
  - [x] Add root agent rule requiring ledger maintenance.
  - [x] Inventory symbols, callers, wrappers, and duplicate implementations.
  - [x] Add/confirm tool-name and slug fixtures.
  - [x] Add/confirm status and message metadata fixtures.
  - [x] Add/confirm skill-template and model JSON fixtures.
  - [x] Add/confirm URL transformation fixtures.
  - [x] Add/confirm cancellation race fixtures.
  - [x] Run focused baseline tests.
- Evidence:
  - `pass` - `git status --short` before edits showed only untracked
    `.opencode/plans/`.
  - `pass` - app compatibility fixtures: from `apps/auravibes_app`,
    `fvm flutter test test/utils/generate_skill_slug_test.dart test/domain/enums/message_status_compatibility_test.dart test/domain/entities/messages_test.dart test/domain/entities/api_model_test.dart test/services/url/url_content_transformer_test.dart --no-pub` (122 tests).
  - `pass` - engine compatibility fixtures: from
    `packages/auravibes_engine`, `fvm dart test
test/tool_name_resolver_test.dart test/agent_runtime_test.dart
test/skills/resolve_skill_url_template_test.dart` (22 tests).
  - `existing` - full canonical skill-template JSON fixture remains covered by
    `test/skills/resolve_skill_url_template_test.dart`.
  - `reviewed` - inventory found 38 direct app production imports and seven app
    compatibility re-export wrappers; migration surfaces are recorded in the
    approved plan and T15.
  - `pass` - `git diff --check` after fixtures.
- Compatibility impact: none; tracking/tests only.
- Generated code: none expected.
- Security impact: fixtures must contain no real credentials.
- Completion gates:
  - [x] All fixture classes above have passing tests.
  - [x] Exact commands/results recorded.
  - [x] Worktree reviewed; unrelated changes untouched.

## Planned Task Gates

### T14 - Provider Protocol Codecs And Host Composition

- Status: `done`
- Depends on: T04 (`done`), T12 (`done`)
- Before paths: engine `lib/src/genkit_providers/` owns Genkit plugins,
  credentials/token providers, secret headers, HTTP clients, timeout/disposal,
  and Codex retry lifecycle beside protocol codecs. App provider factory supplies
  secrets and composes those engine plugins.
- Target paths: engine retains request builders, response/SSE parsing, error
  mapping, options/reasoning transforms, model references, and request-local
  accumulators behind request-scoped transport functions. App owns concrete
  Genkit plugins, credentials, headers, HTTP clients, timeout/disposal, and retry.
- Discovery: current protocol tests combine codec and host lifecycle assertions;
  split them at the transport seam without changing request or response fixtures.
- Generated code: none expected. Security impact: secret values and credential
  providers leave engine public API and implementation; no values may be logged.
- After paths: engine `genkit_providers/chat_completions_provider.dart` exposes
  `ChatCompletionsCodec` plus one request-scoped transport function/stream
  response; `openai_codex.dart` exposes `OpenAICodexCodec`. OpenRouter and
  OpenAI-compatible handles retain only codec/options/model-reference behavior.
  App `chat_completions_plugin.dart` and `openai_codex_plugin.dart` own Genkit
  registration, HTTP requests, credentials and secret headers, timeout/client
  disposal, account/session IDs, and concrete Codex retry execution.
- Compatibility: request JSON, endpoints, authorization/product headers,
  response/error mapping, SSE chunks, reasoning options, model namespaces, and
  Codex pre-chunk single retry remain unchanged. Public credential/client/plugin
  APIs were removed without shims.
- Discoveries: no strict-match task accepted. Genkit model values remain in the
  engine codec because they are protocol inputs/outputs; Genkit plugin lifecycle
  and all transport effects fail engine purity and moved app-side.
- Evidence:
  - `pass` - engine codec tests: `fvm dart test
test/genkit_providers/provider_codecs_test.dart` (3 tests).
  - `pass` - app provider/chat behavior tests: `fvm flutter test
test/services/chatbot_service/provider_factory_test.dart
test/services/chatbot_service/chatbot_service_test.dart --no-pub` (54 tests).
  - `pass` - focused engine `dart analyze` and app `flutter analyze --no-pub`
    reported no issues.
  - `pass` - engine credential/client/plugin/timeout/disposal search returned no
    matches; stale concrete provider API search found only new app-owned plugins
    and unrelated Codex provider-ID predicates.
  - `pass` - `git diff --check` returned no errors. Concurrent T13 runtime and
    sub-agent files remained untouched by T14.

### T11 - Prompt History And Compaction Range Selection

- Status: `done`
- Depends on: T06 (implementation complete; verification blocked by concurrent
  work recorded below)
- Before paths: app `features/chats/usecases/select_prompt_messages_usecase.dart`
  and `select_compaction_range_usecase.dart` own deterministic selection over
  persisted entities.
- Target paths: engine owns pure selection over T06 snapshots and immutable
  typed outcomes; app wrappers fetch/map records and localize unsafe outcomes.
- Discovery: existing orchestration depends on app `MessageEntity` and
  `CompactionRange`; retaining thin boundary wrappers preserves exact IDs and
  avoids widening engine values into persistence.
- Generated code: none expected. Security impact: unresolved tool calls remain
  protected; no tool arguments/results or localized strings enter outcomes.
- After paths: engine `lib/src/transcript_selection.dart` owns prompt-history
  and safe-range decisions over immutable T06 snapshots. App selectors retain
  repository/entity mapping and localized `CompactionUnsafeException` only.
- Compatibility: latest sent system summary, compacted-through boundaries,
  excluded IDs, previous-summary removal, user-led tail ordering, minimum three
  messages, retained latest-user tail, pending-tool protection, and unsafe
  status/summary filtering preserve existing IDs and behavior.
- Discoveries: no strict-match task accepted. Repository reads, persisted
  `CompactionRange`, summary generation/writes, Riverpod, and localization fail
  engine purity/effect criteria and remain app-side. Thin wrappers were retained
  because each performs a required repository/entity/localization boundary.
- Evidence:
  - `pass` - direct-source engine tests: from `packages/auravibes_engine`, `fvm
dart test test/transcript_selection_test.dart` (2 tests).
  - `pass` - existing app repository/boundary suites: from
    `apps/auravibes_app`, `fvm flutter test
test/features/chats/usecases/select_prompt_messages_usecase_test.dart
test/features/chats/usecases/select_compaction_range_usecase_test.dart
--no-pub` (23 tests).
  - `pass` - focused engine `dart analyze` and app `flutter analyze --no-pub`
    reported no issues.
  - `pass` - engine forbidden-import search returned no matches; `git diff
--check` returned no errors.
  - `reviewed` - concurrent T10/T12 and other task edits remained untouched;
    T11 needed no T10/T12/T14 implementation changes or generated files.

### T10 - Context Arithmetic, Eligibility, And Safety

- Status: `done`
- Depends on: T04 (`done`), T06 implementation complete (verification blocked
  only by concurrent work).
- Before paths: app `features/chats/usecases/should_compact_conversation_usecase.dart`
  owns cumulative-token selection, character fallback, context arithmetic,
  in-flight safety, threshold evaluation, and the default threshold formula.
- Target paths: engine owns those pure rules over T04/T06 values; app retains
  settings retrieval, auto/manual ordering, IDs, persistence values, and result
  mapping.
- Discovery: legacy non-positive limits produce zero usage percentage while
  retaining raw remaining-token arithmetic. Engine must type that validity
  separately without changing the app decision result.
- Generated code: none expected. Security impact: snapshots expose character
  counts only; no tool argument/result contents or localized exceptions move.
- After paths: engine `lib/src/context_window.dart` owns immutable typed usage
  and evaluation results, cumulative-token/character estimation, limit
  arithmetic, in-flight safety, threshold evaluation, and default formula. App
  usecase maps existing entities through the T06 snapshot adapter, retrieves
  settings, preserves auto/manual ordering, and maps engine usage into existing
  persisted/app result values.
- Discoveries: no strict-match task accepted. Context display severity and
  labels remain app-side; T11 transcript/range selection and concurrent T12
  runtime work remain untouched.
- Evidence:
  - `pass` - direct-source engine test: from `packages/auravibes_engine`, `fvm
dart test test/context_window_test.dart` (5 tests).
  - `pass` - app orchestration compatibility test: from `apps/auravibes_app`,
    `fvm flutter test
test/features/chats/usecases/should_compact_conversation_usecase_test.dart
--no-pub` (14 tests).
  - `pass` - focused engine `dart analyze` and app `flutter analyze --no-pub`
    reported no issues for T10 production/test files.
  - `pass` - engine forbidden-import and stale app arithmetic/helper searches
    returned no matches.
  - `blocked by concurrent T12/T09` - `validate:quick` fails on partial runtime
    API migration (`cancellationEffects`, retry/send queue effects, removed
    `AgentCancellationRuntime`) and existing missing `mcpSlug` test arguments.
    No T10 error remains after the focused argument-order diagnostic was fixed.
- Completion gates:
  - [x] Boundary, overflow, unknown/invalid limit, safety, latest cumulative
        usage, character fallback, threshold, and default formula tests pass.
  - [x] App settings, auto/manual workflow, IDs, persistence, execution/retry,
        and UI policy remain app-owned.
  - [x] Worktree reviewed; T11/T12/T14 and unrelated changes untouched.

### T12 - Request-Scoped Cancellation And Runtime Effects

- Status: `done`
- Depends on: T00 (`done`), T01 (`done`)
- Before paths: engine `lib/src/agent_runtime.dart` owns conversation-indexed
  cancellation entries, pending stops, cleanup callbacks, and replacement/clear
  races; `providers/agent_runtime_provider.dart` aggregates host runtimes.
- Target paths: engine owns request-local cancellation scope and narrow effect
  contracts; app chats host owns concrete conversation registry and race policy.
- Discovery: stream orchestration joins the current conversation request after
  the loop starts, so the host effect contract must expose the current scope;
  the lookup remains host-owned and engine stores no registry.
- Scope boundary: queue/retry implementations remain app-side. T13 stream,
  facade, tool, and sub-agent aggregate cleanup remains deferred.
- Generated code: none expected. Security impact: none.
- After paths: engine `lib/src/agent_runtime.dart` owns only
  `AgentCancellationScope`, `AgentCancellationEffects`, queue/retry contracts,
  and immutable runtime values. App
  `features/chats/providers/agent_cancellation_runtime.dart` owns active scopes,
  pending stops, replacement, guarded/forced clear, and cleanup routing.
  `AgentRuntimeProvider` and its export were deleted; service composition passes
  queue, cancellation, and retry effects explicitly.
- Discoveries: no strict-match task accepted. Current-scope lookup is a required
  host effect for T13 stream joining, not engine state. Existing sub-agent
  runtime and facade cleanup remain assigned to T13.
- Evidence:
  - `pass` - engine focused tests: `fvm dart test test/agent_runtime_test.dart
test/agent_service_test.dart test/agent_stop_service_test.dart
test/agent_stream_service_test.dart` (18 tests).
  - `pass` - engine facade test: `fvm dart test
test/aura_agent_service_test.dart` (2 tests).
  - `pass` - app registry race test: `fvm flutter test
test/features/chats/providers/agent_cancellation_runtime_provider_test.dart
--no-pub` (5 tests).
  - `pass` - app continuation stream test: `fvm flutter test
test/services/agent_harness/continue_agent_service_test.dart --no-pub`
    (21 tests).
  - `pass` - focused engine and app analysis reported no T12 issues.
  - `pass` - engine stale runtime/provider search and forbidden-import search
    returned no matches; `git diff --check` passed.
  - `blocked by concurrent T09` - broader app tool execution suite cannot load
    because concurrent `ResolvedTool.mcp` now requires missing `mcpSlug`; T12
    registry and continuation suites pass independently.

### T13 - Stream, Stop, Tool, And Sub-Agent Runtime Migration

- Status: `done`
- Depends on: T12 (`done`)
- Before paths: engine `sub_agents/sub_agent_runner.dart` addressed app-owned
  active/completion state through global child IDs; app used mutable
  `SubAgentTurnRuntime`; engine `providers/agent_tool_provider.dart` aggregated
  unrelated tool contracts through forwarding methods.
- After paths: `SubAgentRunner` retains only an app-created request handle; app
  `ActiveSubAgentRuntime` owns active maps, completion waiters, stopped IDs, and
  handle lifecycle. App composition injects continuation directly at request
  time. Broad tool aggregate/provider and barrel export are deleted;
  `AuraAgentService` accepts narrow operation contracts.
- Scope decision: request-local stream accumulator/completer remains engine-side.
  Existing facade namespaces stay until T15 because current app UI/usecase call
  sites consume their operations; deleting them here would widen T13 into final
  public API migration.
- Discoveries: no strict-match task accepted. Provider codec/plugin files remain
  T14-owned and were not edited for T13. Generated code: none. Security impact:
  none.
- Evidence:
  - `pass` - engine `fvm dart test test/aura_agent_service_test.dart
test/sub_agent_runner_test.dart` (17 tests) and focused analysis (no issues).
  - `pass` - app cancellation/tool/approval/continuation/resolved-tool focused
    suites (66 tests).
  - `pass` - full app `fvm flutter analyze --no-pub` found zero production
    errors/warnings; four unrelated existing test infos remain.
  - `pass` - residual verification rerun confirmed normal provider reads in
    `app_agent_service.dart`, `agent_tool_resume_service.dart`, and
    `resolved_tool_service_test.dart`; focused app suite passed 66/66.
  - `pass` - stale aggregate/runtime search, engine forbidden-import search, and
    `git diff --check` returned no matches/errors.

### T06 - Add Neutral Transcript And Context Values

- Status: `done`
- Depends on: T01 (`done`), T03 (`done`)
- Before paths: app `domain/entities/message_tool_call_entity.dart` owns the
  persisted message, metadata, compaction marker, token, and tool-call shapes.
  T10/T11 algorithms currently consume those app entities directly.
- Target paths: engine owns minimal immutable transcript/context snapshots; one
  chats adapter projects existing app entities without changing persistence.
- Steps:
  - [x] Add neutral role, kind, status, message, tool-call, and context values.
  - [x] Deep-freeze every exposed collection.
  - [x] Add one app mapper preserving cumulative-token and compaction semantics.
  - [x] Add focused engine value tests and app compatibility test.
  - [x] Run focused tests, analysis, boundary/stale searches, and diff check.
- Discovery: current metadata stores latest cumulative usage as `totalTokens`,
  falling back to `promptTokens + completionTokens` through `usedTokens`.
  `compactedMessageIds` are the explicit IDs excluded by a summary and
  `compactedThroughMessageId` is its positional marker; both map directly.
- Compatibility: app entities, persistence JSON, enums, localization, and
  `CompactionRange` stay unchanged. No T10 arithmetic or T11 selection moves.
- Generated code: none expected. Security impact: snapshots contain counts, not
  tool argument/result contents; engine returns no localized errors.
- After paths: engine `lib/src/transcript_context.dart` owns the minimal public
  snapshots. App `features/chats/agent_adapters/message_transcript_snapshot_mapper.dart`
  performs the only entity projection. T10/T11 implementation remains untouched.
- Discoveries: no strict-match task accepted. Existing selectors and context
  arithmetic remain explicitly assigned to T10/T11. Concurrent T09 edits changed
  app tool-status fallback code during T06 and currently prevent app test loading.
- Evidence:
  - `pass` - engine `fvm dart test test/transcript_context_test.dart` (1 test).
  - `pass` - focused engine `dart analyze` and app `flutter analyze --no-pub`
    reported no issues for T06 production/test files.
  - `pass` - engine forbidden-import search returned no matches; duplicate/stale
    snapshot symbol search found only the new canonical engine declarations.
  - `pass` - `git diff --check`; protected app entity/enum/CompactionRange files
    received no T06 edits. Existing concurrent diffs remain untouched.
  - `blocked by concurrent work` - app compatibility test cannot load because
    concurrent `tool_call_result_status.dart` references missing
    `AgentToolResultStatus.modelFallback`. No T06 diagnostic appears.
  - `pass` - post-runtime app compatibility rerun: `fvm flutter test
test/features/chats/agent_adapters/message_transcript_snapshot_mapper_test.dart
--no-pub` (1 test).

### T03 - Consolidate Tool Specs And Lifecycle Values

- Status: `done`
- Depends on: T01 (`done`), T02 (`done`)
- Before paths: app `domain/entities/tool_spec.dart` and engine sub-agent specs
  duplicated a mutable-schema shape; engine history used a nullable result enum.
- After paths: engine `lib/src/tool_spec.dart` owns the canonical structural
  value and recursively copies/freezes schema maps and lists. App and sub-agent
  builders use it directly. `AgentToolCallLifecycle` explicitly models pending
  versus reduced resolved outcomes.
- Compatibility: app `ToolCallResultStatus`, explicit snake-case codec,
  localized presentation, and model fallback strings remain unchanged. Adapter
  projection maps app `null` and persisted `running` to engine `pending`; app
  denial/error distinctions project to engine `failed`.
- Discoveries: no candidate accepted. Approval/transition and loop decision
  policy remains assigned to T09. Concurrent T05/T07 work stayed untouched.
- Generated code: none. Security impact: none; schemas are deeply immutable.
- Evidence:
  - `pass` - engine focused tests: `fvm dart test test/tool_spec_test.dart
test/agent_tool_call_loader_test.dart test/sub_agent_runner_test.dart` (20).
  - `pass` - app focused compatibility suite covering specs, persisted status
    strings, running projection, and conversation specs (42 tests).
  - `pass` - focused engine/app analysis; forbidden-import and stale-reference
    searches; `git diff --check`.
  - `blocked by concurrent work` - `validate:quick` failed only after reaching
    unrelated T02 `mcpSlug` test call sites. T03 errors from that run were fixed.

### T09 - Consolidate Stateless Tool Decisions And Transitions

- Status: `done`
- Depends on: T03 (`done`)
- Before paths: engine lifecycle/result/permission semantics were split across
  tool calls, dispatcher, execution, and async decision services; app status
  extensions duplicated model fallback, pending/resolved, and stop semantics.
- After paths: existing engine lifecycle/result/permission types expose pure
  transition, approval, denial, resolved/pending, stop, and model-fallback
  semantics. The async decision service delegates to a pure iteration function;
  app status code retains its persisted codec/localization and maps explicitly.
- Scope decision: persisted workspace group lookup and built-in/native service
  registry assembly remain app-side; only identifier construction and `ToolSpec`
  values are neutral. Repositories, permission loading/persistence, mutable
  runner/queues/resume lifecycle, UI copy, and adapter result mapping are unchanged.
- Discoveries: no strict-match candidate accepted. Concurrent T06/T08/T12/T13
  files and generated files remain untouched.
- Generated code: none. Security impact: permission denial distinctions remain
  exact; no permission source or persistence behavior moved.
- Evidence:
  - `pass` - direct-source engine decision/lifecycle tests: from
    `packages/auravibes_engine`, `fvm dart test test/tool_lifecycle_test.dart
test/agent_tool_decision_service_test.dart` (7 tests).
  - `pass` - focused engine and app static analysis reported no issues.
  - `pass` - engine forbidden-import search returned no matches.
  - `reviewed` - fallback stale search finds canonical engine strings plus
    intentional app execution log/detail text; app status duplication removed.
  - `pass` - `git diff --check`.
  - `blocked by concurrent T12/T13` - barrel-based engine and app focused tests
    cannot compile because concurrent work deleted
    `lib/src/providers/agent_runtime_provider.dart` while remaining runtime
    imports/callers still require it, and cancellation APIs are partially
    migrated. Diagnostics contain no T09 file errors; app execution test also
    retains a concurrent missing `mcpSlug` argument.
- Completion gates:
  - [x] Pure lifecycle transitions, fallbacks, approval, denial, and loop
        decisions have focused engine tests.
  - [x] Persisted status codec, localization, permission distinctions, and app
        effect ownership remain unchanged.
  - [x] Barrel-based focused engine/app suites pass after concurrent runtime
        migration reaches a compilable state.
  - [x] Post-runtime engine rerun passed in `fvm dart test
test/transcript_context_test.dart test/mcp_test.dart
test/tool_lifecycle_test.dart test/agent_tool_decision_service_test.dart`
        (11 tests).

### T07 - Move Skill-Template Validation And Execution Semantics

- Status: `done`
- Depends on: T01 (`done`), T02 (`done`), T05 (`done`)
- Before paths: app `features/skills/usecases/validate_skill_template_tool_usecase.dart`
  owns pure Liquid validation, sample rendering, and canonical serialization;
  engine resolver separately owns runtime rendering and required references.
- Target paths: engine skill execution owns shared canonicalization, references,
  validation, sample rendering, and deterministic runtime resolution; app create
  and update usecases retain repository and credential-definition retrieval.
- Discovery: validation uses only synthetic credential values and existing
  engine skill definition values. No network or credential retrieval belongs in
  the engine move.
- Generated code: none expected.
- Security impact: sample rendering uses fixed synthetic values only; real
  credentials remain app-side and must not be logged.
- After paths: engine `skills/execution/resolve_skill_url_template.dart` owns
  top-level validation and canonical serialization beside deterministic runtime
  resolution. App create/update usecases directly call engine functions while
  retaining repository and credential-definition reads. The zero-state app
  validator/provider and app `liquify` dependency are removed.
- Discoveries: no additional strict-match candidate accepted. App credential
  lookup, persistence, Riverpod composition, and runtime transport fail the
  strict app-neutral/effect-free criteria and remain app-side.
- Evidence:
  - `pass` - engine focused test: from `packages/auravibes_engine`, `fvm dart
test test/skills/resolve_skill_url_template_test.dart` (10 tests).
  - `pass` - app repository/adapter test: from `apps/auravibes_app`, `fvm
flutter test test/data/repositories/skills_repository_impl_test.dart
--no-pub` (22 tests; existing Drift debug warnings only).
  - `pass` - focused engine `dart analyze` and app `flutter analyze --no-pub`
    reported no issues.
  - `pass` - engine forbidden-import, stale validator/provider, duplicate app
    validation-rule, and app `liquify` import searches returned no matches.
  - `pass` - `git diff --check`.
  - `blocked by concurrent T03` - `fvm dart run melos run validate:quick`
    reached analysis but failed on unrelated required `mcpSlug` arguments and
    existing T03 lint findings; no T07 path appeared in the diagnostics.
- Completion gates:
  - [x] Validation classification, exception messages, and canonical JSON are
        covered in engine.
  - [x] Runtime and authoring use the same engine canonical/reference helpers.
  - [x] App retains persistence, credential retrieval, Riverpod, transport,
        localization, and UI ownership.
  - [x] No generated or schema changes; no real credentials used or logged.

### T05 - Move Safe URL Protocol And Content Pipeline

- Status: `done`
- Depends on: T01 (`done`)
- Before paths: engine skill-specific URL request/response values coexist with
  duplicate app Freezed URL values; app owns deterministic transformation and
  mixed DNS/address classification.
- Target paths: engine generic immutable URL values, deterministic content
  transformation, and pure URI/IP/public-host classification; app retains DNS,
  Dio transport, cancellation, credentials, policy enforcement, and lifecycle.
- Discovery: Dio redirects are disabled, but returned redirect destinations are
  not validated. T05 must validate `Location` before exposing a redirect response.
- Generated code: duplicate app Freezed URL files will be removed after all
  callers migrate; no generated engine code expected.
- Security impact: preserve current public-host ranges and HTTPS requirement for
  credential-bearing requests; validate every redirect destination using the
  same policy before returning it.
- After paths: engine `lib/src/skills/models/url_*` exposes canonical generic
  `UrlRequest`/`UrlResponse`; `lib/src/url_content_*` owns deterministic content
  conversion; `lib/src/public_url_classifier.dart` owns pure URI, host-label,
  and IP classification. App `services/url/url_service.dart` retains Dio,
  cancellation, headers, response streaming, DNS, and redirect enforcement.
- Decisions: retained `AppSkillHttpClientAdapter` because it is the mandatory
  pre-transport HTTPS/DNS security adapter for credential-bearing skill calls;
  removed duplicate app URL models, generated files, and transformer after all
  callers migrated. Redirects remain non-followed and unsafe destinations now
  fail before responses escape the transport service.
- Discoveries: Dio default status validation routed 3xx through its exception
  path, bypassing normal redirect checks. App transport now accepts all HTTP
  statuses into one response path, preserving returned error responses while
  validating each redirect `Location`. No additional strict-match task accepted.
- Evidence:
  - `pass` - engine focused tests: `fvm dart test
test/url_content_transformer_test.dart test/url_response_test.dart
test/public_url_classifier_test.dart
test/skills/resolve_skill_url_template_test.dart
test/skills/app_skill_executor_test.dart` (99 tests).
  - `pass` - app focused tests: `fvm flutter test
test/services/url/url_service_test.dart
test/services/tools/native_tools/url_tool_test.dart
test/features/skills/usecases/run_app_skill_tool_usecase_test.dart --no-pub`
    (87 tests).
  - `pass` - focused app analysis reported no issues.
  - `pass` - focused engine analysis reported no issues.
  - `pass` - stale app URL model, transformer, and `AppSkillUrl*` searches
    returned no matches; engine forbidden-import search returned no matches.
  - `pass` - `git diff --check`.
- Compatibility impact: exact canonical transform fixture and existing URL
  suites pass; method/format labels, headers, truncation suffixes, response
  status helpers, and credential HTTPS policy remain unchanged.
- Completion gates:
  - [x] Generic engine URL values replace parallel app and skill-specific APIs.
  - [x] Deterministic transform and pure classification have engine tests.
  - [x] App retains DNS/transport/cancellation/credentials and validates redirects.
  - [x] Focused tests, analysis, boundaries, stale searches, and diff check pass.

### T02 - Canonicalize Tool Names And Skill Slugs

- Status: `done`
- Depends on: T00 (`done`)
- Goal: one engine-owned v1 tool-name codec and exact skill-slug algorithm.
- Before: engine resolver parsed names but only encoded skill names; app owned a
  duplicate parser/type hierarchy, slug function, and built-in/native/MCP/skill
  builders.
- After: `AgentResolvedToolName` is the single v1 parse/encode/classification
  model, retains opaque MCP server slug data, and engine owns
  `generateSkillSlug`; app retains display formatting only.
- Discoveries: app MCP display parsing required preserving the middle MCP slug;
  permission classification and all spec/metadata builders were grammar callers
  and migrated. No additional task met discovery criteria.
- Evidence:
  - `pass` - from `packages/auravibes_engine`, `fvm dart test
test/tool_name_resolver_test.dart test/resolved_tool_service_test.dart` (16
    tests).
  - `pass` - from `apps/auravibes_app`, `fvm flutter test
test/utils/tool_name_formatter_test.dart test/domain/models/mcp_tool_info_test.dart
test/services/mcp_service/mcp_service_test.dart
test/features/skills/usecases/build_app_skill_native_tool_specs_usecase_test.dart
test/features/skills/usecases/sync_skill_tool_permissions_usecase_test.dart
test/features/chats/providers/tool_display_name_provider_test.dart
test/services/agent_harness/agent_tool_call_loader_test.dart --no-pub` (79
    tests).
  - `pass` - engine `fvm dart analyze lib`; app `fvm flutter analyze lib
test/utils/tool_name_formatter_test.dart`.
  - `pass` - repository search found production grammar/slug regex and encoding
    strings only in `packages/auravibes_engine/lib/src/tool_name_resolver.dart`.
  - `pass` - engine forbidden-import search returned no matches.
  - `pass` - `git diff --check`; final worktree reviewed, concurrent/unrelated
    T00/T04 changes untouched.
- Compatibility impact: byte-identical v1 names/slugs; no persisted-history or
  permission-ID rewrite; no shim.
- Generated code: none.
- Security impact: none.

Each `T01`-`T15` task must record before/after paths, focused engine and app test
commands, compatibility evidence, generated files, security impact, discoveries,
and stale-reference searches. Its specific steps and gates are authoritative in
the approved plan file.

`T16` additionally requires:

- [x] Full discovery pass adds no open accepted task.
- [x] All accepted discoveries are `done`.
- [x] Engine forbidden-import search inspected.
- [x] `fvm dart run melos run validate:quick` passes.
- [x] `fvm dart run dependency_validator` passes.
- [x] `fvm dart run import_sorter:main --exit-if-changed` passes.
- [x] Package suites passed directly; `test:ci` cannot run non-interactively.
- [x] `fvm dart run melos run validate` passes.
- [x] Final `git status --short` reviewed.

## Discoveries

- `DISC-001` - Engine URL transformer exposed mutable static tag sets.
  Accepted under strict statelessness rule and completed by converting all three
  sets to `static const`; 55 transformer tests passed.
- `DISC-002` - T14 left zero-state OpenRouter and OpenAI-compatible plugin
  handles in the engine public API. Accepted and completed: codec construction
  now belongs to app composition and engine exports only pure codecs/options.
- `DISC-003` - Five app compatibility re-export paths survived the clean-break
  migration. Accepted and completed: callers import engine APIs directly;
  wrapper-only files and the deprecated `FinishReason` alias were removed.
- `DISC-004` - Final unused-code validation found an SDK-to-MCP tool-definition
  converter, its neutral engine value, and an engine permission-result extension
  used only by their own tests. Accepted and completed by deleting these dead
  APIs and tests; active MCP result normalization and tool lifecycle behavior
  remain covered.

## Compatibility Evidence

- Persisted/wire formats to freeze: tool names, skill slugs, tool-result status
  strings, message metadata JSON, skill-template JSON, model capability JSON,
  URL values/transforms, and cancellation race behavior.

## Final Verification

- Status: `done`.
- `pass` - `fvm dart run melos run validate:quick`; analysis and formatting
  checks completed with no issues or changed files.
- `pass` - `fvm dart run dependency_validator`; every workspace package reported
  no dependency issues.
- `pass` - `fvm dart run import_sorter:main --exit-if-changed`; zero files
  changed (command emitted its existing deprecation warning only).
- `pass` - direct package suites: app 2,834 tests, engine 216 tests, server 5
  tests, and UI 564 tests.
- `not_run` - `fvm dart run melos run test:ci` prompts for package selection and
  fails under non-interactive stdin. Direct package suites above cover the same
  behavioral packages without coverage collection.
- `pass` - final `fvm dart run melos run validate`; analysis, unused files,
  unused code, unnecessary nullable checks, formatting, and Melos package tests
  all completed successfully. App suite reported 2,833 tests in this final run
  after dead test-only API removal.
- `pass` - final focused MCP/lifecycle checks: engine 4 tests and app 42 tests.
- `pass` - engine forbidden-import and stale-API searches; no forbidden package
  dependency or compatibility shim remains.
- `pass` - `git diff --check`.

## Sonar Follow-Up

- SonarCloud PR 647 reports 32 open issues. Thirty-one belong to unrelated
  external plugins or generated platform sources. The one migration-local issue
  is `dart:S3776` in `OpenAICodexCodec.stream` event handling.
- Split the event-specific branches into private accumulator methods without
  changing SSE parsing, emitted chunks, tool accumulation, usage, or errors.
- `pass` - `fvm dart test test/genkit_providers/provider_codecs_test.dart`
  from `packages/auravibes_engine` (5 tests), including streamed text, tool,
  completion, and failure events.
- `pass` - `fvm dart run melos run validate:quick`.
- `pass` - `git diff --check`.
- `reviewed` - final `git status --short`; all listed changes belong to the
  approved migration, task ledger/instructions, or approved plan. No unrelated
  tracked change was reverted.

## PR Feedback

- `PR-647-001` - Post-PR review identified valid regressions in URL error
  wording and app-owned chat-completions URI coverage, plus overbroad engine
  unused-file exclusions. Restored explicit false-positive exclusions, added
  URI regression tests, and made HTTP-capable validation errors accurate.
- Rejected feedback: the MCP schema type claim is disproven by successful full
  validation; the dynamic JSON deep-freeze claim is disproven by the added
  runtime regression test.
- Evidence:
  - `pass` - `fvm dart test test/tool_spec_test.dart
test/public_url_classifier_test.dart` from `packages/auravibes_engine`.
  - `pass` - `fvm flutter test
test/services/chatbot_service/chat_completions_plugin_test.dart --no-pub`
    from `apps/auravibes_app`.
  - `pass` - `fvm dart run melos run validate:quick`.
  - `pass` - `fvm dart run melos run validate`, including explicit
    public-barrel false-positive exclusions for DCL unused-file checks.
  - `pass` - `git diff --check`.
