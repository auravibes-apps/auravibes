// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable tile component following the Aura design system.
///
/// Tiles are horizontally expanded interactive elements similar to buttons
/// but designed for broader content areas and different interaction patterns.
/// They support multiple variants, sizes, and states while maintaining
/// consistency with the design tokens.
class AuraTile extends StatefulWidget {
  // Null onTap creates a non-interactive tile for status rows.
  // ignore: unnecessary-nullable
  /// Creates a Aura tile.
  const AuraTile({
    required this.child,
    super.key,
    this.onTap,
    this.variant = AuraTileVariant.primary,
    this.size = AuraTileSize.medium,
    this.isLoading = false,
    this.leading,
    this.trailing,
    this.enabled = true,
  });

  /// The callback that is called when the tile is tapped.
  final VoidCallback? onTap;

  /// The widget to display inside the tile.
  final Widget child;

  /// The visual variant of the tile.
  final AuraTileVariant variant;

  /// The size of the tile.
  final AuraTileSize size;

  /// Whether the tile is in a loading state.
  final bool isLoading;

  /// Optional widget to display before the main content.
  final Widget? leading;

  /// Optional widget to display after the main content.
  final Widget? trailing;

  /// Whether the tile is enabled for interaction.
  final bool enabled;

  @override
  State<AuraTile> createState() => _AuraTileState();
}

class _AuraTileState extends State<AuraTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _canInteract => widget.enabled && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;
    final leading = widget.leading;
    final trailing = widget.trailing;
    final tileChild = widget.child;
    final isChildEmpty =
        tileChild is SizedBox && tileChild.width == 0 && tileChild.height == 0;
    final Widget content;
    if (widget.isLoading) {
      content = Center(
        child: AuraLoadingCircle(
          tint: AuraTint.primary,
          size: 20,
          itemBuilder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: _getTextColor(auraColors),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else if (isChildEmpty && leading != null && trailing == null) {
      content = Center(child: leading);
    } else {
      content = Row(
        children: [
          if (leading != null) ...[
            leading,
            const AuraSizedBox(width: .sm),
          ],
          Flexible(
            fit: .tight,
            child: DefaultTextStyle(
              style: _getTextStyle(
                auraColors,
                typography: context.auraTheme.typography,
              ),
              child: widget.child,
            ),
          ),
          if (trailing != null) ...[
            const AuraSizedBox(width: .sm),
            trailing,
          ],
        ],
      );
    }

    final tile = AnimatedContainer(
      padding: _getPadding(spacing: context.auraTheme.spacing),
      decoration: BoxDecoration(
        color: _getBackgroundColor(auraColors),
        border: Border.fromBorderSide(
          BorderSide(color: _getBorderColor(auraColors)),
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(
            context.auraTheme.fromBorderRadius(.lg),
          ),
        ),
        boxShadow: _getBoxShadow(),
      ),
      child: content,
      duration: auraTheme.animation.normal,
    );

    return SizedBox(
      width: double.infinity,
      child: FocusableActionDetector(
        enabled: _canInteract,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();

              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        mouseCursor: _canInteract
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          child: tile,
          onTapDown: _canInteract
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: _canInteract ? (_) => _clearPressed() : null,
          onTap: _canInteract ? widget.onTap : null,
          onTapCancel: _clearPressed,
          behavior: HitTestBehavior.opaque,
        ),
      ),
    );
  }

  void _clearPressed() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (!widget.enabled) return colors.outlineVariant;

    final baseColor = switch (widget.variant) {
      AuraTileVariant.primary => colors.primary,
      AuraTileVariant.surface => colors.surface,
      AuraTileVariant.ghost => DesignColors.transparent,
      AuraTileVariant.selected => colors.primary.withValues(alpha: 0.1),
      AuraTileVariant.error => colors.error,
    };

    if (!_canInteract) return baseColor;

    final overlayAlpha = _overlayAlpha;

    if (overlayAlpha == 0) return baseColor;

    return Color.alphaBlend(
      colors.primary.withValues(alpha: overlayAlpha),
      baseColor,
    );
  }

  Color _getBorderColor(AuraColorScheme colors) {
    if (_focused && _canInteract) return colors.primary;

    return Colors.transparent;
  }

  double get _overlayAlpha {
    if (_pressed) return 0.16;
    if (_hovered || _focused) return 0.08;

    return 0;
  }

  List<BoxShadow> _getBoxShadow() {
    if (widget.variant == AuraTileVariant.surface) {
      return [DesignShadows.sm];
    }

    return [];
  }

  TextStyle _getTextStyle(
    AuraColorScheme colors, {
    required AuraTypographyScale typography,
  }) {
    final fontSize = switch (widget.size) {
      AuraTileSize.small => typography.fontSizeSm,
      AuraTileSize.medium => typography.fontSizeBase,
      AuraTileSize.large => typography.fontSizeLg,
    };

    final fontWeight = switch (widget.size) {
      AuraTileSize.small => typography.fontWeightMedium,
      AuraTileSize.medium => typography.fontWeightMedium,
      AuraTileSize.large => typography.fontWeightSemibold,
    };

    return TextStyle(
      color: _getTextColor(colors),
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: typography.lineHeightBase,
    );
  }

  Color _getTextColor(AuraColorScheme colors) {
    if (!widget.enabled) return colors.mutedForeground;

    return switch (widget.variant) {
      AuraTileVariant.primary => colors.onTint(AuraTint.primary),
      AuraTileVariant.surface => colors.foregroundOnSurface,
      AuraTileVariant.ghost => colors.primary,
      AuraTileVariant.selected => colors.primary,
      AuraTileVariant.error => colors.onTint(AuraTint.error),
    };
  }

  EdgeInsets _getPadding({required AuraSpacingScale spacing}) {
    return switch (widget.size) {
      AuraTileSize.small => EdgeInsets.symmetric(
        vertical: spacing.sm,
        horizontal: spacing.md,
      ),
      AuraTileSize.medium => EdgeInsets.symmetric(
        vertical: spacing.md,
        horizontal: spacing.lg,
      ),
      AuraTileSize.large => EdgeInsets.symmetric(
        vertical: spacing.lg,
        horizontal: spacing.xl,
      ),
    };
  }
}

/// The visual variant of a [AuraTile].
enum AuraTileVariant {
  /// A filled tile with primary color background.
  primary,

  /// A tile with surface background and subtle shadow.
  surface,

  /// A tile with transparent background and no border.
  ghost,

  /// A tile with subtle primary tint background, no shadow.
  /// Used for selection states in navigation lists.
  selected,

  /// A tile with error color background.
  error,
}

/// The size of a [AuraTile].
enum AuraTileSize {
  /// A small tile.
  small,

  /// A medium tile (default).
  medium,

  /// A large tile.
  large,
}
