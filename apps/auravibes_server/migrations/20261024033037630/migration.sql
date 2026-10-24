BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "connector_write" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "operationId" text NOT NULL,
    "requestDigest" text NOT NULL,
    "outcome" text NOT NULL,
    "statusCode" bigint
);

-- Indexes
CREATE UNIQUE INDEX "connector_write_operation_idx" ON "connector_write" USING btree ("workspaceId", "operationId");
CREATE INDEX "connector_write_digest_idx" ON "connector_write" USING btree ("workspaceId", "requestDigest");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "connector_write"
    ADD CONSTRAINT "connector_write_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261024033037630', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261024033037630', "timestamp" = now();

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
