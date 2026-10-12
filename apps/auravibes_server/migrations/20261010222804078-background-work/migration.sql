BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "background_work_record" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "conversationToolCallId" bigint NOT NULL,
    "originatingMessageId" bigint,
    "stableId" text NOT NULL,
    "toolCallId" text NOT NULL,
    "toolKind" text NOT NULL,
    "status" text NOT NULL,
    "statusPreview" text,
    "resultContent" text,
    "resultByteLength" bigint NOT NULL DEFAULT 0,
    "errorCode" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "background_work_record_workspace_stable_idx" ON "background_work_record" USING btree ("workspaceId", "stableId");
CREATE UNIQUE INDEX "background_work_record_call_idx" ON "background_work_record" USING btree ("workspaceId", "conversationId", "conversationToolCallId");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "conversation_tool_call" ADD COLUMN "backgroundEligible" boolean NOT NULL DEFAULT false;
ALTER TABLE "conversation_tool_call" ADD COLUMN "backgroundWorkStableId" text;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "background_work_record"
    ADD CONSTRAINT "background_work_record_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "background_work_record"
    ADD CONSTRAINT "background_work_record_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "background_work_record"
    ADD CONSTRAINT "background_work_record_fk_2"
    FOREIGN KEY("conversationToolCallId")
    REFERENCES "conversation_tool_call"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "background_work_record"
    ADD CONSTRAINT "background_work_record_fk_3"
    FOREIGN KEY("originatingMessageId")
    REFERENCES "conversation_message"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261010222804078-background-work', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261010222804078-background-work', "timestamp" = now();

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
