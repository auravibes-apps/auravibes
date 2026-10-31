BEGIN;

CREATE SCHEMA IF NOT EXISTS object_gateway;

CREATE TABLE IF NOT EXISTS object_gateway.keys (
  key_hash bytea PRIMARY KEY,
  registration_hash bytea NOT NULL,
  closed boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS object_gateway.uploads (
  nonce_hash bytea PRIMARY KEY,
  key_hash bytea NOT NULL REFERENCES object_gateway.keys(key_hash),
  pending boolean NOT NULL DEFAULT true
);

CREATE INDEX IF NOT EXISTS object_gateway_pending_uploads
  ON object_gateway.uploads(key_hash) WHERE pending;

--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20261029124845281-object-gateway', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261029124845281-object-gateway', "timestamp" = now();

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
