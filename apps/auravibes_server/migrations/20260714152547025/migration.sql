BEGIN;

-- Convert persisted conversation references before removing selection rows.
UPDATE "conversation_message" AS message
SET
    "metadataJson" = jsonb_set(
        message."metadataJson"::jsonb,
        '{modelSelectionId}',
        to_jsonb(
            'wms1.' ||
            translate(
                rtrim(
                    encode(
                        convert_to(selection."connectionId", 'UTF8'),
                        'base64'
                    ),
                    '='
                ),
                '+/', '-_'
            ) ||
            '.' ||
            translate(
                rtrim(
                    encode(
                        convert_to(selection."modelId", 'UTF8'),
                        'base64'
                    ),
                    '='
                ),
                '+/', '-_'
            )
        ),
        true
    )::text,
    "updatedAt" = now()
FROM "workspace_model_selection" AS selection
WHERE selection."workspaceId" = message."workspaceId"
  AND message."metadataJson" IS NOT NULL
  AND message."metadataJson"::jsonb->>'modelSelectionId' = selection."selectionId";

--
-- ACTION DROP TABLE
--
DROP TABLE "workspace_model_selection" CASCADE;


--
-- MIGRATION VERSION FOR auravibes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('auravibes', '20260714152547025', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260714152547025', "timestamp" = now();

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
