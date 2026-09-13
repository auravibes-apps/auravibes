# Agent Search And Cursor Pagination Design

## Problem

The agent management screen loads every agent and filters in memory. Cloud
reads are capped at 100 resources, so management and `list_agents` can omit
valid agents. Search, filtering, and pagination also differ between local,
cloud, and harness paths.

## Goals

- Search agent name and description at the persistence boundary.
- Filter by visibility and enabled state.
- Page with stable keyset cursors and caller-selected page sizes.
- Keep local, cloud, local-engine, and server-hosted harness contracts aligned.
- Preserve direct agent operations beyond the first 100 cloud resources.
- Preserve compact-selector full-list behavior and existing mutations.

## Non-goals

- Total counts, infinite scrolling, fuzzy search, or snapshot isolation.
- PostgreSQL trigram support or a cloud projection table.
- Replacing generic workspace synchronization.
- Changing `run_sub_agent` behavior.

## Contracts

The app repository adds `listAgents(AgentListQuery)` returning an
`AgentListPage`. Page items contain only ID, name, description, enabled state,
visibility, and skill count. Existing full watch/read methods remain for the
compact selector and current consumers.

The server adds a dedicated agent catalog endpoint. `list` accepts workspace,
query, type, status, limit, and cursor. `getResources` returns the exact agent
resource and its associations so detail and mutation paths do not depend on a
bounded workspace snapshot.

The engine catalog accepts `SubAgentCatalogQuery` and returns
`SubAgentCatalogPage`. `list_agents` accepts optional `query`, `type`, `limit`,
and `cursor`, returning `agents` and nullable `nextCursor`. Harness results are
always restricted to enabled agents.

Limits are 20 by default and 1–100 when supplied. Search is at most 200
characters. Cursors are at most 2,048 characters.

## Cursor Semantics

Cursors are opaque base64url JSON. Version 1 binds the workspace, normalized
query, type, status, last normalized name, and last ID. A cursor is rejected
when malformed, too long, unsupported, cross-workspace, or reused with other
filters. Page size is deliberately not bound and may change between requests.

Rows sort by normalized name ascending, then ID ascending. Implementations
fetch `limit + 1`; the extra row determines whether `nextCursor` exists.
Pagination has no snapshot isolation, so concurrent renames can move rows until
the caller refreshes.

Search uses literal substring matching over name and description. It is
case-insensitive for basic Latin and accent-sensitive. SQL wildcard characters
in user input remain literal.

## Cloud Design

The dedicated server feature authorizes workspace membership before reads. A
fixed parameterized PostgreSQL query extracts agent fields from active
`workspace_resource.data::jsonb`, applies search/type/status/cursor predicates,
sorts, and limits before materialization. A correlated count includes active
agent-skill associations only.

`getResources` directly fetches one active agent and active associations by
agent ID. Existing generic workspace state remains the synchronization API; it
is not extended with feature search.

No PostgreSQL index or projection table is added in v1. Add one only after row
counts and query latency show the JSON scan is a problem.

## Local Design

Drift applies equivalent predicates and keyset ordering before loading rows.
Skills are batch-loaded only for page rows. An expression index on workspace,
case-insensitive name, and ID supports ordered traversal. The app schema moves
from 6 to 7 and creates the index for upgrades while preserving existing data.

## UI Design

An auto-disposed Riverpod notifier owns rows, filters, cursor, initial loading,
load-more loading, and retry state. Search waits 300 ms. Facet changes apply
immediately. A generation token prevents stale responses from replacing newer
filters. Page append deduplicates by ID.

The screen keeps the existing search control and adds type and status dropdowns.
It uses an explicit Show more action instead of implicit scrolling. Initial
failure replaces the list; load-more failure keeps loaded rows and exposes
retry. Empty workspace and filtered no-results remain distinct states.

Create, update, and delete refresh the paged provider while preserving current
filters. Existing full-list invalidation remains for selectors.

## Failure Handling

- Invalid requests and cursors fail as typed validation errors.
- Unauthorized workspaces fail before catalog data is queried.
- A stale load result is discarded by generation, not surfaced as an error.
- A failed page append keeps prior items and cursor for retry.
- Direct lookup returns no resources when the agent is absent or deleted.

## Success Criteria

- Local and cloud screens can search/filter and traverse more than 100 agents.
- Both harness executors expose the same schema and paged response.
- Malformed or mismatched cursors cannot cross query boundaries.
- Existing detail, mutations, navigation, selector, and `run_sub_agent` behavior
  remain intact.
- Focused tests and required repository gates pass.
