BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "codex_oauth_transaction" (
    "id" bigserial PRIMARY KEY,
    "transactionId" text NOT NULL,
    "workspaceId" bigint NOT NULL,
    "connectionId" text NOT NULL,
    "userId" text NOT NULL,
    "stateHash" text NOT NULL,
    "verifierCiphertext" bytea NOT NULL,
    "verifierNonce" bytea NOT NULL,
    "verifierAuthenticationTag" bytea NOT NULL,
    "redirectUri" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "consumedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "codex_oauth_transaction_id_idx" ON "codex_oauth_transaction" USING btree ("transactionId");
CREATE INDEX "codex_oauth_transaction_expiry_idx" ON "codex_oauth_transaction" USING btree ("expiresAt");

--
-- ACTION DROP TABLE
--
DROP TABLE "object_deletion" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "object_deletion" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "objectId" bigint NOT NULL,
    "objectKey" text NOT NULL,
    "requestId" text NOT NULL,
    "expectedRevision" bigint NOT NULL,
    "requestedAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone,
    "attempts" bigint NOT NULL,
    "availableAt" timestamp without time zone NOT NULL,
    "lastError" text
);

-- Indexes
CREATE UNIQUE INDEX "object_deletion_object_idx" ON "object_deletion" USING btree ("objectId");
CREATE UNIQUE INDEX "object_deletion_request_idx" ON "object_deletion" USING btree ("workspaceId", "requestId");
CREATE INDEX "object_deletion_pending_idx" ON "object_deletion" USING btree ("completedAt", "requestedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "object_reference" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "objectId" bigint NOT NULL,
    "messageId" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "object_reference_message_idx" ON "object_reference" USING btree ("workspaceId", "messageId", "objectId");
CREATE INDEX "object_reference_live_idx" ON "object_reference" USING btree ("workspaceId", "objectId", "deletedAt");

--
-- ACTION ALTER TABLE
--
DROP INDEX "workspace_audit_record_workspace_idx";
CREATE UNIQUE INDEX "workspace_audit_record_workspace_idx" ON "workspace_audit_record" USING btree ("workspaceId", "sequence");
--
-- ACTION ALTER TABLE
--
--
-- ACTION ALTER TABLE
--
--
-- ACTION ALTER TABLE
--
--
-- ACTION DROP TABLE
--
DROP TABLE "workspace_mutation_receipt" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_mutation_receipt" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint,
    "scopeKey" text NOT NULL,
    "actorUserId" text NOT NULL,
    "endpoint" text NOT NULL,
    "requestId" text NOT NULL,
    "requestHash" text NOT NULL,
    "responseJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "workspace_mutation_receipt_request_idx" ON "workspace_mutation_receipt" USING btree ("actorUserId", "scopeKey", "endpoint", "requestId");
CREATE INDEX "workspace_mutation_receipt_workspace_idx" ON "workspace_mutation_receipt" USING btree ("workspaceId", "createdAt");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "workspace_secret" ALTER COLUMN "ownerUserId" SET NOT NULL;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "object_deletion"
    ADD CONSTRAINT "object_deletion_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "object_deletion"
    ADD CONSTRAINT "object_deletion_fk_1"
    FOREIGN KEY("objectId")
    REFERENCES "workspace_object"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "object_reference"
    ADD CONSTRAINT "object_reference_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "object_reference"
    ADD CONSTRAINT "object_reference_fk_1"
    FOREIGN KEY("objectId")
    REFERENCES "workspace_object"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "object_reference"
    ADD CONSTRAINT "object_reference_fk_2"
    FOREIGN KEY("messageId")
    REFERENCES "conversation_message"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_audit_record"
    ADD CONSTRAINT "workspace_audit_record_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_event"
    ADD CONSTRAINT "workspace_event_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_invite"
    ADD CONSTRAINT "workspace_invite_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_member"
    ADD CONSTRAINT "workspace_member_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_mutation_receipt"
    ADD CONSTRAINT "workspace_mutation_receipt_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260712052420509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260712052420509', "timestamp" = now();

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
