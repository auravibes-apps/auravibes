# AuraVibes Widgetbook Agent Instructions

## Scope

- Applies to `widgetbook`.
- Widgetbook is for Aura UI component exploration and visual regression support.
- Keep examples focused on `auravibes_ui`; do not add app feature logic or app data dependencies.

## Stories

- Add stories under `lib/aura_ui/` for Aura UI components.
- Use `@widgetbook.UseCase` for component examples.
- Use knobs for component inputs that designers or reviewers need to vary.
- Keep callbacks as intentional no-ops unless interaction state is the story being demonstrated.
- Prefer small top-level helpers when they keep a story readable.
- Do not duplicate business-specific copy from the app; use neutral component example text.

## Theme And Generated Files

- Keep Widgetbook themes aligned with `AuraTheme.light` and `AuraTheme.dark`.
- Do not hand-edit `lib/main.directories.g.dart`.
- After adding, renaming, or removing stories, run the Widgetbook generator through the repo generation command: `fvm dart run melos run generate`.

## Verification

- For story-only changes, run `fvm dart run melos run generate` and `git diff --check`.
- If Widgetbook app code changes beyond stories, run the smallest feasible Flutter analyze or build check and report any skipped checks.
