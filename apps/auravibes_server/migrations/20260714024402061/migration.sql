BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "api_model" (
    "id" bigserial PRIMARY KEY,
    "providerId" text NOT NULL,
    "modelId" text NOT NULL,
    "name" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "api_model_provider_model_idx" ON "api_model" USING btree ("providerId", "modelId");

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
--
CREATE TABLE "workspace_model_selection" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "selectionId" text NOT NULL,
    "connectionId" text NOT NULL,
    "providerId" text NOT NULL,
    "modelId" text NOT NULL,
    "modelName" text NOT NULL,
    "revision" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deletedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "workspace_model_selection_identity_idx" ON "workspace_model_selection" USING btree ("workspaceId", "selectionId");
CREATE UNIQUE INDEX "workspace_model_selection_connection_model_idx" ON "workspace_model_selection" USING btree ("workspaceId", "connectionId", "modelId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_model_connection"
    ADD CONSTRAINT "workspace_model_connection_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_model_selection"
    ADD CONSTRAINT "workspace_model_selection_fk_0"
    FOREIGN KEY("workspaceId")
    REFERENCES "cloud_workspace"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION MOVE LEGACY MODEL RESOURCES
--
INSERT INTO "api_model_provider" (
    "providerId", "name", "url", "createdAt", "updatedAt"
)
SELECT DISTINCT
    resource."data"::jsonb->>'modelId',
    COALESCE(resource."data"::jsonb->>'name', resource."data"::jsonb->>'modelId'),
    resource."data"::jsonb->>'url',
    resource."createdAt",
    resource."updatedAt"
FROM "workspace_resource" AS resource
WHERE resource."resourceKind" = 'modelConnection'
  AND resource."deletedAt" IS NULL
  AND resource."data"::jsonb->>'modelId' IS NOT NULL
ON CONFLICT ("providerId") DO NOTHING;

INSERT INTO "workspace_model_connection" (
    "workspaceId", "connectionId", "providerId", "name", "url",
    "keySuffix", "hasSecret", "revision", "createdAt", "updatedAt", "deletedAt"
)
SELECT
    resource."workspaceId",
    resource."resourceId",
    resource."data"::jsonb->>'modelId',
    COALESCE(resource."data"::jsonb->>'name', resource."data"::jsonb->>'modelId'),
    resource."data"::jsonb->>'url',
    resource."data"::jsonb->>'keySuffix',
    COALESCE((resource."data"::jsonb->>'hasSecret')::boolean, false),
    resource."revision",
    resource."createdAt",
    resource."updatedAt",
    resource."deletedAt"
FROM "workspace_resource" AS resource
WHERE resource."resourceKind" = 'modelConnection'
  AND resource."data"::jsonb->>'modelId' IS NOT NULL
ON CONFLICT ("workspaceId", "connectionId") DO NOTHING;

INSERT INTO "workspace_model_selection" (
    "workspaceId", "selectionId", "connectionId", "providerId", "modelId",
    "modelName", "revision", "createdAt", "updatedAt", "deletedAt"
)
SELECT
    selection."workspaceId",
    selection."resourceId",
    selection."data"::jsonb->>'modelConnectionId',
    connection."providerId",
    selection."data"::jsonb->>'modelId',
    COALESCE(selection."data"::jsonb->>'modelName', selection."data"::jsonb->>'modelId'),
    selection."revision",
    selection."createdAt",
    selection."updatedAt",
    selection."deletedAt"
FROM "workspace_resource" AS selection
JOIN "workspace_model_connection" AS connection
  ON connection."workspaceId" = selection."workspaceId"
 AND connection."connectionId" = selection."data"::jsonb->>'modelConnectionId'
WHERE selection."resourceKind" = 'modelSelection'
  AND selection."data"::jsonb->>'modelId' IS NOT NULL
ON CONFLICT ("workspaceId", "selectionId") DO NOTHING;

INSERT INTO "api_model" (
    "providerId", "modelId", "name", "createdAt", "updatedAt"
)
SELECT DISTINCT
    selection."providerId",
    selection."modelId",
    selection."modelName",
    selection."createdAt",
    selection."updatedAt"
FROM "workspace_model_selection" AS selection
ON CONFLICT ("providerId", "modelId") DO NOTHING;

DELETE FROM "workspace_resource"
WHERE "resourceKind" IN ('modelConnection', 'model', 'modelSelection');


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260714024402061', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260714024402061', "timestamp" = now();

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
