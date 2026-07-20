# HA Recurring Worker Coordinator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace recurring Serverpod FutureCall chains with a durable, highly available leader coordinator.

**Architecture:** Every server runs a lightweight heartbeat. The database elects one fenced leader, which owns local worker timers. Durable schedule rows lease each worker execution, so a replacement leader can recover interrupted work without relying on FutureCall scheduling.

**Tech Stack:** Dart, Serverpod 4, PostgreSQL, Serverpod protocol generation/migrations, package:test.

## Global Constraints

- Do not hand-edit Serverpod generated files.
- Preserve `ConversationJobLeases` and its `SKIP LOCKED` claim behavior.
- Run every server replica with a unique `--server-id`.
- The coordinator must not use Serverpod FutureCalls.
- Use forward migrations only.

---

### Task 1: Remove the rejected FutureCall lease design

**Files:**

- Revert: uncommitted changes to `apps/auravibes_server/lib/server.dart`, the three worker files, generated protocol/client files, and `migration_registry.txt`.
- Delete: uncommitted `recurring_worker_lease` source/generated files, its migration, and its tests.

- [ ] Restore the four pre-existing worker/server source files so they retain their original self-rescheduling behavior until the coordinator replaces them.
- [ ] Remove only the uncommitted lease model, generated output, migration, and tests; preserve the committed coordinator design specification.
- [ ] Confirm `git status --short` contains no rejected lease artifacts.

### Task 2: Add fenced coordinator and execution schedules

**Files:**

- Create: `apps/auravibes_server/lib/src/features/workers/models/worker_coordinator_lease.spy.yaml`
- Create: `apps/auravibes_server/lib/src/features/workers/models/recurring_worker_schedule.spy.yaml`
- Create: `apps/auravibes_server/lib/src/features/workers/worker_coordinator_repository.dart`
- Create: `apps/auravibes_server/test/integration/features/workers/worker_coordinator_repository_test.dart`
- Generated: Serverpod protocol/client files and a forward migration.

**Interfaces:**

- `Future<WorkerCoordinatorLease?> acquireCoordinator(Session, ownerId, now)` renews an owner or takes an expired lease and increments `fencingToken` only on takeover.
- `Future<RecurringWorkerSchedule?> claimDueRun(Session, workerKey, coordinator, now, executionLease)` validates the current coordinator token and atomically assigns a random `runToken`.
- `Future<bool> completeRun(Session, schedule, nextRunAt, now)` conditionally clears only the matching run token.

- [ ] Write failing integration tests for leader renewal, expired-leader takeover, due-run claiming, and stale-token completion rejection.
- [ ] Generate the protocol and a forward migration after defining the two models.
- [ ] Implement conditional upserts/updates so fencing is checked in the same database operation that claims a run.
- [ ] Run the focused tests; if the existing Serverpod build-hook failure persists, record it and use fatal analysis to confirm compilation.

### Task 3: Implement the coordinator lifecycle and direct runners

**Files:**

- Create: `apps/auravibes_server/lib/src/features/workers/recurring_worker_coordinator.dart`
- Create: `apps/auravibes_server/test/features/workers/recurring_worker_coordinator_test.dart`
- Modify: `apps/auravibes_server/lib/server.dart`
- Modify: `apps/auravibes_server/lib/src/features/conversations/workers/conversation_worker.dart`
- Modify: `apps/auravibes_server/lib/src/features/model_connections/workers/model_catalog_sync_worker.dart`
- Modify: `apps/auravibes_server/lib/src/features/objects/object_cleanup_service.dart`

**Interfaces:**

- `RecurringWorkerCoordinator.start(Serverpod)` starts a 15-second heartbeat and leader-only local timers.
- `RecurringWorkerCoordinator.stop()` cancels all timers.
- `RecurringWorkerDefinition` contains worker key, interval, execution lease duration, and `Future<void> Function(Session)` work callback.

- [ ] Write a failing unit test showing a follower starts no worker timer and a leader uses only one active timer per definition.
- [ ] Implement heartbeat sessions with `try/finally { await session.close(); }`; lease duration is 45 seconds.
- [ ] Implement direct runners: conversation drains `runOnce`; catalog calls `run`; cleanup performs the existing endpoint/configuration guard and `runOnce`.
- [ ] Remove FutureCall registration, startup schedules, poll classes, and self-rescheduling calls.
- [ ] Claim a due schedule before invoking work; renew its execution lease every 30 seconds; complete it with `nextRunAt = now + interval` only when its run token still matches.

### Task 4: Generate, migrate, and validate

**Files:**

- Generated: `apps/auravibes_server/lib/src/generated/**`
- Generated: `packages/auravibes_server_client/lib/src/protocol/**`
- Generated: `apps/auravibes_server/migrations/<timestamp>/**`

- [ ] Run `cd apps/auravibes_server && serverpod generate` and inspect generated output.
- [ ] Run `cd apps/auravibes_server && serverpod create-migration --force`; confirm the migration creates only coordinator/schedule tables and their indexes.
- [ ] Run focused tests, `fvm dart analyze --fatal-infos --fatal-warnings`, `dart format --set-exit-if-changed`, and `git diff --check`.
- [ ] Stop active local server processes before applying the migration. Start one development server with `--apply-migrations`; verify the coordinator removes the legacy identifiers once and does not recreate them.
