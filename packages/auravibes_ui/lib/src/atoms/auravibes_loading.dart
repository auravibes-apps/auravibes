import 'dart:async';
import 'dart:math' as math show pi, sin;

import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

class _DelayTween extends Tween<double> {
  _DelayTween({
    required this.delay,
    required double begin,
    required double end,
  }) : super(begin: begin, end: end);

  final double delay;

  @override
  double lerp(double t) {
    return super.lerp((math.sin((t - delay) * 2 * math.pi) + 1) / 2);
  }

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}

/// Loading Widget
class AuraLoadingCircle extends StatefulWidget {
  /// constructor
  const AuraLoadingCircle({
    required this.colorVariant,
    super.key,
    this.size = 50.0,
    this.itemSize,
    this.itemCount,
    this.itemBuilder,
    this.duration = const Duration(milliseconds: 1200),
    this.controller,
  });

  /// Dot color used by the default item builder.
  ///
  /// Ignored when [itemBuilder] is provided, because custom builders own their
  /// rendering.
  final AuraColorVariant colorVariant;

  /// size
  final double size;

  /// itemSize
  final double? itemSize;

  /// itemCount
  final int? itemCount;

  /// itemBuilder
  final IndexedWidgetBuilder? itemBuilder;

  /// duration
  final Duration duration;

  /// controller
  final AnimationController? controller;

  @override
  State<AuraLoadingCircle> createState() => _AuraLoadingCircleState();
}

class _AuraLoadingCircleState extends State<AuraLoadingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        widget.controller ??
        AnimationController(vsync: this, duration: widget.duration);

    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemSize = widget.itemSize ?? widget.size * 0.15;
    final itemCount = widget.itemCount ?? 12;

    return Center(
      child: SizedBox.fromSize(
        size: Size.square(widget.size),
        child: Stack(
          children: List.generate(itemCount, (i) {
            final position = widget.size * .5;
            return Positioned.fill(
              left: position,
              top: position,
              child: Transform(
                transform: Matrix4.rotationZ((360 / itemCount) * i * 0.0174533),
                child: Align(
                  child: FadeTransition(
                    opacity: _DelayTween(
                      begin: 0,
                      end: 1,
                      delay: i / itemCount,
                    ).animate(_controller),
                    child: SizedBox.fromSize(
                      size: Size.square(itemSize),
                      child: _itemBuilder(i),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _itemBuilder(int index) => widget.itemBuilder != null
      ? widget.itemBuilder!(context, index)
      : DecoratedBox(
          decoration: BoxDecoration(
            color: context.auraColors.getColor(widget.colorVariant),
            shape: BoxShape.circle,
          ),
        );
}
