// Required: Component callbacks stay colocated with UI state.
// Required: UI package exposes top-level helpers and constants.

import 'dart:async';

import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Owns Aura snackbar lifecycle for a visual surface.
///
/// Place one host near each app window, navigator, or pane that should manage
/// its own active snackbar.
class AuraSnackBarHost extends StatefulWidget {
  /// Creates a snackbar host for [child].
  const new({required this.child, super.key});

  /// The subtree that can show Aura snackbars.
  final Widget child;

  @override
  State<AuraSnackBarHost> createState() => _AuraSnackBarHostState();

  static _AuraSnackBarHostState? _maybeOf(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_AuraSnackBarHostScope>();
    final scope = element?.widget as _AuraSnackBarHostScope?;

    return scope?.state;
  }
}

class _AuraSnackBarHostState extends State<AuraSnackBarHost> {
  var _nextSnackBarId = 0;
  int? _activeSnackBarId;
  int? _dismissingSnackBarId;
  Widget? _activeSnackBar;

  @override
  void dispose() {
    _removeActiveSnackBarImmediately();
    super.dispose();
  }

  AuraSnackBarController show(_AuraSnackBarRequest request) {
    final snackBarId = _nextSnackBarId++;
    _activateSnackBar(snackBarId, request);

    return AuraSnackBarController(
      dismissCallback: () => _dismissSnackBar(snackBarId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSnackBar = _activeSnackBar;

    return _AuraSnackBarHostScope(
      state: this,
      child: Stack(
        alignment: Alignment.topLeft,
        fit: .passthrough,
        children: [widget.child, ?activeSnackBar],
      ),
    );
  }

  void _activateSnackBar(int snackBarId, _AuraSnackBarRequest request) {
    final snackbarWidget = _AuraSnackBarOverlayEntry(
      request: request,
      dismissCallback: () => _dismissSnackBar(snackBarId),
    );

    setState(() {
      _activeSnackBarId = snackBarId;
      _activeSnackBar = snackbarWidget;
    });
  }

  void _removeActiveSnackBarImmediately() {
    if (_activeSnackBar == null) return;

    _activeSnackBarId = null;
    _activeSnackBar = null;
  }

  void _dismissSnackBar(int snackBarId) {
    if (_dismissingSnackBarId == snackBarId) return;
    _dismissingSnackBarId = snackBarId;
    if (snackBarId != _activeSnackBarId || !mounted) return;
    setState(() {
      _activeSnackBarId = null;
      _activeSnackBar = null;
    });
  }
}

class const _AuraSnackBarHostScope({
  required final _AuraSnackBarHostState state,
  required super.child,
}) extends InheritedWidget {
  @override
  bool updateShouldNotify(_AuraSnackBarHostScope oldWidget) {
    return false;
  }
}

/// Semantic variants for snackbar notifications.
enum AuraSnackBarVariant {
  /// Default appearance using surface colors.
  default_,

  /// Success message with green accent.
  success,

  /// Error message with red accent.
  error,

  /// Warning message with yellow accent.
  warning,

  /// Info message with blue accent.
  info,
}

/// Controller for managing custom Aura snackbar lifecycle.
///
/// This controller is returned from [AuraSnackBars.show] to provide
/// control over the snackbar after it's been shown.
class AuraSnackBarController {
  /// Creates a controller with the dismiss callback.
  new({required this._dismissCallback});

  final void Function() _dismissCallback;

  /// Closes the snackbar, removing it from the overlay.
  void close() {
    _dismissCallback();
  }
}

/// Provides a static API for showing an Aura-styled snackbar notification.
abstract final class AuraSnackBars {
  const new _();

  /// Shows a snackbar in the nearest [AuraSnackBarHost].
  ///
  /// Displays a themed overlay, auto-dismissed after its duration, with an
  /// optional action.
  // Public named arguments preserve the existing snackbar API.
  // ignore: number-of-parameters
  static AuraSnackBarController show({
    required BuildContext context,
    required Widget content,
    AuraSnackBarVariant variant = AuraSnackBarVariant.default_,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) => _showSnackBar(
    .new(
      context: context,
      content: content,
      variant: variant,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );

  @override
  String toString() => 'AuraSnackBars';
}

class _AuraSnackBarShowRequest {
  const new({
    required this.context,
    required this.content,
    required this.variant,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });

  final BuildContext context;
  final Widget content;
  final AuraSnackBarVariant variant;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
}

AuraSnackBarController _showSnackBar(_AuraSnackBarShowRequest request) {
  final host = _requiredSnackBarHost(request.context);

  return host.show(_AuraSnackBarRequestData(request).value);
}

class _AuraSnackBarRequestData {
  new(_AuraSnackBarShowRequest request)
    : value = _AuraSnackBarRequest(
        backgroundColor: _getBackgroundColor(
          request.variant,
          request.context.auraColors,
        ),
        foregroundColor: _getForegroundColor(
          request.variant,
          request.context.auraColors,
        ),
        content: request.content,
        duration: _validatedSnackBarDuration(request.duration),
        actionLabel: request.actionLabel,
        onAction: request.onAction,
      );

  final _AuraSnackBarRequest value;
}

class _AuraSnackBarRequest {
  const new({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.content,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Widget content;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
}

_AuraSnackBarHostState _requiredSnackBarHost(BuildContext context) {
  final host = AuraSnackBarHost._maybeOf(context);
  if (host != null) return host;

  throw FlutterError(
    'showAuraSnackBar requires an AuraSnackBarHost ancestor.\n'
    'Wrap the app, window, navigator, or pane that owns snackbar behavior '
    'with AuraSnackBarHost.',
  );
}

Duration _validatedSnackBarDuration(Duration duration) {
  if (duration < const Duration(seconds: 1)) {
    return const Duration(seconds: 1);
  }
  if (duration > const Duration(seconds: 60)) {
    return const Duration(seconds: 60);
  }

  return duration;
}

/// Internal widget that manages its own animation state.
class const _AuraSnackBarOverlayEntry({
  required final _AuraSnackBarRequest request,
  required final VoidCallback dismissCallback,
}) extends StatefulWidget {
  @override
  State<_AuraSnackBarOverlayEntry> createState() =>
      _AuraSnackBarOverlayEntryState();
}

class _AuraSnackBarOverlayEntryState extends State<_AuraSnackBarOverlayEntry>
    with SingleTickerProviderStateMixin {
  static const _horizontalInset = 16.0;
  static const _contentFontSize = 14.0;
  static const _actionGap = 8.0;
  static const _actionVerticalPadding = 4.0;
  static const _actionHorizontalPadding = 8.0;
  static const _contentVerticalPadding = 14.0;
  static const _bottomInset = 16.0;
  AnimationController? _animationController;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;
  Timer? _dismissTimer;
  bool _isDismissed = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    final animationController = _createAnimationController();
    _animationController = animationController;
    _slideAnimation = _createSlideAnimation(animationController);
    _fadeAnimation = _createFadeAnimation(animationController);
    final _ = animationController.forward();
    _dismissTimer = .new(widget.request.duration, dismiss);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dismissTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  /// Dismisses the snackbar with animation.
  void dismiss() {
    if (_isDismissed || _isDisposed) return;
    _isDismissed = true;
    _dismissTimer?.cancel();
    final animationController = _animationController;
    if (animationController == null) {
      widget.dismissCallback();

      return;
    }
    unawaited(_reverseAndDismiss(animationController));
  }

  @override
  Widget build(BuildContext context) {
    final slideAnimation = _slideAnimation;
    final fadeAnimation = _fadeAnimation;

    if (slideAnimation == null || fadeAnimation == null) {
      return const SizedBox.shrink();
    }

    return _AuraSnackBarAnimated.fromEntry(
      entry: widget,
      slideAnimation: slideAnimation,
      fadeAnimation: fadeAnimation,
      onDismiss: dismiss,
    );
  }

  AnimationController _createAnimationController() => AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  Animation<Offset> _createSlideAnimation(AnimationController controller) =>
      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );

  Animation<double> _createFadeAnimation(AnimationController controller) =>
      Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

  Future<void> _reverseAndDismiss(
    AnimationController animationController,
  ) async {
    try {
      await animationController.reverse().orCancel;
    } on TickerCanceled {
      // Ignore ticker cancellations caused by widget disposal during animation.
      return;
    }

    // Only call dismiss callback - don't dispose here.
    // As dispose() will be called by the framework.
    widget.dismissCallback();
  }
}

class _AuraSnackBarAnimated extends StatelessWidget {
  const new({required this.child});

  new fromEntry({
    required _AuraSnackBarOverlayEntry entry,
    required Animation<Offset> slideAnimation,
    required Animation<double> fadeAnimation,
    required VoidCallback onDismiss,
  }) : this(
         child: _AuraSnackBarTransitions(
           entry: entry,
           slideAnimation: slideAnimation,
           fadeAnimation: fadeAnimation,
           onDismiss: onDismiss,
         ),
       );

  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: _AuraSnackBarOverlayEntryState._horizontalInset,
    right: _AuraSnackBarOverlayEntryState._horizontalInset,
    bottom:
        MediaQuery.paddingOf(context).bottom +
        _AuraSnackBarOverlayEntryState._bottomInset,
    child: child,
  );
}

class const _AuraSnackBarTransitions({
  required final _AuraSnackBarOverlayEntry entry,
  required final Animation<Offset> slideAnimation,
  required final Animation<double> fadeAnimation,
  required final VoidCallback onDismiss,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SlideTransition(
    position: slideAnimation,
    child: FadeTransition(
      opacity: fadeAnimation,
      child: _AuraSnackBarSurface(entry: entry, onDismiss: onDismiss),
    ),
  );
}

class const _AuraSnackBarSurface({
  required final _AuraSnackBarOverlayEntry entry,
  required final VoidCallback onDismiss,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: Material(
      color: DesignColors.transparent,
      child: _AuraSnackBarContainer(entry: entry, onDismiss: onDismiss),
    ),
    container: true,
    liveRegion: true,
  );
}

class const _AuraSnackBarContainer({
  required final _AuraSnackBarOverlayEntry entry,
  required final VoidCallback onDismiss,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: _snackBarDecoration(context, entry.request.backgroundColor),
    child: _AuraSnackBarPadding(entry: entry, onDismiss: onDismiss),
  );
}

BoxDecoration _snackBarDecoration(
  BuildContext context,
  Color backgroundColor,
) => BoxDecoration(
  color: backgroundColor,
  borderRadius: const BorderRadius.all(.circular(12)),
  boxShadow: [
    BoxShadow(
      color: context.auraColors.shadow.withValues(alpha: 0.15),
      offset: const Offset(0, 4),
      blurRadius: 10,
    ),
  ],
);

class const _AuraSnackBarPadding({
  required final _AuraSnackBarOverlayEntry entry,
  required final VoidCallback onDismiss,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: _AuraSnackBarOverlayEntryState._contentVerticalPadding,
        horizontal: 16,
      ),
      child: _AuraSnackBarRow.fromEntry(entry: entry, onDismiss: onDismiss),
    ),
  );
}

class _AuraSnackBarRow extends StatelessWidget {
  const new({required this.content, required this.action});

  new fromEntry({
    required _AuraSnackBarOverlayEntry entry,
    required VoidCallback onDismiss,
  }) : this(
         content: DefaultTextStyle(
           style: .new(
             color: entry.request.foregroundColor,
             fontSize: _AuraSnackBarOverlayEntryState._contentFontSize,
             fontWeight: FontWeight.w500,
           ),
           child: entry.request.content,
         ),
         action: switch (entry.request.actionLabel) {
           final label? => _AuraSnackBarAction(
             label: label,
             foregroundColor: entry.request.foregroundColor,
             onAction: entry.request.onAction,
             onDismiss: onDismiss,
           ),
           null => null,
         },
       );

  final Widget content;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: content),
      ?action,
    ],
  );
}

class const _AuraSnackBarAction({
  required final String label,
  required final Color foregroundColor,
  required final VoidCallback? onAction,
  required final VoidCallback onDismiss,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      const SizedBox(width: _AuraSnackBarOverlayEntryState._actionGap),
      GestureDetector(
        child: _AuraSnackBarActionContent.fromValues(
          label: label,
          foregroundColor: foregroundColor,
        ),
        onTap: _handleTap,
      ),
    ],
  );

  void _handleTap() {
    onAction?.call();
    onDismiss();
  }
}

class _AuraSnackBarActionContent extends StatelessWidget {
  const new({required this.child});

  new fromValues({required String label, required Color foregroundColor})
    : this(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: _AuraSnackBarOverlayEntryState._actionVerticalPadding,
            horizontal: _AuraSnackBarOverlayEntryState._actionHorizontalPadding,
          ),
          child: Text(
            label,
            style: .new(
              color: foregroundColor,
              fontSize: _AuraSnackBarOverlayEntryState._contentFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Gets the background color for a snackbar variant.
Color _getBackgroundColor(AuraSnackBarVariant variant, AuraColorScheme colors) {
  return switch (variant) {
    .default_ => colors.surfaceVariant,
    .success => colors.success,
    .error => colors.error,
    .warning => colors.warning,
    .info => colors.info,
  };
}

/// Gets the foreground (text) color for a snackbar variant.
Color _getForegroundColor(AuraSnackBarVariant variant, AuraColorScheme colors) {
  return switch (variant) {
    .default_ => colors.onSurfaceVariant,
    .success => colors.onSuccess,
    .error => colors.onError,
    .warning => colors.onWarning,
    .info => colors.onInfo,
  };
}
// Public convenience API intentionally remains top-level.
