BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_model_selection_tool_sampling_policy" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "connectionId" text NOT NULL,
    "modelId" text NOT NULL,
    "toolSamplingPolicy" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "workspace_model_selection_tool_sampling_policy_identity_idx" ON "workspace_model_selection_tool_sampling_policy" USING btree ("workspaceId", "connectionId", "modelId");

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
    VALUES ('auravibes', '20260929231815094-tool-sampling-policy', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260929231815094-tool-sampling-policy', "timestamp" = now();

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
