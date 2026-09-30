# Sidebar Selected Semantics

## Goal

Expose the current AuraSidebar destination as selected to screen readers.

## Scope

Pass each navigation item's existing selected state into its interactive semantic node. Preserve the AuraPressable label, enabled/button state, tap callback, focus behavior, keyboard activation, and visual styling. Add focused widget coverage.

## Acceptance criteria

- The selected main or footer item exposes selected=true.
- Every other item exposes selected=false.
- Selection is exposed on the same semantic node that carries the accessible label and tap action.
- Existing labels, pointer activation, focus, and keyboard activation remain available.
- No public API, dependency, or visual behavior changes.

## Assumptions

- AuraSidebar.selectedIndex remains the source of truth; callers update it by rebuilding AuraSidebar.
- Main and footer navigation items share the existing navigation-item implementation.
- AuraPressable remains responsible for button semantics, labels, callbacks, focus, and keyboard activation.
- Related issues #955 and #826 are context only; both are closed and neither blocks this change.
