import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A customizable floating action button component following the Aura design
/// system.
///
/// This FAB supports different sizes, icons, extended variants with text,
/// and proper elevation and shadows.
class AuraFloatingActionButton extends StatelessWidget {
  static const _miniSize = 40.0;
  static const _largeSize = 72.0;
  static const _miniIconSize = 16.0;
  static const _regularIconSize = 20.0;
  static const _largeIconSize = 24.0;
  static const _regularSize = 56.0;

  /// Creates a Aura floating action button.
  const new({
    required this.onPressed,
    required this.icon,
    super.key,
    this.size = AuraFABSize.regular,
    this.tint,
    this.heroTag = const ValueKey<String>('aura_floating_action_button'),
    this.semanticLabel,
    this.tooltip,
  }) : text = null;

  /// Creates an extended Aura floating action button with text.
  const new extended({
    required this.onPressed,
    required this.icon,
    required this.text,
    super.key,
    this.tint,
    this.heroTag = const ValueKey<String>('aura_floating_action_button'),
    this.semanticLabel,
    this.tooltip,
  }) : size = AuraFABSize.extended;

  /// The callback that is called when the button is pressed.
  final VoidCallback? onPressed;

  /// The icon to display.
  final IconData icon;

  /// The text to display (only for extended variant).
  final String? text;

  /// The size of the FAB.
  final AuraFABSize size;

  /// The tint of the FAB. If null, uses the primary tint.
  final AuraTint? tint;

  /// The tag used for the FAB hero animation.
  ///
  /// Set to null to disable hero animations when multiple FABs are present.
  final LocalKey? heroTag;

  /// A semantic label for the FAB for accessibility.
  final String? semanticLabel;

  /// The tooltip message to display when the FAB is long-pressed.
  final String? tooltip;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AuraFABSize>('size', size));
  }

  @override
  Widget build(BuildContext context) => _AuraFabThemeData(
    button: this,
    colors: context.auraColors,
    theme: context.auraTheme,
  ).toWidget();
}

extension on AuraFloatingActionButton {
  double _getFABSize() {
    return switch (size) {
      .mini => AuraFloatingActionButton._miniSize,
      .regular => AuraFloatingActionButton._regularSize,
      .large => AuraFloatingActionButton._largeSize,
      .extended =>
        AuraFloatingActionButton._regularSize, // Height for extended.
    };
  }

  double _getIconPixels() {
    return switch (size) {
      .mini => AuraFloatingActionButton._miniIconSize,
      .regular => AuraFloatingActionButton._regularIconSize,
      .large => AuraFloatingActionButton._largeIconSize,
      .extended => AuraFloatingActionButton._regularIconSize,
    };
  }

  AuraBorderRadius _getBorderRadius() {
    return switch (size) {
      .mini => .lg,
      .regular => .xl,
      .large => .xl,
      .extended => .xl,
    };
  }

  double _getElevation() {
    return DesignElevation.md;
  }

  double _getFocusElevation() {
    return DesignElevation.lg;
  }

  double _getHoverElevation() {
    return DesignElevation.lg;
  }

  double _getHighlightElevation() {
    return DesignElevation.xl;
  }
}

class _AuraFabThemeData {
  new({
    required AuraFloatingActionButton button,
    required AuraColorScheme colors,
    required AuraTheme theme,
  }) : _widget = _AuraFabLayout(
         child: ConstrainedBox(
           constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
           child: Semantics(
             child: button.size == AuraFABSize.extended && button.text != null
                 ? _AuraFabExtended(
                     button: button,
                     background: colors.colorFor(button.tint ?? .primary),
                     foreground: colors.onTint(button.tint ?? .primary),
                     shape: _shape(button, theme),
                   )
                 : _AuraFabRegular(
                     button: button,
                     background: colors.colorFor(button.tint ?? .primary),
                     foreground: colors.onTint(button.tint ?? .primary),
                     shape: _shape(button, theme),
                   ),
             enabled: button.onPressed != null,
             button: true,
             label:
                 button.semanticLabel ??
                 button.tooltip ??
                 'Floating action button',
             onTap: button.onPressed,
           ),
         ),
       );

  final Widget _widget;

  Widget toWidget() => _widget;

  static ShapeBorder _shape(AuraFloatingActionButton button, AuraTheme theme) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          theme.fromBorderRadius(button._getBorderRadius()),
        ),
      );
}

class _AuraFabLayout extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class const _AuraFabExtended({
  required final AuraFloatingActionButton button,
  required final Color background,
  required final Color foreground,
  required final ShapeBorder shape,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraFabExtendedData(
    button: button,
    background: background,
    foreground: foreground,
    shape: shape,
    fontWeight: context.auraTheme.typography.fontWeightMedium,
  ).child;
}

class _AuraFabExtendedData({
  required final AuraFloatingActionButton button,
  required final Color background,
  required final Color foreground,
  required final ShapeBorder shape,
  required final FontWeight fontWeight,
}) {
  final Widget child = FloatingActionButton.extended(
    tooltip: button.tooltip,
    foregroundColor: foreground,
    backgroundColor: background,
    heroTag: button.heroTag,
    elevation: button._getElevation(),
    focusElevation: button._getFocusElevation(),
    hoverElevation: button._getHoverElevation(),
    highlightElevation: button._getHighlightElevation(),
    onPressed: button.onPressed,
    shape: shape,
    icon: Icon(button.icon, color: foreground),
    label: AuraText(
      child: Text(
        button.text ?? '',
        style: .new(color: foreground, fontWeight: fontWeight),
      ),
    ),
  );
}

class const _AuraFabRegular({
  required final AuraFloatingActionButton button,
  required final Color background,
  required final Color foreground,
  required final ShapeBorder shape,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => _AuraFabRegularData(
    button: button,
    background: background,
    foreground: foreground,
    shape: shape,
  ).child;
}

class _AuraFabRegularData extends StatelessWidget {
  new({
    required AuraFloatingActionButton button,
    required Color background,
    required Color foreground,
    required ShapeBorder shape,
  }) : this.fromFab(
         button: button,
         fab: FloatingActionButton(
           child: Icon(
             button.icon,
             size: button._getIconPixels(),
             color: foreground,
           ),
           tooltip: button.tooltip,
           foregroundColor: foreground,
           backgroundColor: background,
           heroTag: button.heroTag,
           elevation: button._getElevation(),
           focusElevation: button._getFocusElevation(),
           hoverElevation: button._getHoverElevation(),
           highlightElevation: button._getHighlightElevation(),
           onPressed: button.onPressed,
           shape: shape,
         ),
       );

  new fromFab({required this.button, required this.fab})
    : child =
          button.size == AuraFABSize.mini || button.size == AuraFABSize.large
          ? SizedBox(
              width: button._getFABSize(),
              height: button._getFABSize(),
              child: fab,
            )
          : fab;

  final AuraFloatingActionButton button;
  final FloatingActionButton fab;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// The size of a [AuraFloatingActionButton].
enum AuraFABSize {
  /// Mini FAB (40x40).
  mini,

  /// Regular FAB (56x56) - default.
  regular,

  /// Large FAB (72x72).
  large,

  /// Extended FAB with text.
  extended,
}
