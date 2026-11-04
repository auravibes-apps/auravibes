BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_label" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "stableId" text NOT NULL,
    "name" text NOT NULL,
    "normalizedName" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_label_workspace_stable_idx" ON "conversation_label" USING btree ("workspaceId", "stableId");
CREATE UNIQUE INDEX "conversation_label_workspace_name_idx" ON "conversation_label" USING btree ("workspaceId", "normalizedName");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_label_assignment" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "labelId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_label_assignment_identity_idx" ON "conversation_label_assignment" USING btree ("workspaceId", "conversationId", "labelId");
CREATE INDEX "conversation_label_assignment_filter_idx" ON "conversation_label_assignment" USING btree ("workspaceId", "labelId", "conversationId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_label"
    ADD CONSTRAINT "conversation_label_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_label_assignment"
    ADD CONSTRAINT "conversation_label_assignment_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_label_assignment"
    ADD CONSTRAINT "conversation_label_assignment_fk_1"
    FOREIGN KEY("labelId")
    REFERENCES "conversation_label"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_label_assignment"
    ADD CONSTRAINT "conversation_label_assignment_fk_2"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261103175754661-issue-1446-labels', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261103175754661-issue-1446-labels', "timestamp" = now();

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
