# AuraVibes UI Agent Instructions
<!-- Managed by agent: AuraVibes | Last updated: 2026-09-11 -->

## Scope

- Applies to `packages/auravibes_ui`.
- Load `.agents/skills/package-architecture/SKILL.md` for package boundary, public API, placement, or architecture changes. Routine edits within an established package can follow nearby code and these scoped rules.
- Read `STYLE_GUIDE.md` before modifying UI components.
- This package must stay domain-agnostic and reusable across projects.

## Const-First Components

- Prefer const-compatible parameters.
- Use `AuraTint` instead of `Color?` for component accent parameters.
- Only children, title widgets, and dropdown lists may be variable parameters.
- Maximize compile-time constants through enums.
- Resolve enum colors inside `build` with `context.auraColors.colorFor`.

## Interactive State

- Check the affected primitive and callers when changing interaction behavior. Preserve accessible targets, keyboard focus, and selection semantics.
- For AuraPressable, state-layer opacity, or underline tabs, read [INTERACTION_CONTRACTS.md](INTERACTION_CONTRACTS.md). Verify the affected interaction visually and with focused behavior checks.

## Component Changes

- Match existing atom/molecule patterns before adding new APIs.
- Do not add business-specific names, copy, localization keys, or app feature logic.
- Keep public API additions minimal and backed by tests when behavior changes.
- Do not add unique UI package architecture rules here; update the root skill instead.
