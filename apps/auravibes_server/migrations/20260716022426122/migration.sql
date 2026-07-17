BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "provider_admission_lock" (
    "id" bigserial PRIMARY KEY,
    "key" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "provider_admission_lock_key_idx" ON "provider_admission_lock" USING btree ("key");

INSERT INTO "provider_admission_lock" ("key") VALUES ('global');

--
-- ACTION CREATE TABLE
--
CREATE TABLE "provider_admission_reservation" (
    "id" bigserial PRIMARY KEY,
    "jobId" bigint NOT NULL,
    "workspaceId" bigint NOT NULL,
    "providerId" text NOT NULL,
    "leaseToken" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "provider_admission_reservation_job_idx" ON "provider_admission_reservation" USING btree ("jobId");
CREATE INDEX "provider_admission_reservation_active_idx" ON "provider_admission_reservation" USING btree ("expiresAt", "workspaceId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "provider_admission_reservation"
    ADD CONSTRAINT "provider_admission_reservation_fk_0"
    FOREIGN KEY("jobId")
    REFERENCES "conversation_job"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "provider_admission_reservation"
    ADD CONSTRAINT "provider_admission_reservation_fk_1"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260716022426122', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260716022426122', "timestamp" = now();

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
