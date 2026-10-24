BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_revision" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "resourceKind" text NOT NULL,
    "resourceId" text NOT NULL,
    "revision" bigint NOT NULL,
    "data" text NOT NULL,
    "capturedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "workspace_revision_identity_idx" ON "workspace_revision" USING btree ("workspaceId", "resourceKind", "resourceId", "revision");


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261024081811809', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261024081811809', "timestamp" = now();

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
