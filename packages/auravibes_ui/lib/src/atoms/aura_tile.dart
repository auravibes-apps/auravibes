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

  @override
  Widget build(BuildContext context) => _AuraTileLayout(
    appearance: _appearance(context),
    callbacks: _callbacks(),
  );

  void _setFocused(bool value) => setState(() => _focused = value);

  void _setHovered(bool value) => setState(() => _hovered = value);

  void _setPressed(TapDownDetails _) => setState(() => _pressed = true);

  void _clearPressed() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }
}

extension on _AuraTileState {
  bool get _canInteract => widget.enabled && !widget.isLoading;

  _AuraTileAppearance _appearance(BuildContext context) => (
    tile: widget,
    colors: context.auraColors,
    theme: context.auraTheme,
    canInteract: _canInteract,
    focused: _focused,
    overlayAlpha: _pressed ? 0.16 : (_hovered || _focused ? 0.08 : 0),
  );

  _AuraTileCallbacks _callbacks() {
    final canInteract = _canInteract;

    return (
      onInvoke: widget.onTap,
      onFocusHighlight: _setFocused,
      onHoverHighlight: _setHovered,
      onTapDown: canInteract ? _setPressed : null,
      onTapUp: canInteract ? (_) => _clearPressed() : null,
      onTap: canInteract ? widget.onTap : null,
      onTapCancel: _clearPressed,
    );
  }
}

class _AuraTileLayout extends StatelessWidget {
  _AuraTileLayout({
    required _AuraTileAppearance appearance,
    required _AuraTileCallbacks callbacks,
  }) : _child = _AuraTileSemantics(
         tile: _AuraTileInteraction(
           tile: _AuraTileSurface(appearance: appearance),
           enabled: appearance.canInteract,
           callbacks: callbacks,
         ),
         enabled: appearance.canInteract,
         expand: appearance.tile.expand,
         semanticLabel: appearance.tile.semanticLabel,
         onTap: appearance.tile.onTap,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
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

class _AuraTileContent extends StatelessWidget {
  _AuraTileContent({
    required _AuraTileAppearance appearance,
    required Color loadingColor,
    required TextStyle textStyle,
  }) : _child = appearance.tile.isLoading
           ? _AuraTileLoading(color: loadingColor)
           : _isEmptyTileChild(appearance.tile.child) &&
                 appearance.tile.leading != null &&
                 appearance.tile.trailing == null
           ? Center(child: appearance.tile.leading)
           : _AuraTileRow(
               child: appearance.tile.child,
               leading: appearance.tile.leading,
               trailing: appearance.tile.trailing,
               textStyle: textStyle,
             );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
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

class _AuraTileRow extends StatelessWidget {
  _AuraTileRow({
    required Widget child,
    required Widget? leading,
    required Widget? trailing,
    required TextStyle textStyle,
  }) : _child = Row(
         children: [
           if (leading case final value?) ...[
             value,
             const AuraSizedBox(width: .sm),
           ],
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

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraTileInteraction extends StatelessWidget {
  _AuraTileInteraction({
    required Widget tile,
    required bool enabled,
    required _AuraTileCallbacks callbacks,
  }) : _child = FocusableActionDetector(
         enabled: enabled,
         actions: {
           ActivateIntent: CallbackAction<ActivateIntent>(
             onInvoke: (_) {
               callbacks.onInvoke?.call();

               return null;
             },
           ),
         },
         onShowFocusHighlight: callbacks.onFocusHighlight,
         onShowHoverHighlight: callbacks.onHoverHighlight,
         mouseCursor: enabled
             ? SystemMouseCursors.click
             : SystemMouseCursors.basic,
         child: _AuraTileGesture(tile: tile, callbacks: callbacks),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
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

  return _tileVariantBackgroundColor(tile.variant, colors);
}

Color _tileVariantBackgroundColor(
  AuraTileVariant variant,
  AuraColorScheme colors,
) => switch (variant) {
  .primary => colors.primary,
  .surface => colors.surface,
  .ghost => DesignColors.transparent,
  .selected => colors.primary.withValues(alpha: 0.1),
  .error => colors.error,
};

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

  return _tileVariantTextColor(tile.variant, colors);
}

Color _tileVariantTextColor(AuraTileVariant variant, AuraColorScheme colors) =>
    switch (variant) {
      .primary => colors.onTint(.primary),
      .surface => colors.foregroundOnSurface,
      .ghost || .selected => colors.primary,
      .error => colors.onTint(.error),
    };

EdgeInsets _tilePadding(_AuraTileAppearance appearance) {
  final spacing = appearance.theme.spacing;

  return _tilePaddingForSize(appearance.tile.size, spacing);
}

EdgeInsets _tilePaddingForSize(AuraTileSize size, AuraSpacingScale spacing) =>
    _tilePaddingValues(switch (size) {
      .small => (vertical: spacing.sm, horizontal: spacing.md),
      .medium => (vertical: spacing.md, horizontal: spacing.lg),
      .large => (vertical: spacing.lg, horizontal: spacing.xl),
    });

EdgeInsets _tilePaddingValues(({double vertical, double horizontal}) values) =>
    EdgeInsets.symmetric(
      vertical: values.vertical,
      horizontal: values.horizontal,
    );

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
