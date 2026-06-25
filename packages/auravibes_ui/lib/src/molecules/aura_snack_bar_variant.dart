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
  const AuraSnackBarHost({
    required this.child,
    super.key,
  });

  /// The subtree that can show Aura snackbars.
  final Widget child;

  static _AuraSnackBarHostState? _maybeOf(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_AuraSnackBarHostScope>();
    final scope = element?.widget as _AuraSnackBarHostScope?;

    return scope?.state;
  }

  @override
  State<AuraSnackBarHost> createState() => _AuraSnackBarHostState();
}

class _AuraSnackBarHostState extends State<AuraSnackBarHost> {
  var _nextSnackBarId = 0;
  int? _activeSnackBarId;
  Widget? _activeSnackBar;

  @override
  void dispose() {
    _removeActiveSnackBarImmediately();
    super.dispose();
  }

  AuraSnackBarController show({
    required Widget content,
    required Color backgroundColor,
    required Color foregroundColor,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final snackBarId = _nextSnackBarId++;
    var isDismissing = false;

    void dismissWithCleanup() {
      if (isDismissing) return;
      isDismissing = true;
      if (snackBarId != _activeSnackBarId || !mounted) return;
      setState(() {
        _activeSnackBarId = null;
        _activeSnackBar = null;
      });
    }

    final snackbarWidget = _AuraSnackBarOverlayEntry(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      content: content,
      dismissCallback: dismissWithCleanup,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );

    setState(() {
      _activeSnackBarId = snackBarId;
      _activeSnackBar = snackbarWidget;
    });

    return AuraSnackBarController(
      dismissCallback: dismissWithCleanup,
    );
  }

  void _removeActiveSnackBarImmediately() {
    if (_activeSnackBar == null) return;

    _activeSnackBarId = null;
    _activeSnackBar = null;
  }

  @override
  Widget build(BuildContext context) {
    final activeSnackBar = _activeSnackBar;

    return _AuraSnackBarHostScope(
      state: this,
      child: Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.passthrough,
        children: [
          widget.child,
          ?activeSnackBar,
        ],
      ),
    );
  }
}

class _AuraSnackBarHostScope extends InheritedWidget {
  const _AuraSnackBarHostScope({
    required this.state,
    required super.child,
  });

  final _AuraSnackBarHostState state;

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
/// This controller is returned from [showAuraSnackBar] to provide
/// control over the snackbar after it's been shown.
class AuraSnackBarController {
  /// Creates a controller with the dismiss callback.
  AuraSnackBarController({
    required this._dismissCallback,
  });

  final void Function() _dismissCallback;

  /// Closes the snackbar, removing it from the overlay.
  void close() {
    _dismissCallback();
  }
}

/// Shows an Aura-styled snackbar notification in the nearest
/// [AuraSnackBarHost].
///
/// Displays a custom snackbar overlay with Aura theming based on the provided
/// [variant]. The snackbar auto-dismisses after [duration] and can include
/// an optional action button.
///
/// This implementation avoids Material's [SnackBar] visual styling while
/// keeping notification behavior scoped to the nearest host surface.
AuraSnackBarController showAuraSnackBar({
  required BuildContext context,
  required Widget content,
  AuraSnackBarVariant variant = AuraSnackBarVariant.default_,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final host = AuraSnackBarHost._maybeOf(context);
  if (host == null) {
    throw FlutterError(
      'showAuraSnackBar requires an AuraSnackBarHost ancestor.\n'
      'Wrap the app, window, navigator, or pane that owns snackbar behavior '
      'with AuraSnackBarHost.',
    );
  }

  final colors = context.auraColors;
  final backgroundColor = _getBackgroundColor(variant, colors);
  final foregroundColor = _getForegroundColor(variant, colors);

  // Validate duration is within bounds (1-60 seconds).
  final validatedDuration = Duration(
    seconds: duration.inSeconds.clamp(1, 60),
  );

  return host.show(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    content: content,
    duration: validatedDuration,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

/// Internal widget that manages its own animation state.
class _AuraSnackBarOverlayEntry extends StatefulWidget {
  const _AuraSnackBarOverlayEntry({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.content,
    required this.dismissCallback,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Widget content;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback dismissCallback;

  @override
  State<_AuraSnackBarOverlayEntry> createState() =>
      _AuraSnackBarOverlayEntryState();
}

class _AuraSnackBarOverlayEntryState extends State<_AuraSnackBarOverlayEntry>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;
  Timer? _dismissTimer;
  bool _isDismissed = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller.
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController = animationController;

    // Set up slide animation (slide up from bottom).
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Set up fade animation.
    _fadeAnimation =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOut,
          ),
        );

    // Start entry animation.
    unawaited(animationController.forward());

    // Set up auto-dismiss timer.
    _dismissTimer = Timer(widget.duration, dismiss);
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

  @override
  Widget build(BuildContext context) {
    final actionLabel = widget.actionLabel;
    final slideAnimation = _slideAnimation;
    final fadeAnimation = _fadeAnimation;

    if (slideAnimation == null || fadeAnimation == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.paddingOf(context).bottom + 16,
      child: SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Semantics(
            child: Material(
              color: DesignColors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: context.auraColors.shadow.withValues(alpha: 0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        // Content.
                        Expanded(
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: widget.foregroundColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            child: widget.content,
                          ),
                        ),
                        // Action button.
                        if (actionLabel != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: Text(
                                actionLabel,
                                style: TextStyle(
                                  color: widget.foregroundColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () {
                              widget.onAction?.call();
                              dismiss();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            container: true,
            liveRegion: true,
          ),
        ),
      ),
    );
  }
}

/// Gets the background color for a snackbar variant.
Color _getBackgroundColor(AuraSnackBarVariant variant, AuraColorScheme colors) {
  return switch (variant) {
    AuraSnackBarVariant.default_ => colors.surfaceVariant,
    AuraSnackBarVariant.success => colors.success,
    AuraSnackBarVariant.error => colors.error,
    AuraSnackBarVariant.warning => colors.warning,
    AuraSnackBarVariant.info => colors.info,
  };
}

/// Gets the foreground (text) color for a snackbar variant.
Color _getForegroundColor(AuraSnackBarVariant variant, AuraColorScheme colors) {
  return switch (variant) {
    AuraSnackBarVariant.default_ => colors.onSurfaceVariant,
    AuraSnackBarVariant.success => colors.onSuccess,
    AuraSnackBarVariant.error => colors.onError,
    AuraSnackBarVariant.warning => colors.onWarning,
    AuraSnackBarVariant.info => colors.onInfo,
  };
}
