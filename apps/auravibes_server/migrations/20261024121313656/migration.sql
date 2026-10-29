BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_conversation_context" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "stableId" text NOT NULL,
    "actorUserId" text NOT NULL,
    "selectionJson" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "workspace_conversation_context_request_idx" ON "workspace_conversation_context" USING btree ("workspaceId", "stableId");
CREATE INDEX "workspace_conversation_context_order_idx" ON "workspace_conversation_context" USING btree ("workspaceId", "conversationId", "actorUserId", "id");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_conversation_context"
    ADD CONSTRAINT "workspace_conversation_context_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "workspace_conversation_context"
    ADD CONSTRAINT "workspace_conversation_context_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261024121313656', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261024121313656', "timestamp" = now();

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
