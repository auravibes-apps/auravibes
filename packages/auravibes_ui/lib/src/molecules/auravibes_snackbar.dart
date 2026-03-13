import 'dart:async';

import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:flutter/material.dart';

/// Semantic variants for snackbar notifications.
enum AuraSnackBarVariant {
  /// Default appearance using surface colors
  default_,

  /// Success message with green accent
  success,

  /// Error message with red accent
  error,

  /// Warning message with yellow accent
  warning,

  /// Info message with blue accent
  info,
}

/// Controller for managing custom Aura snackbar lifecycle.
///
/// This controller is returned from [showAuraSnackBar] to provide
/// control over the snackbar after it's been shown.
class AuraSnackBarController {
  /// Creates a controller with the dismiss callback.
  AuraSnackBarController({
    required void Function() dismissCallback,
  }) : _dismissCallback = dismissCallback;

  final void Function() _dismissCallback;

  /// Closes the snackbar, removing it from the overlay.
  void close() {
    _dismissCallback();
  }
}

/// Shows an Aura-styled snackbar notification using custom OverlayEntry.
///
/// Displays a custom snackbar overlay with Aura theming based on the provided
/// [variant]. The snackbar auto-dismisses after [duration] and can include
/// an optional action button.
///
/// This implementation uses [OverlayEntry] instead of Material's [SnackBar]
/// to remove Material visual styling while keeping notification behavior.
AuraSnackBarController showAuraSnackBar({
  required BuildContext context,
  required Widget content,
  AuraSnackBarVariant variant = AuraSnackBarVariant.default_,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = context.auraColors;
  final backgroundColor = _getBackgroundColor(variant, colors);
  final foregroundColor = _getForegroundColor(variant, colors);

  // Validate duration is within bounds (1-60 seconds)
  final validatedDuration = Duration(
    seconds: duration.inSeconds.clamp(1, 60),
  );

  // Get overlay state - use maybeOf with rootOverlay
  // to avoid appearing under dialogs
  final overlayState = Overlay.maybeOf(context, rootOverlay: true);
  if (overlayState == null) {
    throw FlutterError(
      'showAuraSnackBar requires an Overlay in the widget tree.\n'
      'Ensure your app uses MaterialApp, CupertinoApp, or has an '
      'Overlay widget above the provided BuildContext.',
    );
  }

  // Track overlay entry for removal
  late final OverlayEntry entry;

  // Guard flag to prevent double-removal
  var isDismissing = false;

  // Create dismiss callback that removes the overlay
  void dismissWithCleanup() {
    if (isDismissing) return;
    isDismissing = true;
    entry.remove();
  }

  // Create the snackbar widget with internal state management
  final snackbarWidget = _AuraSnackBarOverlayEntry(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    content: content,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: validatedDuration,
    dismissCallback: dismissWithCleanup,
  );

  // Create overlay entry
  entry = OverlayEntry(builder: (context) => snackbarWidget);

  // Insert the overlay entry
  overlayState.insert(entry);

  return AuraSnackBarController(
    dismissCallback: dismissWithCleanup,
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
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  bool _isDismissed = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Set up slide animation (slide up from bottom)
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Set up fade animation
    _fadeAnimation =
        Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
        );

    // Start entry animation
    unawaited(_animationController.forward());

    // Set up auto-dismiss timer
    _dismissTimer = Timer(widget.duration, dismiss);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Dismisses the snackbar with animation.
  void dismiss() {
    if (_isDismissed || _isDisposed) return;
    _isDismissed = true;
    _dismissTimer?.cancel();
    unawaited(
      _animationController
          .reverse()
          .orCancel
          .then((_) {
            // Only call dismiss callback - don't dispose here
            // as dispose() will be called by the framework
            widget.dismissCallback();
          })
          .catchError((Object error) {
            // Ignore ticker cancellations caused by widget disposal
            // during animation.
            if (error is TickerCanceled) return;
            // ignore: only_throw_errors - re-throwing non-cancellation errors
            throw error;
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Content
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
                      // Action button
                      if (widget.actionLabel != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            // Use provided callback or default no-op
                            (widget.onAction ?? () {})();
                            dismiss();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              widget.actionLabel!,
                              style: TextStyle(
                                color: widget.foregroundColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
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
