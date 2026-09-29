# Fix: Fade horizontal scroll edges to reveal overflow

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/shader-mask
- **Needs new dependency**: none

## Why

Horizontal controls and catalog content can fit flush against the viewport and provide no visual clue that more content exists off-screen.

## Where

`packages/auravibes_ui/lib/src/molecules/aura_tabs.dart:239-251`

```dart
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

`apps/auravibes_app/lib/features/markdown/widgets/markdown_editor_toolbar.dart:13-17`

```dart
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: _ToolbarActions(toolbar: this),
    );
```

`apps/auravibes_app/lib/features/agents/screens/agent_detail_screen.dart:2785-2794`

```dart
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: .horizontal,
    child: AuraButtonGroup<AgentToolPermissionMode>.single(
      items: _agentToolPermissionItems,
      selectedValue: value,
      onChanged: onChanged,
      size: .sm,
    ),
  );
```

The same issue also exists in reusable content widgets:

- `packages/auravibes_ui/lib/src/atoms/aura_code_block.dart` — horizontally scrollable code.
- `packages/auravibes_ui/lib/src/organisms/aura_table.dart` — horizontally scrollable tables.
- `apps/auravibes_app/lib/features/chats/agent_adapters/aura_chat_catalog_adapter.dart` — `AuraList` when its catalog direction is horizontal.

## The fix

Add and export the article's reusable edge-fade widget in `auravibes_ui`, named `AuraEdgy` to match this package's public API convention:

```dart
class AuraEdgy extends StatelessWidget {
  const AuraEdgy({
    required this.child,
    this.axis = Axis.vertical,
    this.fadeStart = true,
    this.fadeEnd = true,
    super.key,
  });

  final Widget child;
  final Axis axis;
  final bool fadeStart;
  final bool fadeEnd;

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
        end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
        colors: [
          fadeStart ? const Color(0x00FFFFFF) : const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
          fadeEnd ? const Color(0x00FFFFFF) : const Color(0xFFFFFFFF),
        ],
        stops: const [0, 0.12, 0.88, 1],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
```

Export `AuraEdgy` from the package barrel. Wrap each listed horizontal scroller and the three reusable horizontal content cases with `AuraEdgy(axis: Axis.horizontal, child: ...)`, leaving both article-default fades enabled. Wrap the dynamic `AuraList` only when its direction is horizontal. Do not add controllers or scroll listeners; those are not part of the article's fix. Do not mask vertical content.

## Steps

1. Add/export `AuraEdgy` and focused UI-package tests for vertical, horizontal, and one-sided masks.
2. Apply it to tabs, Markdown toolbar, agent permission selector, code blocks, tables, and horizontal catalog lists.
3. Test focused package/app surfaces; verify light/dark readability and overlays where those screens are available.

## Check it

```sh
cd packages/auravibes_ui && fvm flutter test --no-pub test/src/atoms/aura_edgy_test.dart test/src/atoms/aura_code_block_test.dart test/src/molecules/auravibes_tabs_test.dart
cd ../../apps/auravibes_app && fvm flutter test --no-pub test/features/markdown/screens/markdown_editor_screen_test.dart test/features/agents/screens/agent_detail_screen_test.dart test/features/chats/agent_adapters/aura_chat_catalog_adapter_test.dart test/features/chats/agent_adapters/aura_dashboard_catalog_adapter_test.dart
```

## Don't touch

- Vertical lists.
- Tab selection behavior; the visibility plan handles auto-scrolling.
- Control spacing or labels.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The mask clips focus rings or popup overlays. Move the mask to the scroll viewport only, not the control subtree's overlay host.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report visual-check limitations and all wrapped horizontal surfaces.

## Attempt log

- 2026-09-28: Added/exported `AuraEdgy`; applied it to the six horizontal surfaces above. Focused analysis passed. UI-package tests passed (26); app surface tests passed (51).
- Visual check remains unverified: the isolated dev app launched and Marionette fixture-seeding succeeded, but the available route showed New Chat rather than the tab, Markdown toolbar, agent-permission, code-block, table, or horizontal catalog-list surfaces. Screenshot was not used as evidence for those surfaces.
