# HA Recurring Worker Coordinator Design

## Goal

Run the recurring conversation, catalog-sync, and object-cleanup workers once per interval across a Serverpod cluster; recover automatically after leader failure; and eliminate duplicate Serverpod FutureCall pollers.

## Non-goals

- Change conversation-job claiming: `ConversationJobLeases` and `SKIP LOCKED` remain the exclusive-work boundary.
- Add external scheduling infrastructure.
- Depend on Serverpod FutureCall identifiers being unique. Serverpod permits duplicate identifiers.

## Decision

Remove the recurring Serverpod FutureCalls. Replace them with a leader-only, in-process coordinator backed by durable PostgreSQL lease and schedule rows.

This avoids an unsound FutureCall handoff: Serverpod scheduling and an application database update cannot be made atomic, so a coordinator cannot safely mark a call dispatched, create it, and recover every crash boundary without allowing duplicate or lost calls.

## Components

### Coordinator lease

`WorkerCoordinatorLease` is a singleton row keyed by `global`. It stores `ownerId`, `fencingToken`, and `expiresAt`.

Every replica runs a 15-second heartbeat. A conditional upsert renews the incumbent lease or takes an expired lease. Taking over increments `fencingToken`. The leader starts its local worker timers; a follower stops or does not start them.

### Durable schedules

`RecurringWorkerSchedule` has exactly one row for each worker. It stores:

- `workerKey` (unique)
- `nextRunAt`
- `runToken` (nullable)
- `leaderFencingToken` (nullable)
- `runLeaseExpiresAt` (nullable)
- `updatedAt`

The leader seeds rows when absent. A timer claims a due schedule row with an atomic conditional update that verifies the coordinator’s unexpired owner and fencing token, then assigns a new `runToken`, records that fencing token, and sets the execution lease. A row with an unexpired `runLeaseExpiresAt` cannot be claimed again. On a crash, the successor claims the row after the execution lease expires.

### Worker execution

The leader invokes the existing worker code directly after claiming its schedule row:

- Conversation: runs the existing `ConversationWorker.runOnce` loop every second.
- Catalog sync: invokes `ModelCatalogSyncWorker.run` every 12 hours.
- Object cleanup: invokes `ObjectCleanupService.runOnce` every 12 hours when object-store configuration exists.

The coordinator renews the execution lease while work runs. Completion is conditional on the matching `runToken`; it clears the token and advances `nextRunAt` by the worker interval. A stale leader cannot complete or advance a run claimed by a newer leader.

### Lifecycle

After `pod.start()`, every server starts the coordinator heartbeat. The leader runs only the timers it owns. Timer callbacks create and close an internal Serverpod session. On lease loss, callbacks stop claiming new work. On shutdown or process death, the database lease expires and another replica takes over.

## Timing

- Coordinator heartbeat: 15 seconds.
- Coordinator lease: 45 seconds.
- Conversation timer: 1 second.
- Catalog and cleanup timers: 12 hours.
- Execution leases: 5 minutes, renewed every 30 seconds while a worker runs.

Failover starts within one lease expiry plus one heartbeat. An interrupted run becomes eligible after its execution lease expires.

## Correctness invariants

1. At most one unexpired coordinator leader lease exists.
2. Only the current leader may claim a new worker run.
3. A worker run is completed only by its matching `runToken`.
4. A crash cannot permanently stop a worker: expired coordinator and execution leases are reclaimable.
5. Serverpod FutureCall tables are not used for recurring workers, so startup cannot create duplicate poller chains.

## Migration and cleanup

A forward migration adds the two coordinator tables. The migration does not modify Serverpod-owned tables. On the first successful coordinator leadership, the leader cancels the three legacy FutureCall identifiers once and then relies exclusively on durable schedules.

## Testing

Integration tests cover lease renewal/takeover, schedule seeding, due-run claiming, execution-lease recovery, stale-token completion rejection, and leader-only timer behavior. Existing conversation worker tests continue to cover job leases and terminal behavior.
