import 'dart:ui';

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

/// screen manager
class AuraScreen extends StatelessWidget {
  /// Screen manager
  const AuraScreen({
    required this.child,
    this.appBar,
    this.variant = AuraScreenVariation.aurora,
    this.padding,
    super.key,
  });

  /// chilg
  final Widget child;

  /// app bar
  final PreferredSizeWidget? appBar;

  /// padding
  final AuraEdgeInsetsGeometry? padding;

  /// variant
  final AuraScreenVariation variant;

  @override
  Widget build(BuildContext context) {
    var container = child;
    if (padding != null) {
      container = AuraPadding(
        padding: padding!,
        child: container,
      );
    }

    var content = container;

    if (appBar != null) {
      content = Padding(
        padding: .only(
          top:
              appBar!.preferredSize.height + MediaQuery.of(context).padding.top,
        ),
        child: content,
      );
    }

    content = switch (variant) {
      AuraScreenVariation.standard => ColoredBox(
        color: context.auraColors.background,
        child: content,
      ),
      AuraScreenVariation.aurora => Stack(
        children: [
          const _AuroraBackground(),
          content,
        ],
      ),
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Portal(
        child: content,
      ),
    );
  }
}

/// App Bar
class AuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// constructor
  const AuraAppBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.leading,
  });

  /// title
  final Widget? title;

  /// acions
  final List<Widget>? actions;

  /// bottom of bar
  final PreferredSizeWidget? bottom;

  /// Optional custom leading widget that replaces the automatic back button.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: title == null
          ? null
          : AuraText(
              style: AuraTextStyle.heading3,
              child: title!,
            ),
      actions: actions,
      leading: leading,
      bottom: bottom,
      backgroundColor: const Color(0x00000000),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
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
