BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "object_deletion" ADD COLUMN "cleanupGeneration" bigint NOT NULL DEFAULT 0;
ALTER TABLE "object_deletion" ADD COLUMN "uploadCleanupVerifiedAt" timestamp without time zone;
ALTER TABLE "object_deletion" ADD COLUMN "uploadCleanupVerifiedGeneration" bigint;
ALTER TABLE "object_deletion" ADD COLUMN "uploadCleanupVerifiedExpiresAt" timestamp without time zone;

--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261026202804082-upload-cleanup-proof', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261026202804082-upload-cleanup-proof', "timestamp" = now();

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
