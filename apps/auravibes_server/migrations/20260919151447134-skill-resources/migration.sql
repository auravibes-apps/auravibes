BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "skill_resource" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "skillId" text NOT NULL,
    "resourceId" text NOT NULL,
    "title" text NOT NULL,
    "slug" text NOT NULL,
    "description" text NOT NULL,
    "content" text NOT NULL,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "skill_resource_identity_idx" ON "skill_resource" USING btree ("workspaceId", "resourceId");
CREATE INDEX "skill_resource_parent_slug_idx" ON "skill_resource" USING btree ("workspaceId", "skillId", "slug");
CREATE INDEX "skill_resource_active_idx" ON "skill_resource" USING btree ("workspaceId", "skillId", "deletedAt");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "skill_resource"
    ADD CONSTRAINT "skill_resource_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260919151447134-skill-resources', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260919151447134-skill-resources', "timestamp" = now();

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
    VALUES ('serverpod_auth_core', '20260824182354731', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182354731', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260910193913364-string-rate-limit-keys', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260910193913364-string-rate-limit-keys', "timestamp" = now();


COMMIT;
