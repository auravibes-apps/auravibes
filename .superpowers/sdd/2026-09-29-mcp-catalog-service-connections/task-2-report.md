# Task 2 implementation report

Status: DONE_WITH_CONCERNS. Base: `6606bd211929a1985226d1fc9603a2d89d11a5ea` (Task 1).

## Delivered

- Added authenticated catalog browsing on the service connections screen with name/description search, transport and auth filters, selected-option fields, required/optional labels, obscured secret inputs, verification, installation, and EN/ES messages. Manual MCP creation remains available.
- Local installs copy listing and option definitions into `mcp_servers.catalog_snapshot_json` and store submitted HTTP headers in the existing encrypted workspace service connection. Cloud installs send listing/option IDs for server-side snapshot creation and store submitted headers in encrypted `WorkspaceSecret` scoped to the active workspace. Submitted values are absent from both catalog and snapshot metadata.
- Mapped `apiKey` field `key` to its literal HTTP header name, `httpHeaders` field keys to their literal HTTP header names, and bearer values to `Authorization: Bearer`. API-key fields must be secret and singular. Header names, reserved request-control headers, duplicate names, and CR/LF values are rejected at the app/server boundary.
- Cloud verification/discovery/tool execution use configured headers while retaining DNS validation, address pinning, origin/proxy checks, redirect blocking, and HTTPS certificate validation. The prior custom `HttpClient.connectionFactory` returned a raw TCP socket on HTTPS; the shared pinned client now wraps it with `SecureSocket.secure(host: requestedHost)`.
- Expanded Task 2 file scope to server MCP request models, use cases, probe, server tool executor, pinned HTTP client, Serverpod-generated protocol, local Drift schema/migration, encrypted credential resolver, and focused tests. This is required for cloud header support and workspace snapshot persistence.

## TDD and focused verification

- RED: app catalog model test failed on missing `mcp_catalog_installation.dart`; server header test failed on missing parser; pinned client test failed on missing implementation. Repository test first compile failed because Drift `copyWith` requires `Value<String?>`, then passed after correction.
- GREEN: app catalog model test (3), browser widget test (2, including visible disabled cloud option), local MCP repository test (18), local service connection repository test (6), existing AddMcpModal/notifier/cloud notifier/service screen bundle (90).
- GREEN: server pinned client/header/probe/verification integration tests (14), including encrypted cloud header and copied snapshot persistence after catalog deletion. Server integration initially failed because the test harness lacked `workspaceSecretKey`; the test fixture now uses the documented 32-byte example key.
- GREEN: app `fvm dart analyze lib --fatal-infos --fatal-warnings`; server `fvm dart analyze lib/src/features --fatal-infos --fatal-warnings`; `git diff --check`.
- Generation: app `fvm dart run build_runner build --delete-conflicting-outputs` and localization generator; server `serverpod generate`. Generated Freezed, Riverpod, Drift, localization, and Serverpod output reviewed for the new fields. The first `fvm dart run serverpod generate` call could not resolve the CLI from package dependencies; the installed `serverpod generate` command succeeded.
- No native screenshot was captured; browser behavior was verified with a focused widget test.

## Remaining acceptance gap

- Cloud SSE and OAuth catalog options are visible with a localized unavailable state. Existing cloud MCP verifier/runtime only supports streamable HTTP and has no OAuth token refresh lifecycle. The app's existing OAuth flow can obtain a token, but cloud persistence currently supports only a bearer access token without refresh handling. Cloud SSE would require a pinned SSE handshake and message/runtime path that preserves DNS pinning, same-origin URL policy, redirect blocking, limits, and TLS checks. The pinned `mcp_client` SSE transport creates its own `HttpClient`, so using it directly would bypass the cloud policy. These modes are not marked supported and are not installed by this commit.
- Local and cloud snapshot independence after installation is covered by model/repository/integration tests; catalog edit/removal between verification and cloud commit still makes the server reject the install because it snapshots the live entry at creation time.

## Follow-up

Implement cloud SSE transport and OAuth token refresh with deterministic offline security tests, then enable the currently disabled options and complete #87/#1232 acceptance.
