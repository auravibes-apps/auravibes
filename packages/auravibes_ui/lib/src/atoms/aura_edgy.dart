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
  ({bool start, bool end}) _fades = (start: false, end: false);

  @override
  Widget build(BuildContext context) => _AuraEdgyScrollNotifications(
    child: _AuraEdgyMask(
      child: _AuraEdgyContent(
        child: widget.child,
        allowMouseDrag: widget.allowMouseDrag,
      ),
      axis: widget.axis,
      fadeStart: widget.fadeStart,
      fadeEnd: widget.fadeEnd,
      fadeStartVisible: _fades.start,
      fadeEndVisible: _fades.end,
    ),
    onMetricsNotification: _onScrollMetricsNotification,
    onScrollNotification: _onScrollNotification,
  );

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

    final fades = _fadesFor(metrics);
    if (fades == _fades) return;

    setState(() => _fades = fades);
  }

  static ({bool start, bool end}) _fadesFor(ScrollMetrics metrics) {
    final isReversed =
        metrics.axisDirection == AxisDirection.left ||
        metrics.axisDirection == AxisDirection.up;
    final hasBefore = metrics.extentBefore > 0;
    final hasAfter = metrics.extentAfter > 0;

    return (
      start: isReversed ? hasAfter : hasBefore,
      end: isReversed ? hasBefore : hasAfter,
    );
  }
}

class const _AuraEdgyScrollNotifications({
  required final Widget child,
  required final bool Function(ScrollMetricsNotification) onMetricsNotification,
  required final bool Function(ScrollNotification) onScrollNotification,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        child: NotificationListener<ScrollNotification>(
          child: child,
          onNotification: onScrollNotification,
        ),
        onNotification: onMetricsNotification,
      );
}

class const _AuraEdgyMask({
  required final Widget child,
  required final Axis axis,
  required final bool fadeStart,
  required final bool fadeEnd,
  required final bool fadeStartVisible,
  required final bool fadeEndVisible,
}) extends StatelessWidget {
  LinearGradient get _edgeGradient => LinearGradient(
    begin: _startAlignment,
    end: _endAlignment,
    colors: _maskColors,
    stops: AuraEdgy._stops,
  );

  Alignment get _startAlignment =>
      axis == Axis.vertical ? Alignment.topCenter : Alignment.centerLeft;

  Alignment get _endAlignment =>
      axis == Axis.vertical ? Alignment.bottomCenter : Alignment.centerRight;

  List<Color> get _maskColors => [
    if (fadeStart && fadeStartVisible)
      AuraEdgy._transparent
    else
      AuraEdgy._opaque,
    AuraEdgy._opaque,
    AuraEdgy._opaque,
    if (fadeEnd && fadeEndVisible) AuraEdgy._transparent else AuraEdgy._opaque,
  ];

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: _edgeGradient.createShader,
    blendMode: .dstIn,
    child: child,
  );
}

class const _AuraEdgyContent({
  required final Widget child,
  required final bool allowMouseDrag,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!allowMouseDrag) return child;

    final scrollBehavior = ScrollConfiguration.of(context);

    return ScrollConfiguration(
      behavior: scrollBehavior.copyWith(
        dragDevices: {...scrollBehavior.dragDevices, PointerDeviceKind.mouse},
      ),
      child: child,
    );
  }
}
