BEGIN;

--
-- ACTION ALTER TABLE
--
-- This migration is intentionally additive. Conversations and their dependent
-- messages, turns, jobs, and tool calls already exist and must retain IDs and
-- foreign keys during the multiplayer-projection rollout.
ALTER TABLE "conversation"
    ADD COLUMN "projectionRevision" bigint NOT NULL DEFAULT 1;
ALTER TABLE "conversation"
    ADD COLUMN "eventSequence" bigint NOT NULL DEFAULT 0;
ALTER TABLE "conversation"
    ADD COLUMN "executionState" text NOT NULL DEFAULT 'idle';
ALTER TABLE "conversation"
    ADD COLUMN "activeExecutionId" bigint;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_event" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "sequence" bigint NOT NULL,
    "eventId" text NOT NULL,
    "actorUserId" text NOT NULL,
    "requestId" text NOT NULL,
    "kind" text NOT NULL,
    "payloadJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_event_sequence_idx" ON "conversation_event" USING btree ("conversationId", "sequence");
CREATE UNIQUE INDEX "conversation_event_workspace_event_idx" ON "conversation_event" USING btree ("workspaceId", "eventId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_execution" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "stableId" text NOT NULL,
    "status" text NOT NULL,
    "settingsJson" text NOT NULL,
    "claimedMessageIdsJson" text NOT NULL,
    "assistantMessageId" bigint,
    "attempt" bigint NOT NULL,
    "createdByUserId" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "terminalAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "conversation_execution_workspace_stable_idx" ON "conversation_execution" USING btree ("workspaceId", "stableId");
CREATE INDEX "conversation_execution_conversation_idx" ON "conversation_execution" USING btree ("conversationId", "id");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "conversation_message" ADD COLUMN "pendingOrder" bigint;
ALTER TABLE "conversation_message" ADD COLUMN "pendingAt" timestamp without time zone;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_event"
    ADD CONSTRAINT "conversation_event_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_event"
    ADD CONSTRAINT "conversation_event_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conversation_execution"
    ADD CONSTRAINT "conversation_execution_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "conversation_execution"
    ADD CONSTRAINT "conversation_execution_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260724022737087', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260724022737087', "timestamp" = now();

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
