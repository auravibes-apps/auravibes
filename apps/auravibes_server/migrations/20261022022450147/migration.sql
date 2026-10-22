BEGIN;

-- Preserve existing bookmarks and snapshot their current target before it can
-- be deleted or compacted.
ALTER TABLE "message_bookmark"
    ADD COLUMN "conversationId" bigint,
    ADD COLUMN "messageStableId" text,
    ADD COLUMN "contentSnapshot" text,
    ADD COLUMN "roleSnapshot" text,
    ADD COLUMN "messageCreatedAt" timestamp without time zone;

UPDATE "message_bookmark" AS bookmark
SET "conversationId" = message."conversationId",
    "messageStableId" = message."stableId",
    "contentSnapshot" = message."content",
    "roleSnapshot" = message."role",
    "messageCreatedAt" = message."createdAt"
FROM "conversation_message" AS message
WHERE message."id" = bookmark."messageId";

ALTER TABLE "message_bookmark"
    ALTER COLUMN "conversationId" SET NOT NULL,
    ALTER COLUMN "messageStableId" SET NOT NULL,
    ALTER COLUMN "contentSnapshot" SET NOT NULL,
    ALTER COLUMN "roleSnapshot" SET NOT NULL,
    ALTER COLUMN "messageCreatedAt" SET NOT NULL,
    DROP CONSTRAINT "message_bookmark_fk_1";

-- Keep the owning conversation cascade while allowing a message target to be
-- removed without deleting its bookmark snapshot.
ALTER TABLE ONLY "message_bookmark"
    ADD CONSTRAINT "message_bookmark_fk_1"
    FOREIGN KEY("conversationId")
    REFERENCES "conversation"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261022022450147', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261022022450147', "timestamp" = now();

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
