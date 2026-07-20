BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "recurring_worker_schedule" (
    "id" bigserial PRIMARY KEY,
    "workerKey" text NOT NULL,
    "nextRunAt" timestamp without time zone NOT NULL,
    "runToken" text,
    "leaderFencingToken" bigint,
    "runLeaseExpiresAt" timestamp without time zone,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "recurring_worker_schedule_worker_key_idx" ON "recurring_worker_schedule" USING btree ("workerKey");
CREATE INDEX "recurring_worker_schedule_due_idx" ON "recurring_worker_schedule" USING btree ("nextRunAt", "runLeaseExpiresAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "worker_coordinator_lease" (
    "id" bigserial PRIMARY KEY,
    "key" text NOT NULL,
    "ownerId" text NOT NULL,
    "fencingToken" bigint NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "worker_coordinator_lease_key_idx" ON "worker_coordinator_lease" USING btree ("key");


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260719202154518', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260719202154518', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260416151914983-insights-perf', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260416151914983-insights-perf', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260417182253191', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260417182253191', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260417182309198', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260417182309198', "timestamp" = now();


COMMIT;
