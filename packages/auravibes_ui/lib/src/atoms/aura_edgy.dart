import 'package:flutter/widgets.dart';

/// Fades the start and end edges of scrollable content.
class AuraEdgy extends StatelessWidget {
  static const _transparent = Color(0x00FFFFFF);
  static const _opaque = Color(0xFFFFFFFF);
  static const _stops = [0.0, 0.12, 0.88, 1.0];

  /// Creates a widget that fades the scrollable content's edges.
  const new({
    required this.child,
    this.axis = Axis.vertical,
    this.fadeStart = true,
    this.fadeEnd = true,
    super.key,
  });

  /// The content painted through the edge mask.
  final Widget child;

  /// The axis along which the edges fade.
  final Axis axis;

  /// Whether the leading edge fades.
  final bool fadeStart;

  /// Whether the trailing edge fades.
  final bool fadeEnd;

  LinearGradient get _edgeGradient => LinearGradient(
    begin: _startAlignment,
    end: _endAlignment,
    colors: _maskColors,
    stops: _stops,
  );

  Alignment get _startAlignment =>
      axis == Axis.vertical ? Alignment.topCenter : Alignment.centerLeft;

  Alignment get _endAlignment =>
      axis == Axis.vertical ? Alignment.bottomCenter : Alignment.centerRight;

  List<Color> get _maskColors => [
    if (fadeStart) _transparent else _opaque,
    _opaque,
    _opaque,
    if (fadeEnd) _transparent else _opaque,
  ];

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (bounds) => _edgeGradient.createShader(bounds),
    blendMode: .dstIn,
    child: child,
  );
}
