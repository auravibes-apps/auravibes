# MCP Catalog and Service Connections Design

**Date:** 2026-09-29 16:59 UTC  
**Issue state checked:** 2026-09-29 16:59 UTC

## Goal

Deliver Group 31 as one reviewable change: cloud-managed MCP listings install into the active local or cloud workspace, saved connections remain usable and safe to edit, MCP results honor declared schemas, and credential definitions cannot race their linked credentials.

Assigned open issues: #87, #1116, #1136, #1160, #1166, #1167, #1168, #1172, #1173, and #1231–#1234. Prerequisites verified closed or merged before implementation: #1115, #1133, #1134, #624, #877, and #1147. #972 remains open as a related security/legal audit and is outside this group.

## Selected approach

Keep the current MCP verification, discovery, and permission flow. Add a cloud database catalog and let the workspace credentials flow browse it. Installing an entry copies its listing and selected option metadata into the workspace record; connection values go only to that workspace's encrypted credential storage. Existing installs therefore keep their own configuration when catalog records change or disappear.

Two alternatives were considered. A bundled catalog would require app releases for listing changes, so it misses #1231. A live catalog reference would let catalog edits or removal alter existing installs, so it misses #1233. The cloud catalog plus workspace snapshot meets both requirements with current local and cloud connection boundaries.

## Data and boundaries

- The Serverpod catalog contains listing metadata, transport, authentication options, and credential field definitions. It contains no submitted values, API keys, tokens, or workspace records. No catalog admin UI or seeded provider list is included; authorized admins manage records directly in the database.
- An authenticated catalog read returns the current enabled listings. The client filters the returned list by name/description, transport, and available authentication option. Catalog field definitions carry stable keys, secret/required flags, and optional label, description, and help link.
- Catalog install copies the listing and selected option definitions into workspace-owned MCP configuration. It reuses existing verification, tool discovery, and safe permission defaults. Submitted values are written only to the active workspace's secure credential store. Local and cloud paths follow the same field definitions.
- Keep supported connection modes within existing MCP transports: no authentication, OAuth, bearer/API-key credentials, and configured HTTP headers where the transport supports them. Never include field values in catalog responses or diagnostic summaries.
- Saved connection edits preserve existing secret values when secret inputs are untouched. An endpoint or authentication identity change resets affected tool permissions to the existing `alwaysAsk` default. Any connection configuration change clears its prior self-test summary.
- Self-test remains a user-initiated connect/initialize/list/disconnect sequence; it never invokes a tool or syncs permissions. Persist only normalized status, attempt time, transport, discovered-tool count, and elapsed duration. Do not persist URLs, raw errors, credential/header values, schemas, tool metadata, arguments/results, or conversation content. Removal deletes the summary.
- When a tool declares `outputSchema`, validate `structuredContent` with the shared provider-neutral schema validator before model projection. Invalid output becomes a typed protocol failure with tool name and schema path; do not expose the payload or schema. Tools without an output schema keep current behavior.
- Local credential-definition count/check and incompatible update/delete run atomically with the mutation. Cloud mutation uses one server-side conditional transaction shared with credential creation. Existing allowed safe schema edits and legacy metadata-only credential records remain supported.
- Credential management identifies legacy records missing required secrets and routes users to the existing credential editor. Secret inputs start empty; saving supplies only new values, while cancel leaves the record unchanged. Values are never displayed or logged.

## UX flow brief

### Install an MCP catalog entry

- **Goal and start:** From the active workspace's credentials/service-connections screen, find and add an MCP server without copying its endpoint or auth instructions manually.
- **Browse view:** Show listing name, description, transport, and available account/usage options. Search and filters narrow the current cloud catalog. Empty and no-match states explain the next action.
- **Configure view:** After selecting an option, show only its defined fields, required status, safe/secret input type, descriptions, and help links. Secret fields never echo a saved or submitted value.
- **Result:** Submit the configuration, run the existing connection verification and discovery flow, then show discovered tools and their permission choices. Failure preserves the user's configuration for correction or retry without silently granting permissions.
- **Observable completion:** The connection appears in the active workspace after navigation and restart. Editing or removing the catalog listing does not change the installed workspace snapshot.

### Repair an incomplete legacy credential

- **Incomplete:** Keep the credential visible, mark it as needing required values, and offer Edit.
- **Editing/saving:** Display metadata and non-secret values, never stored secret values. Blank secret fields mean preserve existing values. Show a saving state and keep save/cancel actions understandable.
- **Success/failure/cancel:** After save, the credential is ready and remains identifiable after leaving and returning. A save failure keeps the prior record intact and offers retry. Cancel leaves the record unchanged.

### Review an MCP self-test

- Show normalized status, attempt time, transport, discovered-tool count (including zero), and duration after navigation or restart. Authentication failures offer the existing reconnect action; transient failures offer user-initiated retry; protocol/configuration failures offer connection settings. Unknown failures keep the existing details view without guessed diagnosis.

## Verification

- Focused server tests prove live database catalog changes appear on the next read and responses include definitions only.
- Local/cloud install tests prove active-workspace storage, required/secret field handling, verification/discovery/permission reuse, and snapshot independence.
- Service-connection tests prove restart persistence, invalidation/removal, no tool invocation, redaction, reconnect/retry/settings guidance, and edit permission resets.
- Engine and cloud/local MCP tests prove schema validation and deterministic offline discovery refresh, cursor/catalog bounds, output-size bounds, and UTF-8 byte accounting.
- Local/cloud credential tests force create-vs-update and create-vs-delete races; the losing operation returns a typed conflict and no dangling credential results. UI tests cover repair, cancel, save failure, and return-to-screen readiness.

## Assumptions and limits

- Existing local and cloud MCP transports remain the supported transports; catalog records cannot ask the client to execute arbitrary commands or code.
- An API key is a per-workspace secret and can be represented by the configured HTTP header or existing bearer mode. OAuth continues through the existing OAuth flow.
- Catalog reads are authenticated. Search and filters apply to the fetched catalog; paging is not added until catalog volume requires it.
- The resolved #1115 self-test implementation is the baseline and will be re-verified against current code and tests.
- #87 is closed only if this implementation and the existing OAuth, API-key, status, discovery, and permission flows satisfy its parent scope. The PR must not close any assigned issue whose acceptance criteria remain unmet.
