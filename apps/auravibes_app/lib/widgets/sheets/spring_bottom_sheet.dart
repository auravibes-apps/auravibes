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
  Animation<double>? get animation {
    final raw = super.animation;
    if (raw == null) return null;

    return _ClampedAnimation(raw);
  }

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

    return _SpringSheetPage(
      controller: controller,
      sheetKey: _sheetKey,
      builder: builder,
      onDragUpdate: _dragUpdate(controller),
      onDragEnd: _dragEnd(controller, navigator),
      onDragCancel: _dragCancel(controller, navigator),
    );
  }
}

class _ClampedAnimation(@override final Animation<double> parent)
    extends Animation<double>
    with AnimationWithParentMixin<double> {
  @override
  double get value => parent.value.clamp(0, 1);
}

extension _SpringBottomSheetDrag<T> on _SpringBottomSheet<T> {
  double get _sheetHeight {
    final renderObject = _sheetKey.currentContext?.findRenderObject();

    return renderObject is RenderBox && renderObject.hasSize
        ? renderObject.size.height
        : 1;
  }

  GestureDragUpdateCallback _dragUpdate(AnimationController controller) =>
      (details) => _dragBy(controller, details.delta.dy / _sheetHeight);

  GestureDragEndCallback _dragEnd(
    AnimationController controller,
    NavigatorState? navigator,
  ) =>
      (details) => _endDrag(
        controller,
        navigator,
        details.velocity.pixelsPerSecond.dy / _sheetHeight,
      );

  VoidCallback _dragCancel(
    AnimationController controller,
    NavigatorState? navigator,
  ) =>
      () => _endDrag(controller, navigator, 0);

  void _dragBy(AnimationController controller, double relativeDelta) {
    if (_popped) return;

    var delta = relativeDelta;
    if (controller.value > 1) {
      final overshoot = controller.value - 1;
      delta *= 1 / (1 + overshoot * _SpringBottomSheet._overdragResistance);
    }
    controller.value -= delta;
  }

  void _endDrag(
    AnimationController controller,
    NavigatorState? navigator,
    double relativeVelocity,
  ) {
    if (_popped) return;
    final value = controller.value;

    if (value > 1) {
      _animateBackToOpen(controller, value, relativeVelocity);

      return;
    }

    if (_shouldClose(value, relativeVelocity)) {
      _releaseVelocity = relativeVelocity;
      navigator?.pop();

      return;
    }

    _animateOpen(controller, value, relativeVelocity);
  }

  bool _shouldClose(double value, double velocity) => switch (velocity) {
    > _SpringBottomSheet._closeVelocity => true,
    < -_SpringBottomSheet._closeVelocity => false,
    _ => value < _SpringBottomSheet._closePosition,
  };

  void _animateBackToOpen(
    AnimationController controller,
    double value,
    double velocity,
  ) {
    final overshoot = value - 1;
    final damped =
        velocity / (1 + overshoot * _SpringBottomSheet._overdragResistance);
    final _ = controller.animateWith(
      SpringSimulation(
        _SpringBottomSheet._enterSpring,
        value,
        1,
        -damped,
        snapToEnd: true,
      ),
    );
  }

  void _animateOpen(
    AnimationController controller,
    double value,
    double velocity,
  ) {
    final _ = controller.animateWith(
      SpringSimulation(
        _SpringBottomSheet._enterSpring,
        value,
        1,
        -velocity,
        snapToEnd: true,
      ),
    );
  }
}

class _SpringSheetPage extends StatelessWidget {
  const new({
    required this.controller,
    required this.sheetKey,
    required this.builder,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final AnimationController controller;
  final GlobalKey sheetKey;
  final WidgetBuilder builder;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) => Align(
    alignment: .bottomCenter,
    child: _SpringSheetAnimation(
      controller: controller,
      child: _SpringSheetDragArea(
        sheetKey: sheetKey,
        builder: builder,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        onDragCancel: onDragCancel,
      ),
    ),
  );
}

class const _SpringSheetAnimation({
  required final AnimationController controller,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, child) =>
        _SpringSheetOffset(controller: controller, child: child),
    child: child,
  );
}

class const _SpringSheetOffset({
  required final AnimationController controller,
  required final Widget? child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FractionalTranslation(
    translation: .new(0, 1 - controller.value),
    child: child,
  );
}

class const _SpringSheetDragArea({
  required final GlobalKey sheetKey,
  required final WidgetBuilder builder,
  required final GestureDragUpdateCallback onDragUpdate,
  required final GestureDragEndCallback onDragEnd,
  required final VoidCallback onDragCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: SizedBox(
      key: sheetKey,
      width: .infinity,
      child: _SpringSheetContainer(child: builder(context)),
    ),
    onVerticalDragUpdate: onDragUpdate,
    onVerticalDragEnd: onDragEnd,
    onVerticalDragCancel: onDragCancel,
    excludeFromSemantics: true,
  );
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
