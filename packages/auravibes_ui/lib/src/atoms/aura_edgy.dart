import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/widgets.dart';

/// Fades the start and end edges of scrollable content.
class AuraEdgy extends StatefulWidget {
  static const _transparent = Color(0x00FFFFFF);
  static const _opaque = Color(0xFFFFFFFF);
  static const _stops = [0.0, 0.12, 0.88, 1.0];

  /// Creates a widget that fades the scrollable content's edges.
  const new({
    required this.child,
    this.axis = Axis.vertical,
    this.fadeStart = true,
    this.fadeEnd = true,
    this.allowMouseDrag = false,
    super.key,
  });

  /// The content painted through the edge mask.
  final Widget child;

  /// The axis along which the edges fade.
  final Axis axis;

  /// Whether the leading edge fades when scrollable content is hidden.
  final bool fadeStart;

  /// Whether the trailing edge fades when scrollable content is hidden.
  final bool fadeEnd;

  /// Whether scrollable descendants can be dragged with a mouse.
  final bool allowMouseDrag;

  @override
  State<AuraEdgy> createState() => _AuraEdgyState();
}

class _AuraEdgyState extends State<AuraEdgy> {
  var _fadeStart = false;
  var _fadeEnd = false;

  LinearGradient get _edgeGradient => LinearGradient(
    begin: _startAlignment,
    end: _endAlignment,
    colors: _maskColors,
    stops: AuraEdgy._stops,
  );

  Alignment get _startAlignment =>
      widget.axis == Axis.vertical ? Alignment.topCenter : Alignment.centerLeft;

  Alignment get _endAlignment => widget.axis == Axis.vertical
      ? Alignment.bottomCenter
      : Alignment.centerRight;

  List<Color> get _maskColors => [
    if (widget.fadeStart && _fadeStart)
      AuraEdgy._transparent
    else
      AuraEdgy._opaque,
    AuraEdgy._opaque,
    AuraEdgy._opaque,
    if (widget.fadeEnd && _fadeEnd) AuraEdgy._transparent else AuraEdgy._opaque,
  ];

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (widget.allowMouseDrag) {
      final scrollBehavior = ScrollConfiguration.of(context);
      content = ScrollConfiguration(
        behavior: scrollBehavior.copyWith(
          dragDevices: {...scrollBehavior.dragDevices, PointerDeviceKind.mouse},
        ),
        child: widget.child,
      );
    } else {
      content = widget.child;
    }

    return NotificationListener<ScrollMetricsNotification>(
      child: NotificationListener<ScrollNotification>(
        child: ShaderMask(
          shaderCallback: (bounds) => _edgeGradient.createShader(bounds),
          blendMode: .dstIn,
          child: content,
        ),
        onNotification: _onScrollNotification,
      ),
      onNotification: _onScrollMetricsNotification,
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    _updateFades(notification.metrics, notification.depth);

    return false;
  }

  bool _onScrollMetricsNotification(ScrollMetricsNotification notification) {
    _updateFades(notification.metrics, notification.depth);

    return false;
  }

  void _updateFades(ScrollMetrics metrics, int depth) {
    if (depth != 0 || metrics.axis != widget.axis) return;

    final isReversed =
        metrics.axisDirection == AxisDirection.left ||
        metrics.axisDirection == AxisDirection.up;
    final fadeStart =
        (isReversed ? metrics.extentAfter : metrics.extentBefore) > 0;
    final fadeEnd =
        (isReversed ? metrics.extentBefore : metrics.extentAfter) > 0;
    if (fadeStart == _fadeStart && fadeEnd == _fadeEnd) return;

    setState(() {
      _fadeStart = fadeStart;
      _fadeEnd = fadeEnd;
    });
  }
}
