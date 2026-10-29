BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_trash_batch" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "batchId" text NOT NULL,
    "targetJson" text NOT NULL,
    "name" text NOT NULL,
    "membersJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "restoredAt" timestamp without time zone,
    "restoredResultJson" text
);

-- Indexes
CREATE UNIQUE INDEX "workspace_trash_identity_idx" ON "workspace_trash_batch" USING btree ("workspaceId", "batchId");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "workspace_view" ADD COLUMN "deletedAt" timestamp without time zone;

--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261024055317007', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261024055317007', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();


COMMIT;
