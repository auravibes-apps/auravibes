// Required: Existing test and UI helpers keep compact return flow.
// Required: UI components keep related private widgets together.

import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart' show Portal;

export 'aura_app_bar.dart';

/// Screen manager.
class AuraScreen extends StatelessWidget {
  /// Screen manager.
  const new({
    required this.child,
    this.appBar,
    this.variant = AuraScreenVariation.standard,
    this.padding,
    super.key,
  });

  /// The screen body.
  final Widget child;

  /// App bar.
  final PreferredSizeWidget? appBar;

  /// Padding.
  final AuraEdgeInsetsGeometry? padding;

  /// Variant.
  final AuraScreenVariation variant;

  @override
  Widget build(BuildContext context) => _AuraScreenScaffold(screen: this);
}

class const _AuraScreenScaffold({required final AuraScreen screen})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: screen.appBar,
    body: Portal(child: _AuraScreenBody(screen: screen)),
    backgroundColor: context.auraColors.background,
    extendBodyBehindAppBar: true,
  );
}

class const _AuraScreenBody({required final AuraScreen screen})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraScreenPresentation(screen: screen);
}

class const _AuraScreenPresentation({required final AuraScreen screen})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = _AuraScreenAppBarContent(
      screen: screen,
      child: _AuraScreenPaddedContent(screen: screen),
    );

    return _AuraScreenVariant(screen: screen, child: content);
  }
}

class const _AuraScreenPaddedContent({required final AuraScreen screen})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final padding = screen.padding;

    return padding == null
        ? screen.child
        : AuraPadding(child: screen.child, padding: padding);
  }
}

class const _AuraScreenAppBarContent({
  required final AuraScreen screen,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appBar = screen.appBar;
    if (appBar == null) return child;

    return Padding(
      padding: .only(top: MediaQuery.paddingOf(context).top),
      child: child,
    );
  }
}

class const _AuraScreenVariant({
  required final AuraScreen screen,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => screen.variant == .aurora
      ? Stack(children: [const _AuroraBackground(), child])
      : child;
}

/// Screen variation.
enum AuraScreenVariation {
  /// Standard.
  standard,

  /// Aurora.
  aurora,
}

class const _AuroraBackground() extends StatelessWidget {
  static const _outerOffset = -100.0;
  static const _bottomOffset = -50.0;
  static const _topBlobSize = 400.0;
  static const _rightBlobSize = 300.0;
  static const _bottomBlobSize = 350.0;
  static const _blurRadius = 60.0;
  static const _primaryAlpha = 102;
  static const _accentAlpha = 76;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(color: context.auraColors.background),
      const _AuroraBlobLayer(),
      BackdropFilter(
        filter: .blur(sigmaX: _blurRadius, sigmaY: _blurRadius),
        child: Container(color: DesignColors.transparent),
      ),
    ],
  );
}

class const _AuroraBlobLayer() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return Stack(
      children: [
        _AuroraTopBlob(colors: colors),
        _AuroraRightBlob(colors: colors),
        _AuroraBottomBlob(colors: colors),
      ],
    );
  }
}

class const _AuroraTopBlob({required final AuraColorScheme colors})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuroraBlobPlacement(
    color: colors.primary.withAlpha(_AuroraBackground._primaryAlpha),
    size: _AuroraBackground._topBlobSize,
    left: _AuroraBackground._outerOffset,
    top: _AuroraBackground._outerOffset,
  );
}

class const _AuroraRightBlob({required final AuraColorScheme colors})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuroraBlobPlacement(
    color: colors.secondary.withAlpha(_AuroraBackground._primaryAlpha),
    size: _AuroraBackground._rightBlobSize,
    right: _AuroraBackground._outerOffset,
    top: 200,
  );
}

class const _AuroraBottomBlob({required final AuraColorScheme colors})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuroraBlobPlacement(
    color: colors.primary.withAlpha(_AuroraBackground._accentAlpha),
    size: _AuroraBackground._bottomBlobSize,
    left: _AuroraBackground._bottomOffset,
    bottom: _AuroraBackground._bottomOffset,
  );
}

class const _AuroraBlobPlacement({
  required final Color color,
  required final double size,
  final double? left,
  final double? right,
  final double? top,
  final double? bottom,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    child: _Blob(color: color, size: size),
  );
}

class const _Blob({required final Color color, required final double size})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
          stops: const [0.0, 1.0],
        ),
        shape: .circle,
      ),
      width: size,
      height: size,
    );
  }
}
