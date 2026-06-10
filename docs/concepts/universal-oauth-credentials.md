# Universal OAuth Credentials

This document explains the current credentials and OAuth implementation. The
goal is one credential path for MCP servers now, and model providers, skills,
and other integrations later.

## Core Idea

External authentication data lives in `service_connections`.

Consumers should not store tokens on their own tables. A feature stores only a
reference to the service connection, then asks the credential domain layer for a
valid token when it needs to connect.

Current MCP shape:

- `mcp_servers` stores MCP identity and runtime config.
- `mcp_servers.service_connection_id` points at `service_connections.id`.
- `mcp_servers` does not store tokens or authentication payloads.
- MCP reconnect resolves auth through `OAuthCredentialService`.

## Storage Model

`service_connections` is the universal credential table.

Important columns:

| Column | Purpose |
| --- | --- |
| `kind` | Credential owner/use category, such as `modelProvider`, `mcpServer`, or `skillCredential`. |
| `authentication_type` | `none`, `apiKey`, `bearerToken`, or `oauth2`. |
| `encrypted_auth_value` | Encrypted secret JSON. Never read this directly from UI or feature code. |
| `metadata_json` | Public/non-secret metadata JSON. Safe to decode for display. |
| `auth_status` | OAuth lifecycle state, such as connected or needs reauth. |
| `expires_at` | Access-token expiry time when known. |
| `last_refreshed_at` | Last successful token refresh/update time. |
| `last_auth_error` | Last auth failure summary for UI/debugging. |
| `key_suffix` | Last characters of the current secret/token for safe display. |

Secret payloads are represented by
`ServiceConnectionSecret` in
`apps/auravibes_app/lib/domain/entities/service_connection_auth.dart`.

Current secret variants:

- `ServiceConnectionSecretApiKey`
- `ServiceConnectionSecretBearerToken`
- `ServiceConnectionSecretOAuth2`

OAuth secret JSON may contain:

- `access_token`
- `refresh_token`
- `id_token`
- `client_secret`

Metadata is represented by `ServiceConnectionMetadata` and may contain:

- `client_id`
- `issuer`
- `authorization_endpoint`
- `token_endpoint`
- `scopes`
- `account_id`
- `tenant_id`
- `provider`
- `flags`

## Boundaries

Use these layers instead of reading Drift rows or encrypted JSON directly.

### ServiceConnectionRepository

Path:
`apps/auravibes_app/lib/domain/repositories/service_connection_repository.dart`

Responsibilities:

- Return domain `ServiceConnectionEntity` records.
- Read decrypted secret payloads by credential id.
- Create MCP service connections.
- Persist OAuth token updates.
- Mark a credential as reauth-required.
- Delete MCP-owned credentials during failed MCP setup cleanup.

The implementation owns Drift and encryption:

`apps/auravibes_app/lib/data/repositories/service_connection_repository_impl.dart`

Feature/domain services should not depend on `ServiceConnectionTable`.

### OAuthCredentialService

Path:
`apps/auravibes_app/lib/services/oauth_credential_service.dart`

Responsibilities:

- `getValidAccessToken(connectionId)`
- `refreshIfNeeded(connectionId)`
- `forceRefresh(connectionId)`
- `persistOAuthTokenUpdate(connectionId, token)`
- `markReauthRequired(connectionId)`
- `resolveMcpAuthentication(serviceConnectionId)`

Refresh behavior:

- Refresh starts when `expires_at` is missing or within 5 minutes.
- Concurrent refreshes for the same credential share one in-flight future.
- Rotated refresh tokens are persisted.
- If a refresh response omits `refresh_token`, the previous refresh token is
  preserved.
- `invalid_grant` marks the credential as `needsReauth`.
- Missing refresh token or token endpoint marks the credential as
  `needsReauth`.

## MCP Flow

MCP server add flow lives in:

`apps/auravibes_app/lib/notifiers/mcp_connection_status.dart`

Current flow:

1. Build the MCP server config from form input.
2. Create a matching `service_connections` row when auth is bearer/OAuth.
3. Connect to the MCP server and discover tools.
4. Persist the MCP server with `service_connection_id`.
5. Persist discovered tools.
6. Subscribe to MCP token updates.
7. Token updates call `OAuthCredentialService.persistOAuthTokenUpdate`.

Failure behavior:

- If connection, discovery, or persistence fails after credential creation, the
  MCP-owned credential is deleted.
- If a client was opened, it is disconnected on failed paths.

Reconnect flow:

1. Load the persisted MCP server.
2. Read `service_connection_id`.
3. Call `OAuthCredentialService.resolveMcpAuthentication`.
4. Connect with the resolved transient auth config.

MCP runtime callers should not parse `metadata_json` or decrypt secrets.

## Connections UI

Connections rows are built by:

`apps/auravibes_app/lib/features/service_connections/usecases/watch_service_connection_list_items_usecase.dart`

It combines:

- model provider connections
- skill credentials
- MCP servers joined to their `service_connections` rows

The UI displays only safe metadata. It must not read or render secret JSON.

MCP row actions are routed through:

`apps/auravibes_app/lib/features/service_connections/controllers/service_connections_controller.dart`

Actions:

- Reconnect MCP server.
- Force refresh OAuth token, then reconnect the MCP server.

Malformed metadata is treated as empty metadata so the Connections stream stays
alive.

## How Other Tools Should Use OAuth

Any feature that needs OAuth should follow this pattern.

### 1. Store a Service Connection

Create or select a `service_connections` row for the integration.

Store:

- secrets in `encrypted_auth_value` through `ServiceConnectionRepository`
- public metadata in `metadata_json`
- only the credential id on the feature-specific table

Do not store access tokens or refresh tokens on feature tables.

### 2. Keep a Reference

Add a nullable `service_connection_id` column to the feature table.

Examples:

- MCP: `mcp_servers.service_connection_id`
- Future model provider OAuth: model connection row references a service
  connection or becomes backed by one.
- Future skill OAuth: skill credential row references a service connection.

### 3. Resolve Credentials at Runtime

Runtime code should call one of:

```dart
final token = await ref
    .read(oauthCredentialServiceProvider)
    .getValidAccessToken(serviceConnectionId);
```

or, for MCP:

```dart
final auth = await ref
    .read(oauthCredentialServiceProvider)
    .resolveMcpAuthentication(serviceConnectionId);
```

The caller receives a valid access token or transient auth object. It does not
receive the full decrypted secret payload unless it is part of the credential
domain layer.

### 4. Persist Token Updates Through the OAuth Service

If a tool receives a refreshed OAuth token from a provider-specific client, it
must call:

```dart
await ref.read(oauthCredentialServiceProvider).persistOAuthTokenUpdate(
  serviceConnectionId: serviceConnectionId,
  token: token,
);
```

This preserves refresh tokens when providers omit them and updates expiry,
status, suffix, and refresh timestamp consistently.

### 5. Mark Reauth Instead of Deleting

When OAuth is no longer recoverable, call:

```dart
await ref.read(oauthCredentialServiceProvider).markReauthRequired(
  serviceConnectionId,
  error: 'Short diagnostic message.',
);
```

Use this for invalid grants, missing refresh config, revoked access, or provider
responses requiring user interaction.

## Extension Points

### Provider Profiles

Future integrations should define typed provider profiles before creating
credentials.

A profile should describe:

- provider id
- display label
- auth type
- authorization endpoint
- token endpoint
- scopes
- redirect behavior
- refresh behavior
- any provider flags

MCP currently derives this from discovered/entered MCP auth data and maps it to
`ServiceConnectionMetadata`.

### Authorization Start and Completion

The current implemented service focuses on refresh and runtime token access.

Future OAuth connect flows should add use cases around the same storage model:

- start authorization with PKCE
- complete authorization
- create/update a `service_connections` row
- persist the received token through the repository

Those use cases should reuse `ServiceConnectionSecretOAuth2`,
`ServiceConnectionMetadata`, and `OAuthCredentialService` refresh behavior.

## Security Rules

- Never log access tokens, refresh tokens, id tokens, API keys, bearer tokens,
  or client secrets.
- Never pass raw secret JSON to widgets, prompts, tool specs, or logs.
- Keep encryption/decryption inside repository/service boundaries.
- UI may decode only `metadata_json`.
- Treat `ServiceConnectionSecret.toString()` as redacted and keep it that way.
- Store only safe display values such as `key_suffix`, provider labels, scopes,
  issuer, and token timestamps.

## Testing Expectations

When adding another OAuth consumer, cover:

- credential creation stores encrypted secret JSON
- runtime code calls `OAuthCredentialService`, not Drift/encryption directly
- refresh updates access token and expiry
- rotated refresh token is persisted
- omitted refresh token preserves the previous refresh token
- concurrent refreshes make one token endpoint request
- `invalid_grant` marks `needsReauth`
- UI never displays or stringifies secret payloads
- deleting an integration does not delete a shared credential unless ownership
  is explicit
