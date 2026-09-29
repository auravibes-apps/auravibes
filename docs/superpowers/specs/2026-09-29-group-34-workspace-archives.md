# Group 34: Workspace configuration archives

## Goal

Let users review an archive before import, merge an archive repeatedly without duplicates, and export a selected configuration subset with valid references.

## Scope

- Preview archive source, counts by configuration type, and create-vs-target destination before any write.
- Require one explicit confirmation; cancellation performs no writes.
- Merge into existing local and cloud workspaces using stable per-kind identity, updating matches and adding missing entries while preserving unrelated target data.
- Keep import into a new local workspace as a copy operation with remapped IDs.
- Offer configuration-kind selection for export and include the dependency closure required by selected entries.
- Bump the archive writer to version 2 for model-selection sampling policies and selective import support; continue reading version 1 archives.
- Preserve secret exclusion: never export/import keys, tokens, credentials, or secure-storage values.

## Identity and reference rules

- Agent: exact trimmed name within workspace.
- Skill: source plus slug.
- Model connection: provider ID, exact name, and sanitized public URL.
- Native tool: tool ID.
- Skill resource: resolved skill ID plus slug.
- Agent-skill association: resolved agent ID plus source and skill ID.
- Agent-tool permission: resolved agent ID plus tool ID.
- Skill setting: source plus skill ID.
- Compaction setting: workspace singleton.
- Model-selection policy: resolved model-connection ID plus model ID.

Resolve definition identities before remapping relationships. For an existing target, map archive IDs to matched target IDs and allocate IDs only for missing entries. For a new target, allocate all IDs and remap references. Reject ambiguous duplicate natural identities in one archive before writes.

## Acceptance criteria

- Preview shows workspace name, every included kind count, and destination; confirm imports once, cancel writes nothing.
- Re-importing one archive into the same existing local or cloud workspace creates no duplicates, updates matching data, keeps references valid, and preserves unrelated entries.
- A selective archive contains exactly selected entries plus their recursive references; selecting no kinds produces an empty valid archive.
- Version 1 archives still decode; version 2 archives preserve explicit sampling policy.
- Invalid or unsupported targets fail before mutation; secrets remain absent.

## Verification

Codec, local importer/exporter, cloud repository, archive use-case, and management-screen tests cover v1/v2 decode, all identities, repeated import, relationship remapping, closure, empty selection, preview/confirm/cancel, and secret exclusion.
