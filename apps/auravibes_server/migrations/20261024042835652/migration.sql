BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_view" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "stableId" text NOT NULL,
    "data" text NOT NULL,
    "revision" bigint NOT NULL,
    "history" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "workspace_view_stable_idx" ON "workspace_view" USING btree ("workspaceId", "stableId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_view"
    ADD CONSTRAINT "workspace_view_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261024042835652', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261024042835652', "timestamp" = now();

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
