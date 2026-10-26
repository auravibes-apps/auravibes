BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_content_report" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "reportId" text NOT NULL,
    "resourceKind" text NOT NULL,
    "resourceId" text NOT NULL,
    "tableId" text,
    "revision" bigint NOT NULL,
    "conversationId" text,
    "reporterUserId" text NOT NULL,
    "status" text NOT NULL,
    "submittedAt" timestamp without time zone NOT NULL,
    "reviewerUserId" text,
    "reviewedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "workspace_content_report_identity_idx" ON "workspace_content_report" USING btree ("workspaceId", "reportId");
CREATE INDEX "workspace_content_report_status_idx" ON "workspace_content_report" USING btree ("workspaceId", "status", "submittedAt");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "workspace_revision" ADD COLUMN "actorUserId" text;
ALTER TABLE "workspace_revision" ADD COLUMN "aiInvolved" boolean;
ALTER TABLE "workspace_revision" ADD COLUMN "operation" text;
ALTER TABLE "workspace_revision" ADD COLUMN "conversationId" text;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_content_report"
    ADD CONSTRAINT "workspace_content_report_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261026045353080', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261026045353080', "timestamp" = now();

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
