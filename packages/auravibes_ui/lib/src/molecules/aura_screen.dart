// Required: Existing test and UI helpers keep compact return flow.
// Required: UI components keep related private widgets together.

import 'dart:ui';

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

export 'aura_app_bar.dart';

/// Screen manager.
class AuraScreen extends StatelessWidget {
  /// Screen manager.
  const AuraScreen({
    required this.child,
    this.appBar,
    this.variant = AuraScreenVariation.standard,
    this.padding,
    super.key,
  });

  /// Chilg.
  final Widget child;

  /// App bar.
  final PreferredSizeWidget? appBar;

  /// Padding.
  final AuraEdgeInsetsGeometry? padding;

  /// Variant.
  final AuraScreenVariation variant;

  @override
  Widget build(BuildContext context) {
    final padding = this.padding;
    final appBar = this.appBar;

    var container = child;
    if (padding != null) {
      container = AuraPadding(child: container, padding: padding);
    }

    var content = container;

    if (appBar != null) {
      content = Padding(
        padding: .only(
          top: appBar.preferredSize.height + MediaQuery.paddingOf(context).top,
        ),
        child: content,
      );
    }

    content = switch (variant) {
      AuraScreenVariation.standard => content,
      AuraScreenVariation.aurora => Stack(
        children: [const _AuroraBackground(), content],
      ),
    };

    return Scaffold(
      appBar: appBar,
      body: Portal(child: content),
      backgroundColor: context.auraColors.background,
      extendBodyBehindAppBar: true,
    );
  }
}

/// Screen variation.
enum AuraScreenVariation {
  /// Standard.
  standard,

  /// Aurora.
  aurora,
}

class _AuroraBackground extends StatelessWidget {
  static const _outerOffset = -100.0;
  static const _bottomOffset = -50.0;
  static const _topBlobSize = 400.0;
  static const _rightBlobSize = 300.0;
  static const _bottomBlobSize = 350.0;
  static const _blurRadius = 60.0;
  static const _primaryAlpha = 102;
  static const _accentAlpha = 76;
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return Stack(
      children: [
        // Base color.
        Container(color: colors.background),
        // Blob 1 (Top Left - Primary).
        Positioned(
          left: _outerOffset,
          top: _outerOffset,
          child: _Blob(
            color: colors.primary.withAlpha(_primaryAlpha),
            size: _topBlobSize,
          ),
        ),
        // Blob 2 (Center Right - Secondary).
        Positioned(
          top: 200,
          right: _outerOffset,
          child: _Blob(
            color: colors.secondary.withAlpha(_primaryAlpha),
            size: _rightBlobSize,
          ),
        ),
        // Blob 3 (Bottom Left - Primary/Accent).
        Positioned(
          left: _bottomOffset,
          bottom: _bottomOffset,
          child: _Blob(
            color: colors.primary.withAlpha(_accentAlpha),
            size: _bottomBlobSize,
          ),
        ),
        // Blur Mesh.
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurRadius, sigmaY: _blurRadius),
          child: Container(color: DesignColors.transparent),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
          stops: const [0.0, 1.0],
        ),
        shape: BoxShape.circle,
      ),
      width: size,
      height: size,
    );
  }
}
