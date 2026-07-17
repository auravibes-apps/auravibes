BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "api_model" CASCADE;

--
-- ACTION CREATE TABLE
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
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260714134039604', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260714134039604', "timestamp" = now();

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
