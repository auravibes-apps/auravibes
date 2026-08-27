# AuraVibes UI Agent Instructions

## Scope

- Applies to `packages/auravibes_ui`.
- Root-run agents must load `.agents/skills/package-architecture/SKILL.md`; it is the package architecture source of truth.
- Read `STYLE_GUIDE.md` before modifying UI components.
- This package must stay domain-agnostic and reusable across projects.

## Const-First Components

- Prefer const-compatible parameters.
- Use `AuraTint` instead of `Color?` for component accent parameters.
- Only children, title widgets, and dropdown lists may be variable parameters.
- Maximize compile-time constants through enums.
- Resolve enum colors inside `build` with `context.auraColors.colorFor`.

`AuraPressable.color` is a deliberate low-level exception. It is the base,
resolved color for its interaction layer, not a background-color parameter.
Pass an opaque theme color. The primitive applies fixed 8% hover/focus and 16%
pressed layers; put a component's persistent background in `decoration`.

## Interactive State and Visual Validation

Treat interaction states as part of the component contract, not as incidental
Flutter defaults. Before changing an interactive widget, inspect the Aura
primitive implementation and every caller. A caller that passes an already
transparent color can double-apply opacity or make a state invisible when the
primitive owns the state layer.

For underline tabs, preserve this hierarchy and geometry:

- accept tab titles as widgets so callers can compose text, icons, or other Aura
  content; provide an explicit semantic label when a title widget has no useful
  semantics;
- inactive: transparent state layer and regular foreground text;
- hover/focus: an 8% state layer limited to the tab hit target;
- pressed: a 16% state layer limited to the tab hit target;
- selected: persistent primary text plus a 2px primary indicator;
- tab target: at least 48px high (`AuraSpacing.xl2`), including horizontal
  padding;
- tab strip: one 1px divider below the full strip, with no per-tab border;
- state-layer radius: `AuraBorderRadius.md` (6px); do not make the underline a
  filled pill or let the state background span the whole strip.

An inactive tab may be hovered while another tab remains selected. Hover must
not change content or selected semantics. Keyboard focus and activation must
remain visible and usable. Widgetbook coverage and focused widget tests should
include that mixed state, tab target size, indicator width, content selection,
and `SemanticsRole.tab`/selected values. Render the story before completion so
the visual result is checked, not inferred from widget names.

## Component Changes

- Match existing atom/molecule patterns before adding new APIs.
- Do not add business-specific names, copy, localization keys, or app feature logic.
- Keep public API additions minimal and backed by tests when behavior changes.
- Do not add unique UI package architecture rules here; update the root skill instead.
