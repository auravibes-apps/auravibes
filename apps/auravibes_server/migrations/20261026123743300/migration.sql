BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "cloud_workspace" ADD COLUMN "erasureRequestedAt" timestamp without time zone;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_erasure_request" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "workspaceName" text NOT NULL,
    "ownerUserId" text NOT NULL,
    "requestId" text NOT NULL,
    "requestHash" text NOT NULL,
    "state" text NOT NULL,
    "requestedAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone,
    "failureReason" text
);

-- Indexes
CREATE UNIQUE INDEX "workspace_erasure_owner_request_idx" ON "workspace_erasure_request" USING btree ("ownerUserId", "requestId");
CREATE INDEX "workspace_erasure_workspace_state_idx" ON "workspace_erasure_request" USING btree ("workspaceId", "state");


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261026123743300', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261026123743300', "timestamp" = now();

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
