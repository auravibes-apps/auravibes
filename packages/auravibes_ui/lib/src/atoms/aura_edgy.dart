import 'package:flutter/widgets.dart';

/// Fades the start and end edges of scrollable content.
class AuraEdgy extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
        end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
        colors: [
          if (fadeStart) const Color(0x00FFFFFF) else const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
          if (fadeEnd) const Color(0x00FFFFFF) else const Color(0xFFFFFFFF),
        ],
        stops: const [0, 0.12, 0.88, 1],
      ).createShader(bounds),
      blendMode: .dstIn,
      child: child,
    );
  }
}
