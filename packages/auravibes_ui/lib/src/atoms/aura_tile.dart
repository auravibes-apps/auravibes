// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

typedef _AuraTileAppearance = ({
  AuraTile tile,
  AuraColorScheme colors,
  AuraTheme theme,
  bool canInteract,
  bool focused,
  double overlayAlpha,
});

typedef _AuraTileCallbacks = ({
  VoidCallback? onInvoke,
  ValueChanged<bool> onFocusHighlight,
  ValueChanged<bool> onHoverHighlight,
  GestureTapDownCallback? onTapDown,
  GestureTapUpCallback? onTapUp,
  GestureTapCallback? onTap,
  GestureTapCancelCallback onTapCancel,
});

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
  const new({
    required this.child,
    super.key,
    this.onTap,
    this.variant = AuraTileVariant.primary,
    this.size = AuraTileSize.medium,
    this.isLoading = false,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.expand = true,
    this.semanticLabel,
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

  /// Whether the tile expands to the available width.
  final bool expand;

  /// A semantic label for interactive tiles.
  final String? semanticLabel;

  @override
  State<AuraTile> createState() => _AuraTileState();
}

class _AuraTileState extends State<AuraTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _canInteract => widget.enabled && !widget.isLoading;

  double get _overlayAlpha {
    if (_pressed) return 0.16;
    if (_hovered || _focused) return 0.08;

    return 0;
  }

  @override
  Widget build(BuildContext context) => _AuraTileLayout(
    appearance: _appearance(context),
    callbacks: _callbacks(),
  );

  _AuraTileAppearance _appearance(BuildContext context) => (
    tile: widget,
    colors: context.auraColors,
    theme: context.auraTheme,
    canInteract: _canInteract,
    focused: _focused,
    overlayAlpha: _overlayAlpha,
  );

  _AuraTileCallbacks _callbacks() {
    final canInteract = _canInteract;

    return (
      onInvoke: widget.onTap,
      onFocusHighlight: _setFocused,
      onHoverHighlight: _setHovered,
      onTapDown: canInteract ? _setPressed : null,
      onTapUp: canInteract ? _clearPressedOnTap : null,
      onTap: canInteract ? widget.onTap : null,
      onTapCancel: _clearPressed,
    );
  }

  void _setFocused(bool value) => setState(() => _focused = value);

  void _setHovered(bool value) => setState(() => _hovered = value);

  void _setPressed(TapDownDetails _) => setState(() => _pressed = true);

  void _clearPressedOnTap(TapUpDetails _) => _clearPressed();

  void _clearPressed() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }
}

class const _AuraTileLayout({
  required final _AuraTileAppearance appearance,
  required final _AuraTileCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tile = appearance.tile;
    final enabled = appearance.canInteract;

    return _AuraTileSemantics(
      tile: _AuraTileInteraction(
        tile: _AuraTileSurface(appearance: appearance),
        enabled: enabled,
        callbacks: callbacks,
      ),
      enabled: enabled,
      expand: tile.expand,
      semanticLabel: tile.semanticLabel,
      onTap: tile.onTap,
    );
  }
}

class const _AuraTileSurface({required final _AuraTileAppearance appearance})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    padding: _tilePadding(appearance),
    decoration: _tileDecoration(appearance),
    child: _AuraTileContent(
      appearance: appearance,
      loadingColor: _tileTextColor(appearance),
      textStyle: _tileTextStyle(appearance),
    ),
    duration: appearance.theme.animation.normal,
  );
}

class const _AuraTileContent({
  required final _AuraTileAppearance appearance,
  required final Color loadingColor,
  required final TextStyle textStyle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tile = appearance.tile;
    if (tile.isLoading) return _AuraTileLoading(color: loadingColor);
    if (_isEmptyTileChild(tile.child) &&
        tile.leading != null &&
        tile.trailing == null) {
      return Center(child: tile.leading);
    }

    return _AuraTileRow(
      child: tile.child,
      leading: tile.leading,
      trailing: tile.trailing,
      textStyle: textStyle,
    );
  }
}

class const _AuraTileLoading({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: AuraLoadingCircle(
      tint: .primary,
      size: 20,
      itemBuilder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(color: color, shape: .circle),
      ),
    ),
  );
}

class const _AuraTileRow({
  required final Widget child,
  required final Widget? leading,
  required final Widget? trailing,
  required final TextStyle textStyle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (leading case final value?) ...[value, const AuraSizedBox(width: .sm)],
      Flexible(
        fit: .tight,
        child: DefaultTextStyle(style: textStyle, child: child),
      ),
      if (trailing case final value?) ...[
        const AuraSizedBox(width: .sm),
        value,
      ],
    ],
  );
}

class const _AuraTileInteraction({
  required final Widget tile,
  required final bool enabled,
  required final _AuraTileCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    enabled: enabled,
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _invoke),
    },
    onShowFocusHighlight: callbacks.onFocusHighlight,
    onShowHoverHighlight: callbacks.onHoverHighlight,
    mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: _AuraTileGesture(tile: tile, callbacks: callbacks),
  );

  Null _invoke(ActivateIntent _) {
    callbacks.onInvoke?.call();

    return null;
  }
}

class const _AuraTileGesture({
  required final Widget tile,
  required final _AuraTileCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: tile,
    onTapDown: callbacks.onTapDown,
    onTapUp: callbacks.onTapUp,
    onTap: callbacks.onTap,
    onTapCancel: callbacks.onTapCancel,
    behavior: .opaque,
    excludeFromSemantics: true,
  );
}

class const _AuraTileSemantics({
  required final Widget tile,
  required final bool enabled,
  required final bool expand,
  required final String? semanticLabel,
  required final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sizedTile = expand ? SizedBox(width: .infinity, child: tile) : tile;

    if (!enabled) return sizedTile;

    return Semantics(
      child: sizedTile,
      container: true,
      excludeSemantics: true,
      enabled: true,
      button: true,
      label: semanticLabel ?? 'Tile',
      onTap: onTap,
    );
  }
}

BoxDecoration _tileDecoration(_AuraTileAppearance appearance) => BoxDecoration(
  color: _tileBackgroundColor(appearance),
  border: Border.fromBorderSide(.new(color: _tileBorderColor(appearance))),
  borderRadius: BorderRadius.all(
    .circular(appearance.theme.fromBorderRadius(.lg)),
  ),
  boxShadow: _tileBoxShadow(appearance),
);

Color _tileBackgroundColor(_AuraTileAppearance appearance) {
  final baseColor = _tileBaseBackgroundColor(appearance);
  if (!appearance.canInteract || appearance.overlayAlpha == 0) {
    return baseColor;
  }

  return Color.alphaBlend(
    appearance.colors.primary.withValues(alpha: appearance.overlayAlpha),
    baseColor,
  );
}

Color _tileBaseBackgroundColor(_AuraTileAppearance appearance) {
  final tile = appearance.tile;
  final colors = appearance.colors;
  if (!tile.enabled) return colors.outlineVariant;

  return switch (tile.variant) {
    .primary => colors.primary,
    .surface => colors.surface,
    .ghost => DesignColors.transparent,
    .selected => colors.primary.withValues(alpha: 0.1),
    .error => colors.error,
  };
}

Color _tileBorderColor(_AuraTileAppearance appearance) =>
    appearance.focused && appearance.canInteract
    ? appearance.colors.primary
    : Colors.transparent;

List<BoxShadow> _tileBoxShadow(_AuraTileAppearance appearance) =>
    appearance.tile.variant == AuraTileVariant.surface
    ? [DesignShadows.sm]
    : [];

TextStyle _tileTextStyle(_AuraTileAppearance appearance) => TextStyle(
  color: _tileTextColor(appearance),
  fontSize: _tileFontSize(appearance),
  fontWeight: _tileFontWeight(appearance),
  height: appearance.theme.typography.lineHeightBase,
);

double _tileFontSize(_AuraTileAppearance appearance) {
  final typography = appearance.theme.typography;

  return switch (appearance.tile.size) {
    .small => typography.fontSizeSm,
    .medium => typography.fontSizeBase,
    .large => typography.fontSizeLg,
  };
}

FontWeight _tileFontWeight(_AuraTileAppearance appearance) =>
    switch (appearance.tile.size) {
      .small || .medium => appearance.theme.typography.fontWeightMedium,
      .large => appearance.theme.typography.fontWeightSemibold,
    };

Color _tileTextColor(_AuraTileAppearance appearance) {
  final tile = appearance.tile;
  final colors = appearance.colors;
  if (!tile.enabled) return colors.mutedForeground;

  return switch (tile.variant) {
    .primary => colors.onTint(.primary),
    .surface => colors.foregroundOnSurface,
    .ghost || .selected => colors.primary,
    .error => colors.onTint(.error),
  };
}

EdgeInsets _tilePadding(_AuraTileAppearance appearance) {
  final spacing = appearance.theme.spacing;

  return switch (appearance.tile.size) {
    .small => EdgeInsets.symmetric(
      vertical: spacing.sm,
      horizontal: spacing.md,
    ),
    .medium => EdgeInsets.symmetric(
      vertical: spacing.md,
      horizontal: spacing.lg,
    ),
    .large => EdgeInsets.symmetric(
      vertical: spacing.lg,
      horizontal: spacing.xl,
    ),
  };
}

bool _isEmptyTileChild(Widget child) =>
    child is SizedBox && child.width == 0 && child.height == 0;

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
