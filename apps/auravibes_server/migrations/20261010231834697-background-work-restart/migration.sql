BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "background_work_record" ADD COLUMN "runtimeServerId" text;

--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261010231834697-background-work-restart', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261010231834697-background-work-restart', "timestamp" = now();

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
