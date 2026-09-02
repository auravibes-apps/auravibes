import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A message delivery status indicator component.
///
/// This component displays the delivery status of messages with appropriate
/// icons and colors, typically used alongside message bubbles.
class AuraMessageStatus extends StatefulWidget {
  /// Creates a Aura message status indicator.
  const new({
    required this.status,
    super.key,
    this.size = AuraMessageStatusSize.medium,
    this.tint,
    this.color,
    this.showAnimation = true,
    this.semanticLabel,
  });

  /// The current message status.
  final AuraMessageDeliveryStatus status;

  /// The size of the status indicator.
  final AuraMessageStatusSize size;

  /// Tint for the status indicator. If null, uses status-appropriate colors.
  final AuraTint? tint;

  /// Legacy explicit color override. Prefer [tint] for theme-aware colors.
  final Color? color;

  /// Whether to show animations for status changes.
  final bool showAnimation;

  /// A semantic label announced by assistive technologies.
  final String? semanticLabel;

  @override
  State<AuraMessageStatus> createState() => _AuraMessageStatusState();
}

class _AuraMessageStatusState extends State<AuraMessageStatus>
    with TickerProviderStateMixin {
  static const double _fullTurnRadians = 2 * 3.14159;
  static const _smallPadding = 2.0;
  static const _mediumPadding = 4.0;
  static const _largePadding = 6.0;
  AnimationController? _rotationController;
  AnimationController? _scaleController;
  Animation<double>? _rotationAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  void didUpdateWidget(AuraMessageStatus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.status != widget.status ||
        oldWidget.showAnimation != widget.showAnimation) {
      _disposeControllers();
      _setupAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final icon = _getStatusIcon();
    final tint = widget.tint;
    final color =
        widget.color ??
        (tint == null
            ? _getStatusColor(auraColors)
            : auraColors.colorFor(tint));

    Widget statusIcon = Icon(
      icon,
      size: _getIconSize(),
      color: color,
      semanticLabel: _getSemanticLabel(),
    );

    if (widget.showAnimation) {
      final rotationAnimation = _rotationAnimation;
      final scaleAnimation = _scaleAnimation;
      if (widget.status == AuraMessageDeliveryStatus.sending &&
          _rotationController != null &&
          rotationAnimation != null) {
        // Rotating animation for sending status.
        statusIcon = AnimatedBuilder(
          animation: rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: rotationAnimation.value * _fullTurnRadians,
              child: child,
            );
          },
          child: statusIcon,
        );
      } else if (_scaleController != null && scaleAnimation != null) {
        // Scale animation for other statuses.
        statusIcon = AnimatedBuilder(
          animation: scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: scaleAnimation.value, child: child);
          },
          child: statusIcon,
        );
      }
    }

    return Container(padding: EdgeInsets.all(_getPadding()), child: statusIcon);
  }

  void _setupAnimations() {
    if (!widget.showAnimation) return;

    if (widget.status == AuraMessageDeliveryStatus.sending) {
      final rotationController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );
      _rotationController = rotationController;

      final rotationAnimation = Tween<double>(
        begin: 0,
        end: 1,
      ).animate(rotationController);
      _rotationAnimation = rotationAnimation;

      final _ = rotationController.repeat();
    } else {
      final scaleController = AnimationController(
        duration: DesignDuration.normal,
        vsync: this,
      );
      _scaleController = scaleController;

      final scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: scaleController, curve: Curves.elasticOut),
      );
      _scaleAnimation = scaleAnimation;

      final _ = scaleController.forward();
    }
  }

  void _disposeControllers() {
    _rotationController?.dispose();
    _scaleController?.dispose();
    _rotationController = null;
    _scaleController = null;
    _rotationAnimation = null;
    _scaleAnimation = null;
  }

  IconData _getStatusIcon() {
    return switch (widget.status) {
      AuraMessageDeliveryStatus.sending => Icons.access_time,
      AuraMessageDeliveryStatus.unfinished => Icons.more_horiz,
      AuraMessageDeliveryStatus.sent => Icons.done,
      AuraMessageDeliveryStatus.delivered => Icons.done_all,
      AuraMessageDeliveryStatus.read => Icons.done_all,
      AuraMessageDeliveryStatus.error => Icons.error_outline,
    };
  }

  Color _getStatusColor(AuraColorScheme auraColors) {
    return switch (widget.status) {
      AuraMessageDeliveryStatus.sending =>
        auraColors.onSurfaceVariant.withValues(alpha: 0.6),
      AuraMessageDeliveryStatus.unfinished => auraColors.warning.withValues(
        alpha: 0.8,
      ),
      AuraMessageDeliveryStatus.sent => auraColors.onSurfaceVariant,
      AuraMessageDeliveryStatus.delivered => auraColors.info,
      AuraMessageDeliveryStatus.read => auraColors.success,
      AuraMessageDeliveryStatus.error => auraColors.error,
    };
  }

  double _getIconSize() {
    return switch (widget.size) {
      AuraMessageStatusSize.small => 12.0,
      AuraMessageStatusSize.medium => 16.0,
      AuraMessageStatusSize.large => 20.0,
    };
  }

  double _getPadding() {
    return switch (widget.size) {
      AuraMessageStatusSize.small => _smallPadding,
      AuraMessageStatusSize.medium => _mediumPadding,
      AuraMessageStatusSize.large => _largePadding,
    };
  }

  String _getSemanticLabel() {
    final semanticLabel = widget.semanticLabel;
    if (semanticLabel != null) return semanticLabel;

    return switch (widget.status) {
      AuraMessageDeliveryStatus.sending => 'Message is being sent',
      AuraMessageDeliveryStatus.unfinished =>
        'Message was interrupted before completion',
      AuraMessageDeliveryStatus.sent => 'Message sent successfully',
      AuraMessageDeliveryStatus.delivered => 'Message delivered',
      AuraMessageDeliveryStatus.read => 'Message read by recipient',
      AuraMessageDeliveryStatus.error => 'Message failed to send',
    };
  }
}

/// The delivery status of a message.
enum AuraMessageDeliveryStatus {
  /// The message is currently being sent.
  sending,

  /// The message was interrupted before completion (for example, app crash or
  /// loss). Loaded from the database with truncated content.
  unfinished,

  /// The message has been sent successfully.
  sent,

  /// The message has been delivered to the recipient.
  delivered,

  /// The message has been read by the recipient.
  read,

  /// The message failed to send.
  error,
}

/// The size of a [AuraMessageStatus].
enum AuraMessageStatusSize {
  /// A small message status indicator.
  small,

  /// A medium message status indicator (default).
  medium,

  /// A large message status indicator.
  large,
}
