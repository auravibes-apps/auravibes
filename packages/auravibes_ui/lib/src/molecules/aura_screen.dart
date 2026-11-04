// Required: Existing test and UI helpers keep compact return flow.
// Required: UI components keep related private widgets together.

import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
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
  Widget build(BuildContext context) => switch (screen.variant) {
    .standard || .aurora => child,
  };
}

/// Screen variation.
enum AuraScreenVariation {
  /// Standard.
  standard,

  /// Legacy alias for the standard themed background.
  aurora,
}
