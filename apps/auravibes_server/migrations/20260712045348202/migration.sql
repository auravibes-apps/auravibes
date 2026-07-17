BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "stableId" text NOT NULL,
    "title" text,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "conversation_workspace_stable_idx" ON "conversation" USING btree ("workspaceId", "stableId");
CREATE INDEX "conversation_workspace_idx" ON "conversation" USING btree ("workspaceId", "updatedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_delta" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "turnId" bigint NOT NULL,
    "sequence" bigint NOT NULL,
    "kind" text NOT NULL,
    "payloadJson" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_delta_sequence_idx" ON "conversation_delta" USING btree ("workspaceId", "turnId", "sequence");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_job" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "turnId" bigint,
    "requestId" text NOT NULL,
    "kind" text NOT NULL,
    "status" text NOT NULL,
    "payloadJson" text,
    "attempt" bigint NOT NULL,
    "maxAttempts" bigint NOT NULL,
    "availableAt" timestamp without time zone NOT NULL,
    "leaseOwner" text,
    "leaseToken" text,
    "leaseExpiresAt" timestamp without time zone,
    "checkpointJson" text,
    "lastErrorCode" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_job_request_idx" ON "conversation_job" USING btree ("workspaceId", "requestId", "kind");
CREATE INDEX "conversation_job_claim_idx" ON "conversation_job" USING btree ("status", "availableAt", "leaseExpiresAt");
CREATE INDEX "conversation_job_turn_idx" ON "conversation_job" USING btree ("workspaceId", "turnId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_message" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "stableId" text NOT NULL,
    "turnId" bigint,
    "role" text NOT NULL,
    "kind" text NOT NULL,
    "status" text NOT NULL,
    "content" text NOT NULL,
    "metadataJson" text,
    "compactedThroughMessageId" bigint,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_message_stable_idx" ON "conversation_message" USING btree ("workspaceId", "stableId");
CREATE INDEX "conversation_message_order_idx" ON "conversation_message" USING btree ("workspaceId", "conversationId", "id");
CREATE INDEX "conversation_message_turn_idx" ON "conversation_message" USING btree ("workspaceId", "turnId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_tool_call" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "turnId" bigint NOT NULL,
    "messageId" bigint NOT NULL,
    "stableId" text NOT NULL,
    "name" text NOT NULL,
    "argumentsJson" text NOT NULL,
    "argumentsDigest" text NOT NULL,
    "status" text NOT NULL,
    "decision" text,
    "decisionByUserId" text,
    "decisionAt" timestamp without time zone,
    "resultJson" text,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_tool_call_stable_idx" ON "conversation_tool_call" USING btree ("workspaceId", "stableId");
CREATE INDEX "conversation_tool_call_turn_idx" ON "conversation_tool_call" USING btree ("workspaceId", "turnId", "id");

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
    "cancellationRequestedAt" timestamp without time zone,
    "terminalAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_turn_request_idx" ON "conversation_turn" USING btree ("workspaceId", "requestId");
CREATE INDEX "conversation_turn_conversation_idx" ON "conversation_turn" USING btree ("workspaceId", "conversationId", "id");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "conversation_usage" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "conversationId" bigint NOT NULL,
    "turnId" bigint NOT NULL,
    "inputTokens" bigint NOT NULL,
    "outputTokens" bigint NOT NULL,
    "totalTokens" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "conversation_usage_turn_idx" ON "conversation_usage" USING btree ("workspaceId", "turnId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "object_deletion" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "objectId" bigint NOT NULL,
    "objectKey" text NOT NULL,
    "requestId" text NOT NULL,
    "requestedAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone,
    "attempts" bigint NOT NULL,
    "lastError" text
);

-- Indexes
CREATE INDEX "object_deletion_pending_idx" ON "object_deletion" USING btree ("completedAt", "requestedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "object_upload" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "objectId" bigint NOT NULL,
    "actorUserId" text NOT NULL,
    "requestId" text NOT NULL,
    "requestHash" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "object_upload_request_idx" ON "object_upload" USING btree ("actorUserId", "workspaceId", "requestId");
CREATE INDEX "object_upload_expiry_idx" ON "object_upload" USING btree ("completedAt", "expiresAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_object" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "objectKey" text NOT NULL,
    "purpose" text NOT NULL,
    "displayName" text NOT NULL,
    "mimeType" text NOT NULL,
    "sizeBytes" bigint NOT NULL,
    "checksumSha256" text NOT NULL,
    "status" text NOT NULL,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "workspace_object_key_idx" ON "workspace_object" USING btree ("objectKey");
CREATE INDEX "workspace_object_scope_idx" ON "workspace_object" USING btree ("workspaceId", "status", "deletedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_resource" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "resourceKind" text NOT NULL,
    "resourceId" text NOT NULL,
    "data" text NOT NULL,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "workspace_resource_identity_idx" ON "workspace_resource" USING btree ("workspaceId", "resourceKind", "resourceId");
CREATE INDEX "workspace_resource_page_idx" ON "workspace_resource" USING btree ("workspaceId", "resourceKind", "updatedAt", "resourceId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_secret" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "secretKind" text NOT NULL,
    "scope" text NOT NULL,
    "ownerUserId" text,
    "resourceId" text NOT NULL,
    "ciphertext" bytea NOT NULL,
    "nonce" bytea NOT NULL,
    "authenticationTag" bytea NOT NULL,
    "algorithm" text NOT NULL,
    "keyVersion" bigint NOT NULL,
    "displaySuffix" text,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "workspace_secret_identity_idx" ON "workspace_secret" USING btree ("workspaceId", "secretKind", "scope", "ownerUserId", "resourceId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "object_deletion"
    ADD CONSTRAINT "object_deletion_fk_0"
    FOREIGN KEY("objectId")
    REFERENCES "workspace_object"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "object_upload"
    ADD CONSTRAINT "object_upload_fk_0"
    FOREIGN KEY("objectId")
    REFERENCES "workspace_object"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260712045348202', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260712045348202', "timestamp" = now();

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
