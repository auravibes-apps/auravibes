BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "conversation"
    ADD COLUMN "isPinned" boolean NOT NULL DEFAULT false,
    ADD COLUMN "modelId" text,
    ADD COLUMN "agentId" text,
    ADD COLUMN "parentConversationStableId" text;

ALTER TABLE "conversation"
    ALTER COLUMN "isPinned" DROP DEFAULT;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260713134310558-f03-f22-final', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260713134310558-f03-f22-final', "timestamp" = now();

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
