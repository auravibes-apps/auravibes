# Fix: Scroll the selected Aura tab fully into view

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/tab-visibility
- **Needs new dependency**: none

## Why

`_AuraTabBar` is stateless and horizontally scrollable, but selected-index changes never move the viewport. A tapped or programmatically selected edge tab can remain clipped.

## Where

`packages/auravibes_ui/lib/src/molecules/aura_tabs.dart:129-151`

```dart
      return _AuraTabBar(
        titles: [for (final option in options) option.title],
        semanticLabels: [for (final option in options) option.semanticLabel],
        selectedIndex: _selectedOptionIndex(options),
        onChanged: onChanged,
      );
    }

    if (widget.items.isEmpty) return const SizedBox.shrink();

    final selectedIndex = _normalizeIndex(
      widget.selectedIndex ?? _selectedIndex,
      widget.items.length,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AuraTabBar(
          titles: [for (final item in widget.items) item.title],
          semanticLabels: [for (final item in widget.items) item.semanticLabel],
          selectedIndex: selectedIndex,
          onChanged: onChanged,
```

`packages/auravibes_ui/lib/src/molecules/aura_tabs.dart:147-152`

```dart
        _AuraTabBar(
          titles: [for (final item in widget.items) item.title],
          semanticLabels: [for (final item in widget.items) item.semanticLabel],
          selectedIndex: selectedIndex,
          onChanged: onChanged,
        ),
```

`packages/auravibes_ui/lib/src/molecules/aura_tabs.dart:231-251`

```dart
class const _AuraTabBar({
  required final List<Widget> titles,
  required final List<String?> semanticLabels,
  required final int selectedIndex,
  final ValueChanged<int>? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < titles.length; index++)
                _buildTab(context, index),
            ],
          ),
        ),
```

## The fix

Convert `_AuraTabBar` to a stateful widget. Maintain one `GlobalKey` per tab, resized when tab count changes. After first layout and whenever `selectedIndex` changes, call:

```dart
Scrollable.ensureVisible(
  selectedContext,
  alignment: 0.5,
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeInOut,
);
```

Schedule with `addPostFrameCallback`; guard `mounted`, index bounds, absent context, and `TickerMode` (use zero duration when disabled). Attach each key to the tab's outer semantic/render object. Do not call during every build.

## Steps

1. Add key lifecycle and `_revealSelectedTab` in `_AuraTabBarState`.
2. Trigger after `initState`, selected-index changes in `didUpdateWidget`, and tab-count changes.
3. Ensure user taps and controlled programmatic changes follow the same path.
4. Add tests for initially selected last tab, tap to clipped tab, controlled update, list shrink, RTL, and no-scroll-needed case.

## Check it

```sh
cd packages/auravibes_ui && fvm flutter test test/src/molecules/aura_tabs_test.dart --no-pub
```

## Don't touch

- Public `AuraTabs` API.
- Tab content state.
- Edge fade colors; that is the shader-mask plan.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## Attempt log

- 2026-09-28: STOP condition reached because `_AuraTabBar` is already stateful
  and has per-tab keys plus post-layout reveal logic; the plan's stateless
  excerpt is stale. It targets the nearest horizontal `ScrollPosition` rather
  than bubbling through ancestor scrollables. The current test filename is
  `auravibes_tabs_test.dart` (the plan path is stale); all 22 tests passed,
  covering initial edge selection, clipped-tab tap, controlled selection,
  list shrink in RTL, and no-scroll-needed behavior. No source change made.

## STOP if

- `ensureVisible` scrolls an ancestor page instead of only the horizontal tab viewport. Add a dedicated horizontal controller and calculate its target offset rather than accepting cross-axis movement.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report initial/tap/programmatic/RTL test results.
