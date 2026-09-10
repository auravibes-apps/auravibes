// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

const _switchRadiusDivisor = 2.0;

/// A customizable switch component following the Aura design system.
///
/// This switch supports multiple sizes and states (on/off, disabled, loading)
/// while maintaining consistency with the design tokens.
class AuraSwitch extends StatefulWidget {
  /// The padding between the track edge and the thumb.
  /// This creates the visual gap that makes the thumb appear to float
  /// inside the track, consistent across all sizes.
  static const double _thumbPadding = 2;

  /// Creates an Aura switch.
  const new({
    required this.value,
    required this.onChanged,
    super.key,
    this.size = AuraSwitchSize.base,
    this.disabled = false,
    this.isLoading = false,
    this.semanticLabel = 'Switch',
  });

  /// Whether the switch is on or off.
  final bool value;

  /// Called when the user toggles the switch.
  ///
  /// This callback is not called when the switch is disabled or loading.
  final ValueChanged<bool>? onChanged;

  /// The size of the switch.
  final AuraSwitchSize size;

  /// Whether the switch is disabled.
  final bool disabled;

  /// Whether the switch is in a loading state.
  final bool isLoading;

  /// A semantic label announced by assistive technologies.
  final String? semanticLabel;

  @override
  State<AuraSwitch> createState() => _AuraSwitchState();
}

class _AuraSwitchState extends State<AuraSwitch> {
  static const _loadingScale = 0.6;
  static const _thumbPaddingMultiplier = 2.0;
  static const _smallTrackWidth = 36.0;
  static const _baseTrackWidth = 44.0;
  static const _largeTrackWidth = 52.0;
  static const _smallTrackHeight = 20.0;
  static const _baseTrackHeight = 24.0;
  static const _largeTrackHeight = 28.0;
  static const _smallThumbSize = 16.0;
  static const _baseThumbSize = 20.0;
  static const _largeThumbSize = 24.0;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) =>
      _AuraSwitchBuildData(this, context).child;

  void _toggle() => widget.onChanged?.call(!widget.value);

  void _setFocus(bool value) => setState(() => _isFocused = value);
}

class _AuraSwitchBuildData {
  _AuraSwitchBuildData(_AuraSwitchState state, BuildContext context)
    : child = _AuraSwitchPresentationData(
        state,
        _AuraSwitchTrackDataBuilder(state, context).value,
      ).child;

  final Widget child;
}

class _AuraSwitchPresentationData {
  _AuraSwitchPresentationData(
    _AuraSwitchState state,
    _AuraSwitchTrackData track,
  ) : child = _AuraSwitchPresentation(
        enabled: _switchIsInteractive(state.widget, track.state.isDisabled),
        value: state.widget.value,
        label: state.widget.semanticLabel,
        onToggle: state._toggle,
        onShowFocusHighlight: state._setFocus,
        track: track,
      );

  final Widget child;
}

class _AuraSwitchTrackDataBuilder {
  _AuraSwitchTrackDataBuilder(_AuraSwitchState state, BuildContext context)
    : value = _switchTrackDataForState(state, context);

  final _AuraSwitchTrackData value;
}

_AuraSwitchTrackData _switchTrackDataForState(
  _AuraSwitchState state,
  BuildContext context,
) {
  final widget = state.widget;
  final isDisabled = _switchIsDisabled(widget, context);

  return _switchTrackData((
    widget: widget,
    colors: context.auraColors,
    animation: context.auraTheme.animation.normal,
    isDisabled: isDisabled,
    isFocused: state._isFocused,
  ));
}

typedef _AuraSwitchBuildRequest = ({
  AuraSwitch widget,
  AuraColorScheme colors,
  Duration animation,
  bool isDisabled,
  bool isFocused,
});

bool _switchIsInteractive(AuraSwitch widget, bool isDisabled) =>
    !isDisabled && !widget.isLoading && widget.onChanged != null;

bool _switchIsDisabled(AuraSwitch widget, BuildContext context) =>
    widget.disabled || !AuraInteractionScope.of(context).allowsValueChanges;

_AuraSwitchTrackData _switchTrackData(_AuraSwitchBuildRequest request) {
  final widget = request.widget;

  return _AuraSwitchTrackData(
    request.colors,
    request.animation,
    _switchDimensions(widget),
    _switchPalette(widget, request.colors, request.isDisabled),
    _AuraSwitchStateData(
      isDisabled: request.isDisabled,
      isLoading: widget.isLoading,
      isFocused: request.isFocused,
    ),
  );
}

_AuraSwitchDimensions _switchDimensions(AuraSwitch widget) =>
    _AuraSwitchDimensions(
      _switchTrackWidth(widget.size),
      _switchTrackHeight(widget.size),
      _switchThumbSize(widget.size),
      AuraSwitch._thumbPadding,
      _switchThumbOffset(widget),
    );

double _switchThumbOffset(AuraSwitch widget) => widget.value
    ? _switchTrackWidth(widget.size) -
          _switchThumbSize(widget.size) -
          AuraSwitch._thumbPadding * _AuraSwitchState._thumbPaddingMultiplier
    : 0.0;

_AuraSwitchPalette _switchPalette(
  AuraSwitch widget,
  AuraColorScheme colors,
  bool isDisabled,
) => _AuraSwitchPalette(
  _switchTrackColor(widget, colors, isDisabled),
  colors.surface,
  AuraTint.primary,
);

double _switchTrackWidth(AuraSwitchSize size) => switch (size) {
  .sm => _AuraSwitchState._smallTrackWidth,
  .base => _AuraSwitchState._baseTrackWidth,
  .lg => _AuraSwitchState._largeTrackWidth,
};

double _switchTrackHeight(AuraSwitchSize size) => switch (size) {
  .sm => _AuraSwitchState._smallTrackHeight,
  .base => _AuraSwitchState._baseTrackHeight,
  .lg => _AuraSwitchState._largeTrackHeight,
};

double _switchThumbSize(AuraSwitchSize size) => switch (size) {
  .sm => _AuraSwitchState._smallThumbSize,
  .base => _AuraSwitchState._baseThumbSize,
  .lg => _AuraSwitchState._largeThumbSize,
};

Color _switchTrackColor(
  AuraSwitch widget,
  AuraColorScheme colors,
  bool isDisabled,
) {
  if (isDisabled) return colors.outlineVariant;

  return widget.value ? colors.primary : colors.outline;
}

class const _AuraSwitchDimensions(
  final double trackWidth,
  final double trackHeight,
  final double thumbSize,
  final double thumbPadding,
  final double thumbOffset,
);

class const _AuraSwitchPalette(
  final Color trackColor,
  final Color thumbColor,
  final AuraTint loadingTint,
);

class const _AuraSwitchStateData({
  required final bool isDisabled,
  required final bool isLoading,
  required final bool isFocused,
});

class const _AuraSwitchTrackData(
  final AuraColorScheme colors,
  final Duration animation,
  final _AuraSwitchDimensions dimensions,
  final _AuraSwitchPalette palette,
  final _AuraSwitchStateData state,
);

class const _AuraSwitchPresentation({
  required final bool enabled,
  required final bool value,
  required final String? label,
  required final VoidCallback onToggle,
  required final ValueChanged<bool> onShowFocusHighlight,
  required final _AuraSwitchTrackData track,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _AuraSwitchInteraction(
      enabled: enabled,
      onToggle: onToggle,
      onShowFocusHighlight: onShowFocusHighlight,
      track: _AuraSwitchTrack(track),
    ),
    enabled: enabled,
    toggled: value,
    label: label,
  );
}

class const _AuraSwitchInteraction({
  required final bool enabled,
  required final VoidCallback onToggle,
  required final ValueChanged<bool> onShowFocusHighlight,
  required final Widget track,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    enabled: enabled,
    actions: {ActivateIntent: _activateAction(onToggle)},
    onShowFocusHighlight: onShowFocusHighlight,
    mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: _AuraSwitchGesture(
      enabled: enabled,
      onToggle: onToggle,
      track: track,
    ),
  );
}

CallbackAction<ActivateIntent> _activateAction(VoidCallback onToggle) =>
    CallbackAction<ActivateIntent>(
      onInvoke: (_) {
        onToggle();

        return null;
      },
    );

class const _AuraSwitchGesture({
  required final bool enabled,
  required final VoidCallback onToggle,
  required final Widget track,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: track,
    onTap: enabled ? onToggle : null,
    behavior: .opaque,
  );
}

class const _AuraSwitchTrack(final _AuraSwitchTrackData data)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    child: Center(child: _AuraSwitchTrackSurface(data)),
  );
}

class const _AuraSwitchTrackSurface(final _AuraSwitchTrackData data)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dimensions = data.dimensions;

    return AnimatedContainer(
      padding: EdgeInsets.all(dimensions.thumbPadding),
      decoration: _trackDecoration(data),
      width: dimensions.trackWidth,
      height: dimensions.trackHeight,
      child: _AuraSwitchThumbStack(data),
      duration: data.animation,
    );
  }
}

BoxDecoration _trackDecoration(_AuraSwitchTrackData data) {
  return BoxDecoration(
    color: data.palette.trackColor,
    borderRadius: BorderRadius.circular(
      data.dimensions.trackHeight / _switchRadiusDivisor,
    ),
    boxShadow: _focusShadow(data),
  );
}

List<BoxShadow>? _focusShadow(_AuraSwitchTrackData data) {
  if (!data.state.isFocused) return null;

  return [
    BoxShadow(
      color: data.colors.primary.withValues(alpha: 0.24),
      spreadRadius: 3,
    ),
  ];
}

class const _AuraSwitchThumbStack(final _AuraSwitchTrackData data)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Stack(children: [_AuraSwitchThumb(data)]);
}

class const _AuraSwitchThumb(final _AuraSwitchTrackData data)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedPositioned(
    child: _AuraSwitchThumbSurface(data),
    left: data.dimensions.thumbOffset,
    top: 0,
    bottom: 0,
    curve: Curves.easeInOut,
    duration: data.animation,
  );
}

class const _AuraSwitchThumbSurface(final _AuraSwitchTrackData data)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dimensions = data.dimensions;
    final state = data.state;

    return AnimatedContainer(
      decoration: _thumbDecoration(data),
      width: dimensions.thumbSize,
      height: dimensions.thumbSize,
      child: state.isLoading ? _AuraSwitchLoading(data) : null,
      duration: data.animation,
    );
  }
}

BoxDecoration _thumbDecoration(_AuraSwitchTrackData data) {
  final state = data.state;

  return BoxDecoration(
    color: data.palette.thumbColor,
    boxShadow: state.isDisabled ? null : [DesignShadows.sm],
    shape: .circle,
  );
}

class const _AuraSwitchLoading(final _AuraSwitchTrackData data)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraLoadingCircle(
    tint: data.palette.loadingTint,
    size: data.dimensions.thumbSize * _AuraSwitchState._loadingScale,
  );
}

/// The size of an [AuraSwitch].
enum AuraSwitchSize {
  /// A small switch.
  sm,

  /// A base/medium switch (default).
  base,

  /// A large switch.
  lg,
}
