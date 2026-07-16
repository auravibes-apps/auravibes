BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "cloud_workspace" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "cloud_workspace" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "ownerUserId" text NOT NULL,
    "revision" bigint NOT NULL,
    "sequence" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_audit_record" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "sequence" bigint NOT NULL,
    "actorUserId" text NOT NULL,
    "operation" text NOT NULL,
    "targetKind" text,
    "targetId" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "workspace_audit_record_workspace_idx" ON "workspace_audit_record" USING btree ("workspaceId", "sequence");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_event" (
    "id" bigserial PRIMARY KEY,
    "eventId" text NOT NULL,
    "workspaceId" bigint NOT NULL,
    "sequence" bigint NOT NULL,
    "actorUserId" text NOT NULL,
    "kind" text NOT NULL,
    "resourceKind" text NOT NULL,
    "resourceId" text,
    "payloadJson" text,
    "createdAt" timestamp without time zone NOT NULL,
    "publishedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "workspace_event_id_idx" ON "workspace_event" USING btree ("eventId");
CREATE UNIQUE INDEX "workspace_event_sequence_idx" ON "workspace_event" USING btree ("workspaceId", "sequence");
CREATE INDEX "workspace_event_outbox_idx" ON "workspace_event" USING btree ("publishedAt", "createdAt");

--
-- ACTION DROP TABLE
--
DROP TABLE "workspace_invite" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_invite" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "email" text NOT NULL,
    "normalizedEmail" text NOT NULL,
    "role" text NOT NULL,
    "invitedByUserId" text NOT NULL,
    "acceptedByUserId" text,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone,
    "acceptedAt" timestamp without time zone,
    "declinedAt" timestamp without time zone,
    "revokedAt" timestamp without time zone,
    "pendingKey" text
);

-- Indexes
CREATE UNIQUE INDEX "workspace_invite_pending_key_idx" ON "workspace_invite" USING btree ("pendingKey");
CREATE INDEX "workspace_invite_email_state_idx" ON "workspace_invite" USING btree ("normalizedEmail", "acceptedAt", "declinedAt", "revokedAt");

--
-- ACTION DROP TABLE
--
DROP TABLE "workspace_member" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_member" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "userId" text NOT NULL,
    "role" text NOT NULL,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "removedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "workspace_member_workspace_user_idx" ON "workspace_member" USING btree ("workspaceId", "userId");
CREATE INDEX "workspace_member_user_removed_idx" ON "workspace_member" USING btree ("userId", "removedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_mutation_receipt" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint,
    "actorUserId" text NOT NULL,
    "endpoint" text NOT NULL,
    "requestId" text NOT NULL,
    "requestHash" text NOT NULL,
    "responseJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "workspace_mutation_receipt_request_idx" ON "workspace_mutation_receipt" USING btree ("actorUserId", "endpoint", "requestId");
CREATE INDEX "workspace_mutation_receipt_workspace_idx" ON "workspace_mutation_receipt" USING btree ("workspaceId", "createdAt");


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260712043123049', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260712043123049', "timestamp" = now();

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
