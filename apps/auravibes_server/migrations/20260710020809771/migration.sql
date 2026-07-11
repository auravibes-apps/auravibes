BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "workspace_invite" ADD COLUMN "expiresAt" timestamp without time zone;
ALTER TABLE "workspace_invite" ADD COLUMN "revokedAt" timestamp without time zone;
ALTER TABLE "workspace_invite" ADD COLUMN "pendingKey" text;
UPDATE "workspace_invite"
SET "expiresAt" = "createdAt" + INTERVAL '7 days'
WHERE "expiresAt" IS NULL;
CREATE UNIQUE INDEX "workspace_invite_pending_key_idx" ON "workspace_invite" USING btree ("pendingKey");
--
-- ACTION ALTER TABLE
--
DELETE FROM "workspace_member"
WHERE id IN (
  SELECT id
  FROM (
    SELECT
      id,
      ROW_NUMBER() OVER (
        PARTITION BY "workspaceId", "userId"
        ORDER BY ("removedAt" IS NULL) DESC, "createdAt" DESC, id DESC
      ) AS duplicate_rank
    FROM "workspace_member"
  ) ranked_members
  WHERE duplicate_rank > 1
);
CREATE UNIQUE INDEX "workspace_member_workspace_user_idx" ON "workspace_member" USING btree ("workspaceId", "userId");

--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260710020809771', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260710020809771', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260416151914983-insights-perf', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260416151914983-insights-perf', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260417182309198', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260417182309198', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260417182253191', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260417182253191', "timestamp" = now();


COMMIT;
