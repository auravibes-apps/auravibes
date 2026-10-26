-- Apply to the gateway's dedicated PostgreSQL database before startup.
CREATE SCHEMA object_gateway;
CREATE TABLE object_gateway.keys (
  key_hash bytea PRIMARY KEY,
  registration_hash bytea NOT NULL,
  closed boolean NOT NULL DEFAULT false
);
CREATE TABLE object_gateway.uploads (
  nonce_hash bytea PRIMARY KEY,
  key_hash bytea NOT NULL REFERENCES object_gateway.keys(key_hash),
  pending boolean NOT NULL DEFAULT true
);
CREATE INDEX object_gateway_pending_uploads ON object_gateway.uploads(key_hash) WHERE pending;
