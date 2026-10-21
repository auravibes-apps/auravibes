# Group 34: Management feedback and workspace search

## Goal

Make every failed bulk-delete target inspectable and retryable, and define one deterministic international search-folding policy for workspace names.

## Scope

- After partial workspace, tool, or skill deletion, show every failed target in an accessible dialog.
- Keep failures selected and offer retry for only the currently failed targets. Update the dialog and selected set after each retry.
- Preserve existing successful-deletion behavior.
- Normalize query and workspace name with Unicode NFKD, remove all Unicode marks, then use Dart's locale-independent lowercase mapping before substring matching.
- Pin expansion and locale-sensitive behavior: lowercase mapping does not perform full multi-character case-fold expansion, so `ß` does not equal `ss`; dotted capital `İ` folds to `i` after mark removal; dotless `ı` remains distinct from `i`.

## Acceptance criteria

- Three or more failures are fully readable; retry targets only failed IDs, including after repeated partial retries.
- Failure dialogs expose accessible names and clear Close/Retry actions.
- Workspace search remains case-insensitive substring matching and treats canonical/decomposed accents alike across Latin and non-Latin scripts.
- Tests pin NFKD compatibility forms, combining marks, dotted/dotless I, and the documented `ß`/`ss` behavior.

## Verification

Focused workspace/tool/skill management widget tests cover partial failure and retry. Search unit/widget tests cover the documented normalization matrix across local, mirrored, and cloud workspaces.
