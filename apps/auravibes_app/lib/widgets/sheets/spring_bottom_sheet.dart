import 'package:auravibes_ui/ui.dart';
import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a modal sheet anchored to the bottom edge of the screen.
Future<T?> showSpringBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => Navigator.of(context).push(_SpringBottomSheet<T>(builder: builder));

class _SpringBottomSheet<T>({required final WidgetBuilder builder})
    extends PopupRoute<T> {
  static const SpringDescription _enterSpring = .new(
    mass: 1,
    stiffness: 438.6,
    damping: 41.9,
  );
  static const SpringDescription _exitSpring = .new(
    mass: 1,
    stiffness: 987,
    damping: 62.8,
  );
  static const double _overdragResistance = 100;
  static const double _closeVelocity = 0.9;
  static const double _closePosition = 0.5;

  double? _releaseVelocity;
  bool _popped = false;
  final GlobalKey _sheetKey = .new();

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

  @override
  Animation<double>? get animation {
    final raw = super.animation;
    if (raw == null) return null;

    return _ClampedAnimation(raw);
  }

  double get _sheetHeight {
    final renderObject = _sheetKey.currentContext?.findRenderObject();

    return renderObject is RenderBox && renderObject.hasSize
        ? renderObject.size.height
        : 1;
  }

  @override
  AnimationController createAnimationController() => switch (navigator) {
    final navigator? => AnimationController.unbounded(
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      vsync: navigator,
    ),
    _ => throw StateError(
      'Spring sheet route must be installed before animation creation.',
    ),
  };

  @override
  Simulation createSimulation({required bool forward}) {
    final velocity = _releaseVelocity ?? 0;
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

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controller = this.controller;
    if (controller == null) return const SizedBox.shrink();

    return Align(
      alignment: .bottomCenter,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => FractionalTranslation(
          translation: .new(0, 1 - controller.value),
          child: child,
        ),
        child: Builder(
          builder: (context) => GestureDetector(
            child: SizedBox(
              key: _sheetKey,
              width: .infinity,
              child: _SpringSheetContainer(child: builder(context)),
            ),
            onVerticalDragUpdate: (details) =>
                _dragBy(details.delta.dy / _sheetHeight),
            onVerticalDragEnd: (details) =>
                _endDrag(details.velocity.pixelsPerSecond.dy / _sheetHeight),
            onVerticalDragCancel: () => _endDrag(0),
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }

  void _dragBy(double relativeDelta) {
    final controller = this.controller;
    if (_popped || controller == null) return;

    var delta = relativeDelta;
    if (controller.value > 1) {
      final overshoot = controller.value - 1;
      delta *= 1 / (1 + overshoot * _overdragResistance);
    }
    controller.value -= delta;
  }

  void _endDrag(double relativeVelocity) {
    final controller = this.controller;
    if (_popped || controller == null) return;
    final value = controller.value;

    if (value > 1) {
      final overshoot = value - 1;
      final damped = relativeVelocity / (1 + overshoot * _overdragResistance);
      final _ = controller.animateWith(
        SpringSimulation(_enterSpring, value, 1, -damped, snapToEnd: true),
      );

      return;
    }

    final close = switch (relativeVelocity) {
      > _closeVelocity => true,
      < -_closeVelocity => false,
      _ => value < _closePosition,
    };

    if (close) {
      _releaseVelocity = relativeVelocity;
      navigator?.pop();
    } else {
      final _ = controller.animateWith(
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
}

class const _SpringSheetContainer({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    type: .transparency,
    child: ClipRRect(
      borderRadius: .vertical(
        top: .circular(context.auraTheme.fromBorderRadius(.xl)),
      ),
      child: ColoredBox(color: context.auraColors.surface, child: child),
    ),
  );
}

class _ClampedAnimation(@override final Animation<double> parent)
    extends Animation<double>
    with AnimationWithParentMixin<double> {
  @override
  double get value => parent.value.clamp(0, 1);
}
