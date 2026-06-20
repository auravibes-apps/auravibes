# AuraVibes UI Agent Instructions

## Scope

- Applies to `packages/auravibes_ui`.
- Read `STYLE_GUIDE.md` before modifying UI components.
- This package must stay domain-agnostic and reusable across projects.

## Const-First Components

- Prefer const-compatible parameters.
- Use `AuraColorVariant` instead of `Color?` for component color parameters.
- Only children and dropdown lists may be variable parameters.
- Maximize compile-time constants through enums.
- Resolve enum colors inside `build` with `context.auraColors`.

## Component Changes

- Match existing atom/molecule patterns before adding new APIs.
- Do not add business-specific names, copy, localization keys, or app feature logic.
- Keep public API additions minimal and backed by tests when behavior changes.
