# Agent Search, Filtering, And Cursor Pagination Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` or `superpowers:subagent-driven-development`.

**Goal:** Replace management-screen in-memory filtering with database-backed
search and cursor pagination for local and cloud workspaces, then expose the
same cursor contract through `list_agents`.

**Architecture:** Boundary-specific query/page models share behavior, not
dependencies. Drift owns local keyset queries, Serverpod owns cloud catalog
queries, app adapters map both to app models, and the engine owns harness-neutral
catalog models.

## Constraints

- Preserve existing dirty localization, screen, generated-key, and widget-test
  changes; evolve them instead of reverting them.
- Keep compact-selector full-list reads and direct runnable-agent validation.
- Use default limit 20, accepted range 1–100, query max 200, cursor max 2,048.
- Keep cloud storage unchanged. Add no cloud index or projection table.
- Generate Serverpod, Drift, Riverpod, and localization outputs; never hand-edit
  generated files.

### Task 1: Server Agent Catalog

**Files:**
- Add `apps/auravibes_server/lib/src/features/agents/**`
- Add Serverpod models under that feature
- Update generated endpoint/protocol/client output through generation
- Add server integration tests

- [ ] Add request, page, item, type, and status protocol models.
- [ ] Implement versioned filter-bound cursor codec.
- [ ] Implement fixed parameterized PostgreSQL list query with `limit + 1`.
- [ ] Implement direct agent/association resource retrieval.
- [ ] Authorize each endpoint operation through workspace membership.
- [ ] Add integration coverage for authorization, filters, search, counts,
      ordering, traversal, cursor validation, and direct retrieval beyond 100.

### Task 2: Local And Cloud App Repositories

**Files:**
- Add app-owned agent list models
- Modify agent repository interface and implementations
- Modify Drift agents DAO/database migration
- Modify cloud repository/provider wiring
- Add focused repository and migration tests

- [ ] Add `AgentListQuery`, `AgentListItem`, and `AgentListPage`.
- [ ] Add local search/filter/keyset query and batch skill counts.
- [ ] Add `(workspace_id, name COLLATE NOCASE, id)` index and schema-7 upgrade.
- [ ] Map cloud list calls through the generated agent catalog client.
- [ ] Use direct resources for cloud reads and mutation revision discovery.
- [ ] Cover equivalent filtering, literal wildcard input, ordering, traversal,
      cursor validation, index creation, and data preservation.

### Task 3: Engine And Harness

**Files:**
- Modify engine sub-agent catalog/runner/tool specs and tests
- Modify app catalog adapter
- Modify server-hosted tool executor and tests

- [ ] Add paged engine catalog query/page contracts.
- [ ] Add `query`, `type`, `limit`, and `cursor` to `list_agents`.
- [ ] Validate argument types and limits.
- [ ] Return `agents` plus nullable `nextCursor` from both executors.
- [ ] Keep enabled-only filtering and `run_sub_agent` unchanged.

### Task 4: Management UI

**Files:**
- Add generated auto-disposed agent list notifier/state
- Modify agent screen and mutation refresh paths
- Extend existing localization and widget tests

- [ ] Own filters, cursor, loading states, retry, and generation in notifier.
- [ ] Debounce search 300 ms; apply facets immediately.
- [ ] Append pages with ID deduplication and stale-result suppression.
- [ ] Replace in-memory `_filterAgents` with paged state.
- [ ] Add localized type/status selectors and explicit Show more.
- [ ] Preserve empty workspace, filtered no-results, navigation, and deletion.
- [ ] Refresh paged and full-list providers after mutations.

### Task 5: Generation And Verification

- [ ] Run Serverpod, Drift, Riverpod, and localization generation.
- [ ] Review every generated path and remove unrelated churn.
- [ ] Run focused server, app repository/migration, engine/harness, notifier,
      and widget tests.
- [ ] Run `fvm dart run melos run validate:quick`.
- [ ] Run `fvm dart run dependency_validator`.
- [ ] Run `fvm dart run import_sorter:main --exit-if-changed`.
- [ ] Inspect final `git status --short` and diff; preserve unrelated changes.
