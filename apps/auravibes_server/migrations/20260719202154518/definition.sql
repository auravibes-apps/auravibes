BEGIN;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- Class ApiModel as table api_model
--
CREATE TABLE "api_model" (
    "id" bigserial PRIMARY KEY,
    "providerId" text NOT NULL,
    "modelId" text NOT NULL,
    "name" text NOT NULL,
    "limitContext" bigint NOT NULL,
    "limitOutput" bigint NOT NULL,
    "modalitiesInput" json NOT NULL,
    "modalitiesOutput" json NOT NULL,
    "family" text,
    "costInput" double precision NOT NULL,
    "costCacheRead" double precision NOT NULL,
    "costOutput" double precision NOT NULL,
    "openWeights" boolean NOT NULL,
    "supportsReasoning" boolean NOT NULL,
    "isCanonical" boolean NOT NULL,
    "supportsPriorityMode" boolean NOT NULL,
    "supportsToolCalls" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "api_model_provider_model_idx" ON "api_model" USING btree ("providerId", "modelId");

--
-- Class ApiModelProvider as table api_model_provider
--
CREATE TABLE "api_model_provider" (
    "id" bigserial PRIMARY KEY,
    "providerId" text NOT NULL,
    "name" text NOT NULL,
    "type" text,
    "url" text,
    "documentationUrl" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "api_model_provider_id_idx" ON "api_model_provider" USING btree ("providerId");

--
-- Class CloudWorkspace as table cloud_workspace
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
-- Class CodexOAuthTransaction as table codex_oauth_transaction
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
-- Class Conversation as table conversation
--
CREATE TABLE "conversation" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "stableId" text NOT NULL,
    "title" text,
    "isPinned" boolean NOT NULL,
    "modelId" text,
    "agentId" text,
    "parentConversationStableId" text,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "conversation_workspace_stable_idx" ON "conversation" USING btree ("workspaceId", "stableId");
CREATE INDEX "conversation_workspace_idx" ON "conversation" USING btree ("workspaceId", "updatedAt");
CREATE UNIQUE INDEX "conversation_workspace_id_idx" ON "conversation" USING btree ("workspaceId", "id");

--
-- Class ConversationJob as table conversation_job
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
-- Class ConversationMessage as table conversation_message
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
CREATE UNIQUE INDEX "conversation_message_workspace_id_idx" ON "conversation_message" USING btree ("workspaceId", "id");

--
-- Class ConversationToolCall as table conversation_tool_call
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
-- Class ConversationTurn as table conversation_turn
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
-- Class ConversationUsage as table conversation_usage
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
-- Class ObjectDeletion as table object_deletion
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
-- Class ObjectReference as table object_reference
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
-- Class ObjectUpload as table object_upload
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
CREATE UNIQUE INDEX "object_upload_object_idx" ON "object_upload" USING btree ("objectId");
CREATE INDEX "object_upload_expiry_idx" ON "object_upload" USING btree ("completedAt", "expiresAt");

--
-- Class ProviderAdmission as table provider_admission
--
CREATE TABLE "provider_admission" (
    "id" bigserial PRIMARY KEY,
    "jobId" bigint NOT NULL,
    "workspaceId" bigint NOT NULL,
    "providerId" text NOT NULL,
    "leaseToken" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "provider_admission_workspace_created_idx" ON "provider_admission" USING btree ("workspaceId", "createdAt");

--
-- Class ProviderAdmissionLock as table provider_admission_lock
--
CREATE TABLE "provider_admission_lock" (
    "id" bigserial PRIMARY KEY,
    "key" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "provider_admission_lock_key_idx" ON "provider_admission_lock" USING btree ("key");

--
-- Class ProviderAdmissionReservation as table provider_admission_reservation
--
CREATE TABLE "provider_admission_reservation" (
    "id" bigserial PRIMARY KEY,
    "jobId" bigint NOT NULL,
    "workspaceId" bigint NOT NULL,
    "providerId" text NOT NULL,
    "leaseToken" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "provider_admission_reservation_job_idx" ON "provider_admission_reservation" USING btree ("jobId");
CREATE INDEX "provider_admission_reservation_active_idx" ON "provider_admission_reservation" USING btree ("expiresAt", "workspaceId");

--
-- Class RecurringWorkerSchedule as table recurring_worker_schedule
--
CREATE TABLE "recurring_worker_schedule" (
    "id" bigserial PRIMARY KEY,
    "workerKey" text NOT NULL,
    "nextRunAt" timestamp without time zone NOT NULL,
    "runToken" text,
    "leaderFencingToken" bigint,
    "runLeaseExpiresAt" timestamp without time zone,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "recurring_worker_schedule_worker_key_idx" ON "recurring_worker_schedule" USING btree ("workerKey");
CREATE INDEX "recurring_worker_schedule_due_idx" ON "recurring_worker_schedule" USING btree ("nextRunAt", "runLeaseExpiresAt");

--
-- Class WorkerCoordinatorLease as table worker_coordinator_lease
--
CREATE TABLE "worker_coordinator_lease" (
    "id" bigserial PRIMARY KEY,
    "key" text NOT NULL,
    "ownerId" text NOT NULL,
    "fencingToken" bigint NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "worker_coordinator_lease_key_idx" ON "worker_coordinator_lease" USING btree ("key");

--
-- Class WorkspaceAuditRecord as table workspace_audit_record
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
CREATE UNIQUE INDEX "workspace_audit_record_workspace_idx" ON "workspace_audit_record" USING btree ("workspaceId", "sequence");

--
-- Class WorkspaceEvent as table workspace_event
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
-- Class WorkspaceInvite as table workspace_invite
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
-- Class WorkspaceMember as table workspace_member
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
-- Class WorkspaceModelConnection as table workspace_model_connection
--
CREATE TABLE "workspace_model_connection" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "connectionId" text NOT NULL,
    "providerId" text NOT NULL,
    "name" text NOT NULL,
    "url" text,
    "keySuffix" text,
    "hasSecret" boolean NOT NULL,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "workspace_model_connection_identity_idx" ON "workspace_model_connection" USING btree ("workspaceId", "connectionId");
CREATE INDEX "workspace_model_connection_active_idx" ON "workspace_model_connection" USING btree ("workspaceId", "deletedAt");

--
-- Class WorkspaceMutationReceipt as table workspace_mutation_receipt
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
-- Class WorkspaceObject as table workspace_object
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
-- Class WorkspaceResource as table workspace_resource
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
-- Class WorkspaceSecret as table workspace_secret
--
CREATE TABLE "workspace_secret" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "secretKind" text NOT NULL,
    "scope" text NOT NULL,
    "ownerUserId" text NOT NULL,
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
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text,
    "scheduling" json
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class FutureCallClaimEntry as table serverpod_future_call_claim
--
CREATE TABLE "serverpod_future_call_claim" (
    "id" bigserial PRIMARY KEY,
    "futureCallId" bigint,
    "lastHeartbeatTime" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "future_call_unique_idx" ON "serverpod_future_call_claim" USING btree ("futureCallId");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId", "order");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_message_log_sessionLogId_idx" ON "serverpod_message_log" USING btree ("sessionLogId", "order");

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId", "order");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Class RefreshToken as table serverpod_auth_core_jwt_refresh_token
--
CREATE TABLE "serverpod_auth_core_jwt_refresh_token" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "extraClaims" text,
    "method" text NOT NULL,
    "fixedSecret" bytea NOT NULL,
    "rotatingSecretHash" text NOT NULL,
    "lastUpdatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "serverpod_auth_core_jwt_refresh_token_last_updated_at" ON "serverpod_auth_core_jwt_refresh_token" USING btree ("lastUpdatedAt");

--
-- Class UserProfile as table serverpod_auth_core_profile
--
CREATE TABLE "serverpod_auth_core_profile" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userName" text,
    "fullName" text,
    "email" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "imageId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_profile_user_profile_email_auth_user_id" ON "serverpod_auth_core_profile" USING btree ("authUserId");

--
-- Class UserProfileImage as table serverpod_auth_core_profile_image
--
CREATE TABLE "serverpod_auth_core_profile_image" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userProfileId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "url" text NOT NULL
);

--
-- Class ServerSideSession as table serverpod_auth_core_session
--
CREATE TABLE "serverpod_auth_core_session" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUsedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" timestamp without time zone,
    "expireAfterUnusedFor" bigint,
    "sessionKeyHash" bytea NOT NULL,
    "sessionKeySalt" bytea NOT NULL,
    "method" text NOT NULL
);

--
-- Class AuthUser as table serverpod_auth_core_user
--
CREATE TABLE "serverpod_auth_core_user" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "scopeNames" json NOT NULL,
    "blocked" boolean NOT NULL
);

--
-- Class AnonymousAccount as table serverpod_auth_idp_anonymous_account
--
CREATE TABLE "serverpod_auth_idp_anonymous_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- Class AppleAccount as table serverpod_auth_idp_apple_account
--
CREATE TABLE "serverpod_auth_idp_apple_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userIdentifier" text NOT NULL,
    "refreshToken" text NOT NULL,
    "refreshTokenRequestedWithBundleIdentifier" boolean NOT NULL,
    "lastRefreshedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text,
    "isEmailVerified" boolean,
    "isPrivateEmail" boolean,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_apple_account_identifier" ON "serverpod_auth_idp_apple_account" USING btree ("userIdentifier");

--
-- Class EmailAccount as table serverpod_auth_idp_email_account
--
CREATE TABLE "serverpod_auth_idp_email_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "passwordHash" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_email" ON "serverpod_auth_idp_email_account" USING btree ("email");

--
-- Class EmailAccountPasswordResetRequest as table serverpod_auth_idp_email_account_password_reset_request
--
CREATE TABLE "serverpod_auth_idp_email_account_password_reset_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "emailAccountId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "challengeId" uuid NOT NULL,
    "setPasswordChallengeId" uuid
);

--
-- Class EmailAccountRequest as table serverpod_auth_idp_email_account_request
--
CREATE TABLE "serverpod_auth_idp_email_account_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "email" text NOT NULL,
    "challengeId" uuid NOT NULL,
    "createAccountChallengeId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_request_email" ON "serverpod_auth_idp_email_account_request" USING btree ("email");

--
-- Class FacebookAccount as table serverpod_auth_idp_facebook_account
--
CREATE TABLE "serverpod_auth_idp_facebook_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "fullName" text,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_facebook_account_user_identifier" ON "serverpod_auth_idp_facebook_account" USING btree ("userIdentifier");

--
-- Class FirebaseAccount as table serverpod_auth_idp_firebase_account
--
CREATE TABLE "serverpod_auth_idp_firebase_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text,
    "phone" text,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_firebase_account_user_identifier" ON "serverpod_auth_idp_firebase_account" USING btree ("userIdentifier");

--
-- Class GitHubAccount as table serverpod_auth_idp_github_account
--
CREATE TABLE "serverpod_auth_idp_github_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_github_account_user_identifier" ON "serverpod_auth_idp_github_account" USING btree ("userIdentifier");

--
-- Class GoogleAccount as table serverpod_auth_idp_google_account
--
CREATE TABLE "serverpod_auth_idp_google_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_google_account_user_identifier" ON "serverpod_auth_idp_google_account" USING btree ("userIdentifier");

--
-- Class MicrosoftAccount as table serverpod_auth_idp_microsoft_account
--
CREATE TABLE "serverpod_auth_idp_microsoft_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_microsoft_account_user_identifier" ON "serverpod_auth_idp_microsoft_account" USING btree ("userIdentifier");

--
-- Class PasskeyAccount as table serverpod_auth_idp_passkey_account
--
CREATE TABLE "serverpod_auth_idp_passkey_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "keyId" bytea NOT NULL,
    "keyIdBase64" text NOT NULL,
    "clientDataJSON" bytea NOT NULL,
    "attestationObject" bytea NOT NULL,
    "originalChallenge" bytea NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_passkey_account_key_id_base64" ON "serverpod_auth_idp_passkey_account" USING btree ("keyIdBase64");

--
-- Class PasskeyChallenge as table serverpod_auth_idp_passkey_challenge
--
CREATE TABLE "serverpod_auth_idp_passkey_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "challenge" bytea NOT NULL
);

--
-- Class RateLimitedRequestAttempt as table serverpod_auth_idp_rate_limited_request_attempt
--
CREATE TABLE "serverpod_auth_idp_rate_limited_request_attempt" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "domain" text NOT NULL,
    "source" text NOT NULL,
    "nonce" text NOT NULL,
    "ipAddress" text,
    "attemptedAt" timestamp without time zone NOT NULL,
    "extraData" json
);

-- Indexes
CREATE INDEX "serverpod_auth_idp_rate_limited_request_attempt_composite" ON "serverpod_auth_idp_rate_limited_request_attempt" USING btree ("domain", "source", "nonce", "attemptedAt");

--
-- Class SecretChallenge as table serverpod_auth_idp_secret_challenge
--
CREATE TABLE "serverpod_auth_idp_secret_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "challengeCodeHash" text NOT NULL
);

--
-- Foreign relations for "conversation" table
--
ALTER TABLE ONLY "conversation"
    ADD CONSTRAINT "conversation_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "conversation_job" table
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
-- Foreign relations for "conversation_message" table
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
-- Foreign relations for "conversation_tool_call" table
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
-- Foreign relations for "conversation_turn" table
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
-- Foreign relations for "conversation_usage" table
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
-- Foreign relations for "object_deletion" table
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
-- Foreign relations for "object_reference" table
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
-- Foreign relations for "object_upload" table
--
ALTER TABLE ONLY "object_upload"
    ADD CONSTRAINT "object_upload_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "object_upload"
    ADD CONSTRAINT "object_upload_fk_1"
    FOREIGN KEY("objectId")
    REFERENCES "workspace_object"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "provider_admission" table
--
ALTER TABLE ONLY "provider_admission"
    ADD CONSTRAINT "provider_admission_fk_0"
    FOREIGN KEY("jobId")
    REFERENCES "conversation_job"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "provider_admission"
    ADD CONSTRAINT "provider_admission_fk_1"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "provider_admission_reservation" table
--
ALTER TABLE ONLY "provider_admission_reservation"
    ADD CONSTRAINT "provider_admission_reservation_fk_0"
    FOREIGN KEY("jobId")
    REFERENCES "conversation_job"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "provider_admission_reservation"
    ADD CONSTRAINT "provider_admission_reservation_fk_1"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "workspace_audit_record" table
--
ALTER TABLE ONLY "workspace_audit_record"
    ADD CONSTRAINT "workspace_audit_record_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "workspace_event" table
--
ALTER TABLE ONLY "workspace_event"
    ADD CONSTRAINT "workspace_event_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "workspace_invite" table
--
ALTER TABLE ONLY "workspace_invite"
    ADD CONSTRAINT "workspace_invite_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "workspace_member" table
--
ALTER TABLE ONLY "workspace_member"
    ADD CONSTRAINT "workspace_member_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "workspace_model_connection" table
--
ALTER TABLE ONLY "workspace_model_connection"
    ADD CONSTRAINT "workspace_model_connection_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "workspace_mutation_receipt" table
--
ALTER TABLE ONLY "workspace_mutation_receipt"
    ADD CONSTRAINT "workspace_mutation_receipt_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "workspace_object" table
--
ALTER TABLE ONLY "workspace_object"
    ADD CONSTRAINT "workspace_object_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_future_call_claim" table
--
ALTER TABLE ONLY "serverpod_future_call_claim"
    ADD CONSTRAINT "serverpod_future_call_claim_fk_0"
    FOREIGN KEY("futureCallId")
    REFERENCES "serverpod_future_call"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_jwt_refresh_token" table
--
ALTER TABLE ONLY "serverpod_auth_core_jwt_refresh_token"
    ADD CONSTRAINT "serverpod_auth_core_jwt_refresh_token_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_profile" table
--
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_1"
    FOREIGN KEY("imageId")
    REFERENCES "serverpod_auth_core_profile_image"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_profile_image" table
--
ALTER TABLE ONLY "serverpod_auth_core_profile_image"
    ADD CONSTRAINT "serverpod_auth_core_profile_image_fk_0"
    FOREIGN KEY("userProfileId")
    REFERENCES "serverpod_auth_core_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_session" table
--
ALTER TABLE ONLY "serverpod_auth_core_session"
    ADD CONSTRAINT "serverpod_auth_core_session_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_anonymous_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_anonymous_account"
    ADD CONSTRAINT "serverpod_auth_idp_anonymous_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_apple_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_apple_account"
    ADD CONSTRAINT "serverpod_auth_idp_apple_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account_password_reset_request" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_0"
    FOREIGN KEY("emailAccountId")
    REFERENCES "serverpod_auth_idp_email_account"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_1"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_2"
    FOREIGN KEY("setPasswordChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account_request" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_0"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_1"
    FOREIGN KEY("createAccountChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_facebook_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_facebook_account"
    ADD CONSTRAINT "serverpod_auth_idp_facebook_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_firebase_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_firebase_account"
    ADD CONSTRAINT "serverpod_auth_idp_firebase_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_github_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_github_account"
    ADD CONSTRAINT "serverpod_auth_idp_github_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_google_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_google_account"
    ADD CONSTRAINT "serverpod_auth_idp_google_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_microsoft_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_microsoft_account"
    ADD CONSTRAINT "serverpod_auth_idp_microsoft_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_passkey_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_passkey_account"
    ADD CONSTRAINT "serverpod_auth_idp_passkey_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260719202154518', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260719202154518', "timestamp" = now();

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
