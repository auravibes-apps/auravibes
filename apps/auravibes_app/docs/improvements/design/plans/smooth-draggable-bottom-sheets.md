# Fix: Give the small agent-visibility sheet spring drag motion

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/smooth-draggable-bottom-sheets
- **Needs new dependency**: none

## Why

The compact agent-visibility picker is three options plus one Done button, but opens through `showModalBottomSheet` with Material's mechanical route animation. Its `SingleChildScrollView` is unnecessary for this bounded content and prevents the article's drag route from owning the gesture.

## Where

`apps/auravibes_app/lib/features/agents/screens/agents_screen.dart:838-854`

```dart
  Future<void> _openSheet() async {
    if (_isSaving) return;

    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await _showSheet();
    if (!mounted || selected == null || selected == widget.value) return;

    await _save(selected);
  }

  Future<AgentVisibility?> _showSheet() =>
      showModalBottomSheet<AgentVisibility>(
        context: context,
        builder: (context) => _AgentVisibilitySheet(value: widget.value),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useSafeArea: true,
      );
```

`apps/auravibes_app/lib/features/agents/screens/agents_screen.dart:1001-1022`

```dart
class const _AgentVisibilitySheetContent({
  required final AgentVisibility selectedValue,
  required final ValueChanged<List<AgentVisibility>> onChanged,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => SingleChildScrollView(
    child: AuraColumn(
      children: [
        const _AgentVisibilitySheetTitle(),
        const AuraSizedBox(height: .md),
        _AgentVisibilitySheetPicker(
          selectedValue: selectedValue,
          onChanged: onChanged,
        ),
        const AuraSizedBox(height: .md),
        _AgentVisibilitySheetDoneButton(onPressed: onDone),
      ],
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
    ),
  );
```

`apps/auravibes_app/lib/features/agents/screens/agents_screen.dart:964-999`

```dart
class const _AgentVisibilitySheetSurface({
  required final AgentVisibility selectedValue,
  required final ValueChanged<List<AgentVisibility>> onChanged,
  required final VoidCallback onDone,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AgentVisibilitySheetFrame(
    maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    color: context.auraColors.surface,
    borderRadius: .vertical(
      top: .circular(context.auraTheme.fromBorderRadius(.xl)),
    ),
    child: _AgentVisibilitySheetContent(
      selectedValue: selectedValue,
      onChanged: onChanged,
      onDone: onDone,
    ),
  );
}

class const _AgentVisibilitySheetFrame({
  required final double maxHeight,
  required final Color color,
  required final BorderRadius borderRadius,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => ConstrainedBox(
    constraints: .new(maxHeight: maxHeight),
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: child,
    ),
  );
}
```

The other bottom sheets contain genuine `ListView`/scrolling forms (`active_sub_agent_status_widget.dart:269`, `chat_reasoning_control.dart:195`, and selector content under `chat_input_widget.dart:928`) and are explicitly out of scope.

## The fix

Add `lib/widgets/sheets/spring_bottom_sheet.dart` with the article's complete route below. Its exact motion values are enter spring mass `1`, stiffness `438.6`, damping `41.9`; exit spring mass `1`, stiffness `987.0`, damping `62.8`; overdrag resistance `100`; close velocity `0.9` sheet heights/second; close position `0.5`; enter duration `300ms`; exit duration `200ms`; and barrier `0x8A000000`. The only visual adaptation is Aura's surface color and `.xl` top radius.

```dart
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Shows a modal sheet anchored to the bottom edge of the screen.
///
/// A spring-driven replacement for showModalBottomSheet. The sheet enters
/// and exits on smooth springs, and dragging it drives the route animation
/// directly, so the velocity of a released fling is carried into the open
/// or close spring.
///
/// The sheet surface comes from [_SpringSheetContainer]; the widget returned by
/// [builder] brings only its content and padding.
///
/// Returns a [Future] that resolves to the value passed to [Navigator.pop]
/// when the sheet is closed.
Future<T?> showSpringBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return Navigator.of(context).push(
    _SpringSheetRoute<T>(
      builder: builder,
    ),
  );
}

/// A route that shows a spring-driven modal sheet at the bottom of the
/// screen.
class _SpringSheetRoute<T> extends PopupRoute<T> {
  _SpringSheetRoute({
    required this.builder,
    super.settings,
  });

  /// Builds the content of the sheet.
  final WidgetBuilder builder;

  // SwiftUI's .smooth spring written out as plain numbers: critically
  // damped, stiffness 4pi^2 / duration^2, at 300ms in and 200ms out.
  static const SpringDescription _enterSpring = SpringDescription(
    mass: 1,
    stiffness: 438.6,
    damping: 41.9,
  );
  static const SpringDescription _exitSpring = SpringDescription(
    mass: 1,
    stiffness: 987.0,
    damping: 62.8,
  );

  // Resistance applied when dragging past fully open.
  static const double _overdragResistance = 100;

  // Thresholds past which a released drag closes the sheet: fling speed in
  // sheet heights per second, or resting position as a fraction of height.
  static const double _closeVelocity = 0.9;
  static const double _closePosition = 0.5;

  // Release velocity in sheet heights per second (positive is downward),
  // carried from the drag into the close simulation.
  double? _releaseVelocity;

  bool _popped = false;

  @override
  Color? get barrierColor => const Color(0x8A000000);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  // The scrim fades with the clamped animation so that dragging past fully
  // open does not push the barrier curve out of range. The slide reads the
  // raw controller.
  @override
  Animation<double>? get animation {
    final Animation<double>? raw = super.animation;
    if (raw == null) return null;

    return _ClampedAnimation(raw);
  }

  @override
  AnimationController createAnimationController() {
    return AnimationController.unbounded(
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      vsync: navigator!,
    );
  }

  @override
  Simulation? createSimulation({required bool forward}) {
    final double velocity = _releaseVelocity ?? 0;
    _releaseVelocity = null;

    return SpringSimulation(
      forward ? _enterSpring : _exitSpring,
      controller?.value ?? 0,
      forward ? 1 : 0,
      -velocity,
      snapToEnd: true,
    );
  }

  @override
  bool didPop(T? result) {
    _popped = true;

    return super.didPop(result);
  }

  void _dragBy(double relativeDelta) {
    if (_popped) return;

    final AnimationController controller = this.controller!;

    double delta = relativeDelta;
    if (controller.value > 1) {
      final double overshoot = controller.value - 1;
      delta *= 1 / (1 + overshoot * _overdragResistance);
    }
    controller.value -= delta;
  }

  void _endDrag(double relativeVelocity) {
    if (_popped) return;
    final AnimationController controller = this.controller!;
    final double value = controller.value;

    if (value > 1) {
      // Dragged past fully open. Settle back, damping the velocity by the
      // same resistance that was applied while dragging.
      final double overshoot = value - 1;
      final double damped =
          relativeVelocity / (1 + overshoot * _overdragResistance);
      controller.animateWith(
        SpringSimulation(_enterSpring, value, 1, -damped, snapToEnd: true),
      );

      return;
    }

    final bool close = switch (relativeVelocity) {
      > _closeVelocity => true,
      < -_closeVelocity => false,
      _ => value < _closePosition,
    };

    if (close) {
      _releaseVelocity = relativeVelocity;
      navigator?.pop();
    } else {
      controller.animateWith(
        SpringSimulation(
          _enterSpring,
          value,
          1,
          -relativeVelocity,
          snapToEnd: true,
        ),
      );
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: controller!,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset(0, 1 - controller!.value),
            child: child,
          );
        },
        child: Builder(
          builder: (context) {
            // Drag deltas are normalized by the sheet's own height, so the
            // gesture and the route animation share one coordinate space.
            double height() => context.size?.height ?? 1;

            return GestureDetector(
              excludeFromSemantics: true,
              onVerticalDragUpdate: (details) {
                _dragBy(details.primaryDelta! / height());
              },
              onVerticalDragEnd: (details) {
                _endDrag(details.velocity.pixelsPerSecond.dy / height());
              },
              onVerticalDragCancel: () {
                _endDrag(0);
              },
              child: SizedBox(
                width: double.infinity,
                child: _SpringSheetContainer(
                  child: builder(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Aura surface for sheets shown with [showSpringBottomSheet].
class _SpringSheetContainer extends StatelessWidget {
  const _SpringSheetContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: .transparency,
      child: ClipRRect(
        borderRadius: .vertical(
          top: .circular(context.auraTheme.fromBorderRadius(.xl)),
        ),
        child: ColoredBox(
          color: context.auraColors.surface,
          child: child,
        ),
      ),
    );
  }
}

/// An animation that forwards [parent] with its value clamped to the range
/// 0.0 to 1.0, for consumers such as the modal barrier that should not see
/// values past fully open.
class _ClampedAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _ClampedAnimation(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value => parent.value.clamp(0.0, 1.0);
}
```

Replace `_showSheet()` with:

```dart
Future<AgentVisibility?> _showSheet() =>
    showSpringBottomSheet<AgentVisibility>(
      context: context,
      builder: (context) => _AgentVisibilitySheet(value: widget.value),
    );
```

Replace `_AgentVisibilitySheetSurface.build` and delete `_AgentVisibilitySheetFrame`:

```dart
@override
Widget build(BuildContext context) => ConstrainedBox(
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.75,
  ),
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: _AgentVisibilitySheetContent(
      selectedValue: selectedValue,
      onChanged: onChanged,
      onDone: onDone,
    ),
  ),
);
```

Remove only the `SingleChildScrollView` wrapper from `_AgentVisibilitySheetContent`; keep the existing `AuraColumn(mainAxisSize: .min)` as the route's non-scrolling content. The `0.75` maximum height remains a safety constraint. If this bounded content overflows at a supported size, STOP instead of inserting a scrollable that would steal the article's drag gesture.

## Steps

1. Add the route/helper under `lib/widgets/sheets/` with route-level tests.
2. Convert agent visibility and remove its unnecessary inner scroll view.
3. Test slow drag, fast fling, cancelled drag, overdrag settle, barrier/back dismissal, and result propagation at the literal thresholds above.
4. Leave all three genuinely scrollable sheets unchanged.

## Check it

```sh
fvm flutter test test/widgets/sheets test/features/agents/screens/agents_screen_test.dart --no-pub
fvm dart analyze apps/auravibes_app --fatal-infos --fatal-warnings --format=machine
```

## Don't touch

- Scrollable selector/reasoning/sub-agent sheets.
- Visibility persistence logic.
- Full-screen Markdown editor route.

- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- Visibility content overflows at supported text scale or landscape height without scrolling. Keep Material's scrollable sheet for that size class; do not nest a scrollable inside the spring drag route.

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Report drag/velocity/overdrag tests and confirm excluded sheets stayed unchanged.

## Attempt log

- 2026-09-28: The implementation was already present: `_showSheet` uses `showSpringBottomSheet`, the visibility content is non-scrolling, and the spring route plus route tests exist. All three quoted pre-fix locations in "Where" have therefore moved on; per the plan's STOP clause, no source changes made. `fvm flutter test test/widgets/sheets test/features/agents/screens/agents_screen_test.dart --no-pub` passed all 17 tests, covering return values, slow drag thresholds, fling direction, cancelled drag, overdrag, barrier/back dismissal, and visibility integration. The app fatal analyzer exited 1 with INFO diagnostics only in the separate friendly-error widget and test; no diagnostics in the sheet or agent screen. Landscape/high-text-scale overflow remains unverified.
