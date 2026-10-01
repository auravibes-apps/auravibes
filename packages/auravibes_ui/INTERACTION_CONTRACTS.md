# Aura interaction contracts

Read when changing AuraPressable, state layers, or underline tabs.

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
- tab target: use `context.auraTheme.interactionSizes.minimumTargetSize`,
  including horizontal padding; default is 48px and the theme enforces a 48px
  floor;
- tab strip: one 1px divider below the full strip, with no per-tab border;
- state-layer radius: `AuraBorderRadius.md` (6px); do not make the underline a
  filled pill or let the state background span the whole strip.

An inactive tab may be hovered while another tab remains selected. Hover must
not change content or selected semantics. Keyboard focus and activation must
remain visible and usable. Widgetbook coverage and focused widget tests should
include that mixed state, tab target size, indicator width, content selection,
and `SemanticsRole.tab`/selected values. Render the story before completion so
the visual result is checked, not inferred from widget names.
