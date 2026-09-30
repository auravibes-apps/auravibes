BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "mcp_catalog_entry" (
    "id" bigserial PRIMARY KEY,
    "catalogId" text NOT NULL,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "url" text NOT NULL,
    "transport" text NOT NULL,
    "isEnabled" boolean NOT NULL,
    "optionsJson" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "mcp_catalog_entry_catalog_id_idx" ON "mcp_catalog_entry" USING btree ("catalogId");
CREATE INDEX "mcp_catalog_entry_enabled_name_idx" ON "mcp_catalog_entry" USING btree ("isEnabled", "name");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "serverpod_auth_core_profile" DROP CONSTRAINT IF EXISTS "serverpod_auth_core_profile_fk_1";
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_1"
    FOREIGN KEY("imageId")
    REFERENCES "serverpod_auth_core_profile_image"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260929172625300', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260929172625300', "timestamp" = now();

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
