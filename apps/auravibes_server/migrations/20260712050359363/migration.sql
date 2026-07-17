BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE UNIQUE INDEX "conversation_workspace_id_idx" ON "conversation" USING btree ("workspaceId", "id");
--
-- ACTION ALTER TABLE
--
--
-- ACTION ALTER TABLE
--
--
-- ACTION ALTER TABLE
--
CREATE UNIQUE INDEX "conversation_message_workspace_id_idx" ON "conversation_message" USING btree ("workspaceId", "id");
--
-- ACTION ALTER TABLE
--
--
-- ACTION DROP TABLE
--
DROP TABLE "conversation_turn" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_turn" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "requestId" text NOT NULL,
    "requestHash" text NOT NULL,
    "initiatorUserId" text NOT NULL,
    "userMessageId" bigint,
    "assistantMessageId" bigint,
    "status" text NOT NULL,
    "revision" bigint NOT NULL,
    "acceptedSequence" bigint NOT NULL,
    "cancellationRequestedAt" timestamp without time zone,
    "terminalAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_turn_request_idx" ON "conversation_turn" USING btree ("workspaceId", "requestId");
CREATE INDEX "conversation_turn_conversation_idx" ON "conversation_turn" USING btree ("workspaceId", "conversationId", "id");
CREATE UNIQUE INDEX "conversation_turn_workspace_id_idx" ON "conversation_turn" USING btree ("workspaceId", "id");

--
-- ACTION ALTER TABLE
--
--
-- ACTION ALTER TABLE
--
ALTER TABLE "object_deletion" DROP CONSTRAINT IF EXISTS "object_deletion_fk_0";
CREATE UNIQUE INDEX "object_deletion_object_idx" ON "object_deletion" USING btree ("objectId");
CREATE UNIQUE INDEX "object_deletion_request_idx" ON "object_deletion" USING btree ("workspaceId", "requestId");
--
-- ACTION ALTER TABLE
--
ALTER TABLE "object_upload" DROP CONSTRAINT IF EXISTS "object_upload_fk_0";
CREATE UNIQUE INDEX "object_upload_object_idx" ON "object_upload" USING btree ("objectId");
--
-- ACTION ALTER TABLE
--
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation"
    ADD CONSTRAINT "conversation_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_delta"
    ADD CONSTRAINT "conversation_delta_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_delta"
    ADD CONSTRAINT "conversation_delta_fk_1"
    FOREIGN KEY("turnId")
    REFERENCES "conversation_turn"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_job"
    ADD CONSTRAINT "conversation_job_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_job"
    ADD CONSTRAINT "conversation_job_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_job"
    ADD CONSTRAINT "conversation_job_fk_2"
    FOREIGN KEY("turnId")
    REFERENCES "conversation_turn"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_message"
    ADD CONSTRAINT "conversation_message_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_message"
    ADD CONSTRAINT "conversation_message_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_message"
    ADD CONSTRAINT "conversation_message_fk_2"
    FOREIGN KEY("turnId")
    REFERENCES "conversation_turn"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_tool_call"
    ADD CONSTRAINT "conversation_tool_call_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_tool_call"
    ADD CONSTRAINT "conversation_tool_call_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_tool_call"
    ADD CONSTRAINT "conversation_tool_call_fk_2"
    FOREIGN KEY("turnId")
    REFERENCES "conversation_turn"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_tool_call"
    ADD CONSTRAINT "conversation_tool_call_fk_3"
    FOREIGN KEY("messageId")
    REFERENCES "conversation_message"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_turn"
    ADD CONSTRAINT "conversation_turn_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_turn"
    ADD CONSTRAINT "conversation_turn_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_turn"
    ADD CONSTRAINT "conversation_turn_fk_2"
    FOREIGN KEY("userMessageId")
    REFERENCES "conversation_message"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_turn"
    ADD CONSTRAINT "conversation_turn_fk_3"
    FOREIGN KEY("assistantMessageId")
    REFERENCES "conversation_message"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_usage"
    ADD CONSTRAINT "conversation_usage_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_usage"
    ADD CONSTRAINT "conversation_usage_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_usage"
    ADD CONSTRAINT "conversation_usage_fk_2"
    FOREIGN KEY("turnId")
    REFERENCES "conversation_turn"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "object_deletion"
    ADD CONSTRAINT "object_deletion_fk_1"
    FOREIGN KEY("objectId")
    REFERENCES "workspace_object"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "object_deletion"
    ADD CONSTRAINT "object_deletion_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "object_upload"
    ADD CONSTRAINT "object_upload_fk_1"
    FOREIGN KEY("objectId")
    REFERENCES "workspace_object"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "object_upload"
    ADD CONSTRAINT "object_upload_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_object"
    ADD CONSTRAINT "workspace_object_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260712050359363', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260712050359363', "timestamp" = now();

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
