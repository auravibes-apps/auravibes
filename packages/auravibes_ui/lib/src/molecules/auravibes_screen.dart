import 'dart:ui';

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class _AuraScreenScope extends InheritedWidget {
  const _AuraScreenScope({
    required this.hasAppBar,
    required super.child,
  });
  final bool hasAppBar;

  static _AuraScreenScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AuraScreenScope>();

  @override
  bool updateShouldNotify(_AuraScreenScope oldWidget) =>
      hasAppBar != oldWidget.hasAppBar;
}

class _AuraScreenDefaultsScope extends InheritedWidget {
  const _AuraScreenDefaultsScope({
    required this.appBarBuilder,
    required this.inheritLeadingWhen,
    required super.child,
  });

  final Widget? Function(BuildContext) appBarBuilder;
  final bool Function(BuildContext)? inheritLeadingWhen;

  static _AuraScreenDefaultsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AuraScreenDefaultsScope>();

  @override
  bool updateShouldNotify(_AuraScreenDefaultsScope oldWidget) =>
      appBarBuilder != oldWidget.appBarBuilder ||
      inheritLeadingWhen != oldWidget.inheritLeadingWhen;
}

/// screen manager
class AuraScreen extends StatelessWidget {
  /// Screen manager
  const AuraScreen({
    required this.child,
    this.allowOverride = false,
    this.appBar,
    this.variant = AuraScreenVariation.aurora,
    this.padding,
    super.key,
  });

  /// chilg
  final Widget child;

  /// app bar
  final Widget? appBar;

  /// padding
  final AuraEdgeInsetsGeometry? padding;

  /// variant
  final AuraScreenVariation variant;

  /// allow override
  final bool allowOverride;

  @override
  Widget build(BuildContext context) {
    final ancestorHasAppBar =
        _AuraScreenScope.maybeOf(context)?.hasAppBar ?? false;

    final defaults = _AuraScreenDefaultsScope.maybeOf(context);
    final defaultAppBar = defaults?.appBarBuilder(context);

    var resolvedAppBar = appBar ?? defaultAppBar;

    final inheritLeading = defaults?.inheritLeadingWhen?.call(context);

    final appBarIsAuraAppBar = resolvedAppBar is AuraAppBar;
    final defaultIsAuraAppBar = defaultAppBar is AuraAppBar;

    // If child route provides an app bar without leading, and we should inherit
    // leading from default, copy the hamburger menu from default app bar
    if (appBarIsAuraAppBar &&
        defaultIsAuraAppBar &&
        appBar != null &&
        resolvedAppBar.leading == null &&
        (inheritLeading ?? false)) {
      final providedAppBar = resolvedAppBar;
      final defaultAuraAppBar = defaultAppBar;
      if (defaultAuraAppBar.leading != null) {
        resolvedAppBar = AuraAppBar(
          title: providedAppBar.title,
          actions: providedAppBar.actions,
          footer: providedAppBar.footer,
          leading: defaultAuraAppBar.leading,
        );
      }
    }

    final showOwnAppBar =
        resolvedAppBar != null && (!ancestorHasAppBar || allowOverride);

    final scopeHasAppBar = showOwnAppBar || ancestorHasAppBar;

    var container = child;
    if (padding != null) {
      container = AuraPadding(
        padding: padding!,
        child: container,
      );
    }

    final content = Column(
      children: [
        if (scopeHasAppBar && resolvedAppBar != null) resolvedAppBar,
        Expanded(child: container),
      ],
    );

    if (variant == AuraScreenVariation.aurora) {
      return Portal(
        child: _AuraScreenScope(
          hasAppBar: scopeHasAppBar,
          child: Stack(
            children: [
              const _AuroraBackground(),
              content,
            ],
          ),
        ),
      );
    }

    return Portal(
      child: _AuraScreenScope(
        hasAppBar: scopeHasAppBar,
        child: ColoredBox(
          color: context.auraColors.background,
          child: content,
        ),
      ),
    );
  }
}

/// Wraps a subtree with default app bar builder for AuraScreens.
///
/// This widget provides default app bar configuration to all [AuraScreen]
/// widgets in its subtree. The [appBarBuilder] function is called to create
/// the default app bar, and [inheritLeadingWhen] controls when the leading
/// widget (e.g., back button) from a parent screen should be inherited.
class AuraScreenDefaults extends StatelessWidget {
  /// Creates a widget that provides default app bar configuration.
  ///
  /// The [appBarBuilder] is required and will be called to create the default
  /// app bar for child screens. The [child] is required and will have access
  /// to the default configuration. The [inheritLeadingWhen] callback determines
  /// when a child screen should inherit the leading widget from the default.
  const AuraScreenDefaults({
    required this.appBarBuilder,
    required this.child,
    this.inheritLeadingWhen,
    super.key,
  });

  /// A function that builds the default app bar for child screens.
  ///
  /// This function receives the [BuildContext] and should return an
  /// [AuraAppBar] or null if no default app bar should be shown.
  final Widget? Function(BuildContext) appBarBuilder;

  /// The child widget that will have access to the default app bar
  /// configuration.
  final Widget child;

  /// Determines when the leading widget should be inherited from the default.
  ///
  /// When this returns true and a child [AuraAppBar] doesn't provide its own
  /// leading widget, the leading widget from the default app bar will be used.
  final bool Function(BuildContext)? inheritLeadingWhen;

  @override
  Widget build(BuildContext context) {
    return _AuraScreenDefaultsScope(
      appBarBuilder: appBarBuilder,
      inheritLeadingWhen: inheritLeadingWhen,
      child: child,
    );
  }
}

/// App Bar
class AuraAppBar extends StatelessWidget {
  /// constructor
  const AuraAppBar({
    super.key,
    this.title,
    this.actions,
    this.footer,
    this.leading,
  });

  /// title
  final Widget? title;

  /// acions
  final List<Widget>? actions;

  /// footer of bar
  final Widget? footer;

  /// Optional custom leading widget that replaces the automatic back button.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsGeometry.all(DesignSpacing.sm),
      child: AuraColumn(
        children: [
          AuraRow(
            children: [
              if (leading != null)
                leading!
              else if (Navigator.of(context).canPop() &&
                  (ModalRoute.of(context)?.isCurrent ?? false))
                AuraIconButton(
                  icon: Icons.chevron_left_rounded,
                  color: context.auraColors.onBackground,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  semanticLabel: 'Back',
                  tooltip: 'Back to previous screen',
                ),
              AuraText(
                style: AuraTextStyle.heading3,
                child: Expanded(
                  child: Center(child: title ?? Container()),
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...actions!,
            ],
          ),
          ?footer,
        ],
      ),
    );
  }
}

/// screen variation
enum AuraScreenVariation {
  /// standard
  standard,

  /// aurora
  aurora,
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    return Stack(
      children: [
        // Base color
        Container(color: colors.background),
        // Blob 1 (Top Left - Primary)
        Positioned(
          top: -100,
          left: -100,
          child: _Blob(
            color: colors.primary.withAlpha(102),
            size: 400,
          ),
        ),
        // Blob 2 (Center Right - Secondary)
        Positioned(
          top: 200,
          right: -100,
          child: _Blob(
            color: colors.secondary.withAlpha(102),
            size: 300,
          ),
        ),
        // Blob 3 (Bottom Left - Primary/Accent)
        Positioned(
          bottom: -50,
          left: -50,
          child: _Blob(
            color: colors.primary.withAlpha(76),
            size: 350,
          ),
        ),
        // Blur Mesh
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
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
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
