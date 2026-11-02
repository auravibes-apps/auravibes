# Provider adapter fault injection contract implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task by task. The issue implementer works in this worktree; the parent coordinates independent plan and code reviews. Do not dispatch nested agents.

**Goal:** Run deterministic offline failure scenarios through every supported provider runtime and selected plugin path, its production codec, and its production retry and cancellation adapter.

**Architecture:** Package-local scripted fixtures supply controlled byte streams and record each request. Engine tests run the protocol contract through the real Chat Completions and Codex codecs. One reusable app `http.BaseClient` fixture runs the same runtime contract through every actual Genkit plugin, because transport retry and cancellation live in the app. Per-runtime expectations describe existing retry differences rather than implementing retries inside the fake.

**Tech stack:** Dart 3.13, Flutter 3.47.9 through FVM, `test`, `flutter_test`, Genkit 1.0, `http` 1.6, and the pinned Anthropic SDK 8.0. No live credentials or provider calls.

**Spec:** [Issue #1431](https://github.com/auravibes-apps/auravibes/issues/1431). Related closed work: #1385 and #1405. Baseline `f00fc7b9159cc35713db498ad319200a5ed4052e`.

## Global constraints

- Cover mid-stream disconnects, partial and delayed chunks, timeouts, authentication failures, rate limits with `Retry-After`, server errors, and cancellation.
- Assert adapter-specific retry rules, preservation of partial output where supported, stable request/tool-call identity, and absence of duplicate side effects.
- Every supported adapter must participate or have a documented, tested exception.
- Keep engine fixtures pure Dart. Do not move app credential, HTTP, localization, or persistence ownership into the engine.
- Reuse the installed pinned SDK and already resolved dependencies. Do not run bootstrap, dependency resolution, SDK installation, or downloads. If SDK resolution or the validation lease blocks a check, report the exact failure and continue independent work without bypassing it.
- Keep existing redaction guarantees. Never retain raw SDK errors, response bodies, or headers in an error cause to recover classification metadata.
- Use completers and explicit event gates for scheduling. Do not use real sleeps, live HTTP, environment credentials, or probabilistic timing assertions.
- Use the existing `retryWait` hook for Chat Completions. Inject typed timeout failures for common scenarios; separately pin actual timeout enforcement with a zero deadline and a never-completing fake request, with teardown releasing it.
- This is a test contract task. Production changes are limited to failures proved by the new acceptance tests, especially cancellation that leaves a quiet stream open. Do not normalize all adapters' retry policies.

## Review focus

- UTF-8 code points and SSE lines split across transport chunks must decode once without losing text.
- A failure after an emitted text or tool chunk must not replay the request or duplicate a tool effect.
- Cancellation while the source is idle must close the source subscription without requiring a later provider event.
- Cancellation while a retry wait is blocked must prevent another attempt, including when that wait later completes.
- Missing, malformed, negative, and excessively large `Retry-After` values must preserve each adapter's documented policy.

## Supported adapters and deliberate differences

Use a registry keyed by `(ProviderRuntime, ProviderPluginPath)`, where `ProviderPluginPath` is a test-local enum with `upstreamOpenAi`, `appChatCompletions`, `appCodex`, and `appAnthropic`. Assert its keys exactly match the six selected paths below, and separately assert its runtime set equals `ProviderRuntime.values`. `ProviderFactory._openAIPlugin` selects upstream `genkit_openai.openAI` when there is no strict sampling profile and no explicit tool-sampling policy. Its alternate path uses the app plugin. Tests must exercise both; one OpenAI runtime case is insufficient. OpenRouter and OpenAI reasoning use `AppChatCompletionsPlugin` with their actual codec configuration. Codex OAuth uses `AppOpenAICodexPlugin`. Anthropic uses `AppAnthropicPlugin` and its actual SDK and encoder.

| Runtime and selected plugin path | Retry before streamed output | Failure after output | Rate limit contract |
| --- | --- | --- | --- |
| `(openAi, upstreamOpenAi)` | None; OpenAI SDK 8.1 streaming bypasses interceptor retry wrapper | No retry; emitted chunks survive; SDK accumulates final tool requests | Plugin wraps stream failures in a generic `GenkitException`; SDK status remains in the nested SDK cause but current engine recovery cannot interpret it; streaming `Retry-After` is lost, so no inferred delay |
| `(openAi, appChatCompletions)`, `(openRouter, appChatCompletions)`, `(openAiReasoning, appChatCompletions)` | One retry for HTTP 500/502/503/504, `http.ClientException`, or `TimeoutException`; none for 401/403 | No retry; preserve already delivered chunks | 429 does not retry inside plugin; explicit header becomes `AgentRateLimitRetryException`; engine loop owns the delay, capped at 60 seconds |
| `(codexOAuth, appCodex)` | One retry for structured internal `server_error`; no retry for plain 500, 502, transport failure, or timeout | No retry; preserve delivered chunks | No internal 429 retry; recovery retains parsed header, capped at 60 seconds; no implicit engine rate-limit retry exception |
| `(anthropic, appAnthropic)` | Streaming SDK bypasses ordinary request retry wrapper, so one attempt for all injected stream failures | No retry; delivered text chunks survive; completed tool requests only appear in the final response | SDK streaming exception discards response headers and app converts API errors to redacted `AnthropicRequestException('provider_failure')`; no delay or inferred retry |

| Selected plugin path | Actual timeout enforcement | Cancellation before headers / on an idle stream |
| --- | --- | --- |
| `upstreamOpenAi` | SDK streaming path bypasses configured request timeouts. Plugin exposes no request timeout parameter. Injected `TimeoutException` still exercises propagation; do not claim actual deadline enforcement. | Plugin calls `createStream(request)` without `abortTrigger`; request has no cancellation signal. Genkit can prevent later tool execution after cancellation, but cannot close an idle transport by itself. Required regression first. |
| `appChatCompletions` | Configured header timeout, stream inactivity timeout, and overall stopwatch deadline | Request carries `http.Abortable` trigger; source must cancel promptly and injected shared client must remain open. |
| `appCodex` | Configured header timeout and stream inactivity timeout; no overall stopwatch deadline | Request carries `http.Abortable` trigger; source must cancel promptly and injected shared client must remain open. |
| `appAnthropic` | Streaming SDK bypasses ordinary timeout wrapper; injected timeout remains in shared scenarios | SDK creates a regular `http.Request` and checks cancellation only on later SSE events. Required regression first. |

Anthropic's and upstream OpenAI's streaming HTTP classification, `Retry-After`, and actual timeout limitations are documented tested exceptions. Assert real failures and concrete cause types rather than skipping scenarios. Upstream OpenAI's non-stream path maps SDK API status into Genkit status, so also assert non-stream authentication is non-retryable. Both SDKs have different non-stream retry wrappers; do not claim the shared stream contract covers those wrappers or change their policies.

Cancellation is not yet an approved exception for either upstream path. An app-owned fix appears feasible: run each resolved upstream OpenAI model action inside a request-scoped `http.runWithClient` zone that returns a cancellation-aware client, and pass an equivalent client bridge to the app-owned Anthropic wrapper. The bridge can attach the per-generation token to the HTTP request and cancel the response subscription without altering encoding, parsing, or retry policy. The default OpenAI factory currently gives the upstream plugin no client and therefore lets its SDK create an owned `http.Client` inside the generation zone. A wrapper at that boundary must retain model namespace, metadata, custom options, and error behavior, and close only the client the generation owns. Add tests for those preservation and ownership rules before adopting it. Do not claim an upstream exception is unavoidable while this app-owned route remains viable.

If acceptance tests show this approach cannot preserve upstream behavior, stop that production change and report the precise API limitation, failed regression, alternative considered, and why the app-owned bridge cannot satisfy cancellation. Parent review must decide any issue-scope gap; do not silently accept an unabortable default path.

The shared contract calls Genkit with `returnToolRequests: true` when inspecting tool identity. Separate acceptance cases allow Genkit to execute one registered counting tool, then assert zero effects on incomplete/failing/cancelled calls and exactly one on successful recovery. The fake records transport and tool effects separately so a fabricated fixture result cannot satisfy those assertions.

## File map

- Create `packages/auravibes_engine/test/support/provider_fault_fixture.dart`: pure Dart scripted response/body controls and request snapshots, independent of Flutter and `http`.
- Create `packages/auravibes_engine/test/genkit_providers/provider_fault_contract_test.dart`: shared codec scenarios for the supported codec configurations, classification, and transcript/tool identity.
- Create `apps/auravibes_app/test/features/chats/services/chatbot/support/provider_fault_client.dart`: reusable scripted `http.BaseClient`, app-local response/body controls, request snapshots, and abort observation. All six selected adapter paths share this fixture. Keep its small stream-control implementation local rather than importing another package's `test/` tree.
- Create `apps/auravibes_app/test/features/chats/services/chatbot/support/provider_adapter_case.dart`: production plugin registry and adapter-specific expectations, separate from the transport fake.
- Create `apps/auravibes_app/test/features/chats/services/chatbot/provider_adapter_fault_contract_test.dart`: shared matrix over all `ProviderRuntime` values, real retry counts, cancellation, and side effects.
- Create `apps/auravibes_app/test/features/chats/services/chatbot/support/provider_fault_protocol.dart`: provider wire event builders for Chat Completions, Codex Responses, and Anthropic Messages. Keep protocol syntax out of scenario assertions.
- Modify `packages/auravibes_engine/test/agent_service_test.dart`: focused rate-limit loop test using the already injectable `now` and `sleep`, only if existing tests do not assert the exact elapsed delay and no tool effects.
- Potentially modify `apps/auravibes_app/lib/features/chats/services/chatbot/app_anthropic_plugin.dart`: cancellation subscription cleanup, only after the idle-stream test proves failure. Keep helpers local and preserve error redaction.
- Potentially create `apps/auravibes_app/lib/features/chats/services/chatbot/cancellable_provider_client.dart`: request-scoped cancellation bridge shared by app-owned upstream wrappers, only after regressions prove the need.
- Potentially create `apps/auravibes_app/lib/features/chats/services/chatbot/app_open_ai_plugin.dart` and modify `provider_factory.dart`: wrap the actual upstream default OpenAI model action with request-scoped transport cancellation while retaining its codec, namespace, options, metadata, and retry policy. Add adjacent focused wrapper/factory regression tests if implemented.
- Potentially modify `apps/auravibes_app/test/features/chats/services/chatbot/app_anthropic_plugin_test.dart`: regression assertions adjacent to a proved production fix.

Fixture ownership follows `.agents/skills/package-architecture/SKILL.md`: app imports supported engine APIs through `package:auravibes_engine/auravibes_engine.dart`, and engine never imports app code. A relative import into a sibling package's `test/` directory would couple test internals to repository layout, expose no supported package API, and be fragile under package-only execution. Therefore each package owns its small test transport helper; the app fixture itself is reused across every runtime and every adapter scenario. Keep relative imports within the same package and follow existing analyzer/import conventions. Do not add lint suppressions, public test APIs, a helper package, or new dependencies to share these few controller operations.

## Task 1: Scripted fixture and shared codec contract

**Interfaces:** `ProviderFaultFixture` owns an ordered script and immutable request snapshots. `Future<ProviderTransportResponse> send(Map<String, dynamic> body)` consumes exactly one scripted attempt and fails on an unexpected extra attempt. `ProviderFaultBody` exposes `Stream<List<int>> stream`, `add(List<int>)`, `fail(Object)`, `Future<void> close()`, and `Future<void> cancelled`. `Future<void> dispose()` closes all controllers. No helper decides retry eligibility or suppresses output according to the expected answer.

- [ ] Add a fixture self-check that an unexpected request fails, request snapshots are immutable, and cancellation completes exactly once. All tests register teardown before starting a stream.
- [ ] Add `partial and delayed bytes decode once` for OpenAI, OpenRouter, OpenAI reasoning codec configurations, and Codex. Release a first fragment, wait for observed delivery, then release the rest. Include a split UTF-8 character, split `data:` prefix, multiple events per byte chunk, and final text `Hello 🌍` exactly once.
- [ ] Add `disconnect and timeout preserve delivered output without replay`: emit `partial`, inject a typed transport failure or timeout, assert observed text remains `partial`, failure is observable, and the codec made exactly one request. Attach error listeners before injection.
- [ ] Add parameterized `HTTP failure metadata` for 401, 403, 429 with and without a 12-second delay, 500, 502, 503, and 504. Assert `ProviderFailureRecovery` fields, including auth non-retryability and exact delay. Assert Codex's structured versus unstructured server-error predicate separately.
- [ ] Add `tool identity survives fragmentation and transcript reserialization`: use `call-contract-1` and a complete JSON input split across protocol events; assert one final tool request, stable ref/name/input, and the next built request retains the tool response ref. For Codex include repeated completion snapshots to prove they do not duplicate the final tool request.
- [ ] Run the new engine contract and existing codec tests. Fix fixture/protocol expectations, then commit the reusable fixture and passing contract.

## Task 2: All-runtime adapter matrix and deterministic retry assertions

**Interfaces:** `ProviderFaultClient extends http.BaseClient` owns an ordered script producing `http.StreamedResponse`, captures immutable URI/headers/body snapshots, records abort signals and source cancellations, and throws on all unscripted sends. Its app-local `ProviderFaultBody` exposes the same small stream-control operations needed by the app scenarios, without importing the engine test implementation. `ProviderAdapterCase` carries `ProviderRuntime runtime`, production `GenkitPlugin createPlugin(ProviderFaultClient client, Future<void> Function(Duration) retryWait)`, `String modelName`, wire builders, and explicit retry/classification expectations. `ProviderFaultProtocol` supplies success, text fragments, tool fragments, terminal events, and error bodies without owning assertions.

- [ ] Build all six cases with fixed fixture credentials and `.invalid` URLs. Assert registry coverage against the exact `(ProviderRuntime, ProviderPluginPath)` set and actual request paths and namespace. For upstream default OpenAI use the actual `genkit_openai.openAI` path, injecting the fake through `http.runWithClient` to match factory behavior, and never substitute `AppChatCompletionsPlugin`. Never call `ProviderFactory` with a live credential repository.
- [ ] Run shared `partial/delayed stream succeeds`, `mid-stream disconnect`, `timeout before headers`, `timeout after first chunk`, `authentication fails once`, `server errors obey retry policy`, and `successful retry preserves request identity` tests. Compare immutable body/method/URI snapshots between attempts, including tool refs in history and stable session affinity headers when configured.
- [ ] For Chat Completions server retry, assert one recorded wait of 12 seconds, no second send until an explicit release, and exactly two sends after release. Assert delay cap 60 seconds, invalid header fallback zero, and no third attempt after two failures. For Codex distinguish structured HTTP 500 from plain 500 and 502, and assert no real delay.
- [ ] For HTTP 429, assert no plugin retry and exact recovery metadata for Chat Completions and Codex, plus their different exception types. Test absent, malformed, negative, and `120` headers. Anthropic and upstream OpenAI must consume the same wire failures and assert their documented exception/cause chains and unknown recovery instead of silently skipping. Distinguish each adapter's terminal propagation from automatic retry safety.
- [ ] Inspect existing `AgentService` tests. Add one integrated delay assertion if absent: inject the adapter's real `AgentRateLimitRetryException`, advance a fixed clock in `sleep`, assert summed sleep equals 12 seconds, the second model call occurs only afterwards, original acknowledgement identity is stable, and no tool runs before recovery. Also assert the 60-second cap and cancellation of a pending retry.
- [ ] Add one real deadline test with an unresolved fake send and a zero configured deadline for each local timeout-enabled adapter family. Assert final timeout and exact attempt limit. Treat Anthropic's and upstream OpenAI's SDK streaming timeout implementation as explicit actual-deadline exceptions, but still run the injected timeout scenario for both.
- [ ] Run the new app contract and existing plugin suites. Commit the matrix and recorded exceptions.

## Task 3: Cancellation, tool effects, and review gates

**Interfaces:** Use `CancellationController` from Genkit. Fake transport emulates HTTP abort only when the production request implements `http.Abortable` and supplies an abort trigger. A non-abortable request must not magically close in the fake. Observe stream subscription cancellation separately from abort signaling and client ownership.

- [ ] Add shared `cancellation before headers aborts request`, `cancellation after first text closes idle source`, and `cancellation ignores later text and tools`. Cancel after a delivery acknowledgement, await generation and source cancellation, then attempt to release queued late text/tool events. Assert preserved prefix, aborted generation, no later chunk, no extra request, and zero registered-tool effects.
- [ ] Add `cancellation during retry wait prevents resend` for Chat Completions with the blocked `retryWait` gate, then release the gate and assert request count remains one. Codex has no wait hook; test cancellation before its permitted retry can start using an error/body gate and the cancellation token.
- [ ] Add a successful transient recovery that produces `call-contract-1` and allows one registered tool execution. Assert exactly one effect and no duplicated response/ref across retries. Add a failure after a completed-looking tool chunk, and assert no execution before a successful final model result.
- [ ] Run failing cancellation tests first. If Anthropic leaves the quiet source open, add a local cancellation-aware transport bridge or subscription cleanup in `app_anthropic_plugin.dart` that makes header waits and response consumption abortable, unregisters listeners in `finally`, and does not close an injected shared client. Retain SDK encoding/parsing and redacted exceptions. Do not loosen the fake to make the test pass.
- [ ] Run the same failing cancellation tests on actual upstream default OpenAI. Evaluate the request-scoped app wrapper described above, including retained codec/options/metadata/namespace and exactly-once owned-client closure. If a safe bridge is impossible, send the concrete tested issue-scope gap to the parent for review before proceeding with an exception.
- [ ] Rerun focused contract and affected existing suites, then run changed-file format/analysis once. Inspect the diff and documented exceptions before reporting to the parent reviewer. Apply all findings and repeat relevant checks.
- [ ] After the parent confirms review is clean, create one Conventional Commit PR with `Closes #1431`, the adapter matrix, exception reasons, and exact verification results. Parent owns CI monitoring and merge.

## Verification commands

Use the installed pinned FVM SDK and already resolved dependencies. The user confirmed workspace bootstrap passed. No bootstrap or SDK/dependency setup is part of this plan. If the isolated worktree cannot resolve the existing SDK/dependencies or the lease prevents a command, preserve and report the concrete failure; do not install, download, resolve dependencies, or bypass the lease. Continue code inspection, implementation, and other independent work while that constraint is reported.

From `packages/auravibes_engine`:

```bash
python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" --label engine-provider-contract -- fvm dart test test/genkit_providers/provider_fault_contract_test.dart test/genkit_providers/provider_codecs_test.dart test/provider_failure_recovery_test.dart test/agent_service_test.dart
```

From `apps/auravibes_app`:

```bash
python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" --label adapter-provider-contract -- fvm flutter test test/features/chats/services/chatbot/provider_adapter_fault_contract_test.dart test/features/chats/services/chatbot/app_open_ai_plugin_test.dart test/features/chats/services/chatbot/cancellable_provider_client_test.dart test/features/chats/services/chatbot/provider_factory_test.dart test/features/chats/services/chatbot/chat_completions_plugin_test.dart test/features/chats/services/chatbot/app_open_ai_codex_plugin_test.dart test/features/chats/services/chatbot/app_anthropic_plugin_test.dart --no-pub
```

From the root after edits settle:

```bash
python3 tool/validation_lease.py --label changed-1431 -- fvm dart run melos run validate:changed
git diff --check
git status --short
```

Expected results are zero failed tests, no changed-file format/analyzer diagnostics, and no whitespace errors. Report any baseline or environment failures with the command and output; do not substitute host Dart for FVM. Required GitHub CI gates must pass before the parent merges.

## Plan self-review at approval

All issue scenarios map to Tasks 1 through 3, all six selected plugin paths appear in the registry, and all five review-focus cases have explicit tests. The test fixture contains no retry or application side-effect policy. Anthropic and default OpenAI metadata/timeout limitations are documented with required assertions; stream cancellation is required unless parent review approves a concrete tested gap after the app-owned bridge has been evaluated. No implementation file has changed and no PR has been created. A baseline test invocation was blocked before child execution by the validation lease: worktree free space 17.5 GiB and `/tmp` free space 3.0 GiB are below the required 20.0 GiB reserve. No lease bypass, SDK download, bootstrap, or dependency resolution has run.

## Execution record

- The engine fixture and codec contract, six-case app adapter matrix, factory route regression, counting-tool checks, exact engine loop delay/identity test, and cancellation regressions are written.
- Source inspection confirmed that upstream OpenAI omits `abortTrigger` and Anthropic's streaming SDK uses a regular request and waits for another SSE event before observing cancellation. After the validation lease blocked executable checks, the parent explicitly authorized fixes established by source inspection without claiming local RED/GREEN results.
- Added `CancellableProviderClient` and `AppOpenAIPlugin`, wired only the default upstream OpenAI factory route through that wrapper, and supplied the same client bridge to the app-owned Anthropic plugin. The upstream codec/options/retry implementation remains delegated. Tests compare metadata, namespace, custom-option schema, encoded requests, error types, and owned/injected client cleanup.
- The upstream streaming error metadata and timeout exceptions remain explicit contract assertions and documented SDK limitations. No cancellation exception is accepted.
- Tests and formatter/analyzer commands must still execute in hosted CI because local validation is blocked before launching Dart. No bootstrap, dependency resolution, SDK installation/download, or lease bypass was performed.
