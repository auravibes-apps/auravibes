// Required: Existing test and UI helpers keep compact return flow.
// Required: Component callbacks stay colocated with UI state.

import 'dart:math' as math show pi, sin;

import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

class _DelayTween({
  required final double delay,
  required double begin,
  required double end,
}) extends Tween<double> {
  static const _fullTurn = 2.0;
  this : super(begin: begin, end: end);

  @override
  double lerp(double t) {
    return super.lerp(
      (math.sin((t - delay) * _fullTurn * math.pi) + 1) / _fullTurn,
    );
  }

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}

/// Loading Widget.
class AuraLoadingCircle extends StatefulWidget {
  /// Constructor.
  const new({
    required this.tint,
    super.key,
    this.size = 50.0,
    this.itemSize,
    this.itemCount,
    this.itemBuilder,
    this.duration = const Duration(milliseconds: 1200),
    this.controller,
  });

  /// Compact loading indicator for inline controls.
  const new compact({
    required this.tint,
    super.key,
    this.duration = const Duration(milliseconds: 1200),
    this.controller,
  }) : size = 20.0,
       itemSize = null,
       itemCount = null,
       itemBuilder = null;

  /// Dot color used by the default item builder.
  ///
  /// Ignored when [itemBuilder] is provided, because custom builders own their
  /// rendering.
  final AuraTint tint;

  /// Size.
  final double size;

  /// ItemSize.
  final double? itemSize;

  /// ItemCount.
  final int? itemCount;

  /// ItemBuilder.
  final IndexedWidgetBuilder? itemBuilder;

  /// Duration.
  final Duration duration;

  /// Controller.
  final AnimationController? controller;

  @override
  State<AuraLoadingCircle> createState() => _AuraLoadingCircleState();
}

class _AuraLoadingCircleState extends State<AuraLoadingCircle>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  AnimationController get _requiredController {
    final controller = _controller;
    if (controller == null) {
      throw StateError('_controller is not initialized');
    }

    return controller;
  }

  @override
  void initState() {
    super.initState();

    final controller =
        widget.controller ??
        AnimationController(duration: widget.duration, vsync: this);
    _controller = controller;

    final _ = controller.repeat();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LoadingCircleLayout(
      circle: widget,
      controller: _requiredController,
    );
  }
}

class const _LoadingCircleLayout({
  required final AuraLoadingCircle circle,
  required final AnimationController controller,
}) extends StatelessWidget {
  double get _itemSize => circle.itemSize ?? circle.size * 0.15;

  int get _itemCount => circle.itemCount ?? 12;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.fromSize(
      child: _LoadingCircleStack(
        circle: circle,
        controller: controller,
        itemSize: _itemSize,
        itemCount: _itemCount,
      ),
      size: .square(circle.size),
    ),
  );
}

class const _LoadingCircleStack({
  required final AuraLoadingCircle circle,
  required final AnimationController controller,
  required final double itemSize,
  required final int itemCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: .generate(
      itemCount,
      (i) => _LoadingCircleItem(
        circle: circle,
        index: i,
        itemCount: itemCount,
        itemSize: itemSize,
        controller: controller,
      ),
    ),
  );
}

class const _LoadingCircleItem({
  required final AuraLoadingCircle circle,
  required final int index,
  required final int itemCount,
  required final double itemSize,
  required final AnimationController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final position = circle.size * 0.5;

    return Positioned.fill(
      left: position,
      top: position,
      child: _LoadingCircleItemTransform(item: this),
    );
  }
}

class const _LoadingCircleItemTransform({
  required final _LoadingCircleItem item,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Transform(
    transform: .rotationZ((360 / item.itemCount) * item.index * 0.0174533),
    child: Align(
      child: _LoadingCircleDot(
        index: item.index,
        itemCount: item.itemCount,
        itemSize: item.itemSize,
        itemBuilder: item.circle.itemBuilder,
        tint: item.circle.tint,
        controller: item.controller,
      ),
    ),
  );
}

class const _LoadingCircleDot({
  required final int index,
  required final int itemCount,
  required final double itemSize,
  required final IndexedWidgetBuilder? itemBuilder,
  required final AuraTint tint,
  required final AnimationController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _DelayTween(
      delay: index / itemCount,
      begin: 0,
      end: 1,
    ).animate(controller),
    child: _LoadingCircleDotContent(
      index: index,
      itemSize: itemSize,
      itemBuilder: itemBuilder,
      tint: tint,
    ),
  );
}

class const _LoadingCircleDotContent({
  required final int index,
  required final double itemSize,
  required final IndexedWidgetBuilder? itemBuilder,
  required final AuraTint tint,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    child:
        itemBuilder?.call(context, index) ??
        _LoadingCircleDefaultDot(tint: tint),
    size: .square(itemSize),
  );
}

class const _LoadingCircleDefaultDot({required final AuraTint tint})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.auraColors.colorFor(tint),
      shape: .circle,
    ),
  );
}
