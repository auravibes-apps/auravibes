BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "provider_admission" (
    "id" bigserial PRIMARY KEY,
    "jobId" bigint NOT NULL,
    "workspaceId" bigint NOT NULL,
    "providerId" text NOT NULL,
    "leaseToken" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "provider_admission_workspace_created_idx" ON "provider_admission" USING btree ("workspaceId", "createdAt");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "provider_admission"
    ADD CONSTRAINT "provider_admission_fk_0"
    FOREIGN KEY("jobId")
    REFERENCES "conversation_job"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "provider_admission"
    ADD CONSTRAINT "provider_admission_fk_1"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260716115129298', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260716115129298', "timestamp" = now();

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
