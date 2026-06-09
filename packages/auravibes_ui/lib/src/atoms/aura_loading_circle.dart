// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// ignore_for_file: avoid-returning-widgets
// Required: Existing helper builders return widgets.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-extracting-callbacks
// Required: Component callbacks stay colocated with UI state.

import 'dart:async';
import 'dart:math' as math show pi, sin;

import 'package:auravibes_ui/src/tokens/aura_theme.dart';
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

/// Loading Widget.
class AuraLoadingCircle extends StatefulWidget {
  /// Constructor.
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

    unawaited(controller.repeat());
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
    final itemSize = widget.itemSize ?? widget.size * 0.15;
    final itemCount = widget.itemCount ?? 12;

    return Center(
      child: SizedBox.fromSize(
        child: Stack(
          children: List.generate(itemCount, (i) {
            final position = widget.size * 0.5;

            return Positioned.fill(
              left: position,
              top: position,
              child: Transform(
                transform: Matrix4.rotationZ((360 / itemCount) * i * 0.0174533),
                child: Align(
                  child: FadeTransition(
                    opacity: _DelayTween(
                      delay: i / itemCount,
                      begin: 0,
                      end: 1,
                    ).animate(_requiredController),
                    child: SizedBox.fromSize(
                      child: _itemBuilder(i),
                      size: Size.square(itemSize),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        size: Size.square(widget.size),
      ),
    );
  }

  Widget _itemBuilder(int index) {
    final itemBuilder = widget.itemBuilder;
    if (itemBuilder != null) {
      return itemBuilder(context, index);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            context.auraColors.getColorOrNull(widget.colorVariant) ??
            context.auraColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
