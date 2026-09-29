# Task 2 implementation report

Status: DONE_WITH_CONCERNS. Base Task 2 commit: `391b3d7bdbc5c09ecda6d8d4d37db514abbfe988`.

## Delivered

- Workspace catalog search, transport/auth filters, required fields, secret obscuring, verify/install, and immutable listing/option snapshots work for local and cloud workspaces. Manual MCP creation remains available. User-facing copy is localized in EN/ES.
- Header contract: an `apiKey` option's single secret field key is the literal HTTP header name; `httpHeaders` field keys are literal header names; bearer values use `Authorization: Bearer`. Invalid/reserved names, case-insensitive duplicates, and CR/LF values are rejected at catalog and local form boundaries. OAuth catalog options only accept the supported non-secret `clientId` field; required unsupported fields fail source and local validation.
- Active workspace credentials use existing encrypted storage. Submitted values do not enter catalog definitions, copied snapshots, logs, or `toString`. Cloud verification receipts bind the full OAuth JSON digest, preventing refresh-token or endpoint changes between verify and create. A successful idempotent create replay checks its receipt before live catalog lookup, so catalog edit/deletion does not break replay.
- Cloud legacy HTTP+SSE uses the existing DNS-validated, pinned HTTP client with HTTPS certificate validation/SNI. Handshake, same-origin message endpoint, pagination, tool calls, no redirects, response/event size limits, idle timeouts, and total operation deadlines are implemented. The app routes cloud SSE through the gateway. Legacy SSE remains for repository compatibility although the current MCP specification deprecates it.
- Cloud OAuth reuses the app's OAuth acquisition flow. Verify/create pass access token plus full token/refresh metadata; only encrypted workspace secret stores the payload. Discovery and tool execution resolve the selected secret, refresh expired or missing-expiry tokens under a row lock, persist rotated ciphertext and revision, or mark `reauthRequired` on failure. Refresh requests validate public HTTPS DNS answers and use the pinned TLS client.
- Expanded Task 2 scope to server request models, Serverpod-generated client/protocol, use cases, SSE/probe/runtime, OAuth resolver, and app gateway/notifier. This was required to make advertised cloud catalog options functional without bypassing network policy.

## TDD and focused verification

- RED cases recorded during implementation: missing catalog parser/form contracts, missing pinned client, unsupported SSE/OAuth server paths, missing OAuth parser/session classes, and catalog replay after deletion. Each was followed by a focused GREEN check.
- GREEN: `fvm dart test test/features/mcp_catalog/mcp_catalog_use_cases_test.dart test/features/mcp_servers/mcp_oauth_credentials_test.dart test/features/mcp_servers/mcp_sse_session_test.dart test/features/mcp_servers/mcp_server_probe_test.dart test/integration/features/mcp_servers/mcp_server_verification_test.dart` from server package: 21 tests, 11.2s. Offline SSE fixtures cover handshake, pagination, call, cross-origin endpoint, GET/POST redirects, and event bound. OAuth integration covers receipt tampering, ciphertext, missing-expiry refresh, rotation, unexpired reuse, failure, and no-refresh reauth.
- GREEN: `fvm flutter test test/features/service_connections/models/mcp_catalog_installation_test.dart test/features/service_connections/widgets/mcp_catalog_browser_test.dart --no-pub` from app package: 7 tests, 9.0s. Cloud SSE/OAuth choice is enabled.
- GREEN: focused app fatal analyzer (`cloud_tools_repository.dart`, `cloud_mcp_gateway.dart`, `mcp_connection_status.dart`, `workspace_capabilities.dart`): no issues. Focused server fatal analyzer (`mcp_servers`, `mcp_catalog`, server tool executor, and changed tests): no issues, 5.0s.
- Generation: app `fvm dart run build_runner build --delete-conflicting-outputs`; server `serverpod generate` after both request-model changes. Generated diff reviewed. No new dependency. No native screenshot; catalog UI checked by widget test.

## Remaining limits

- Cloud credential ownership remains workspace scoped, matching Task 2's workspace isolation. Issue #87 also says per-user API key; parent is clarifying that product decision. This change does not alter credential scope.
- No full repository suite, live external OAuth provider, or live external SSE server run. Focused offline tests validate protocol and security boundaries. `authStatus` is persisted on the resource after refresh failure; a workspace sync event is not emitted by this resolver, so clients may need a refetch to see that status immediately.
