import 'dart:async';

import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A message delivery status indicator component.
///
/// This component displays the delivery status of messages with appropriate
/// icons and colors, typically used alongside message bubbles.
class AuraMessageStatus extends StatefulWidget {
  /// Creates a Aura message status indicator.
  const AuraMessageStatus({
    required this.status,
    super.key,
    this.size = AuraMessageStatusSize.medium,
    this.color,
    this.showAnimation = true,
  });

  /// The current message status.
  final AuraMessageDeliveryStatus status;

  /// The size of the status indicator.
  final AuraMessageStatusSize size;

  /// Custom color for the status indicator. If null, uses status-appropriate
  /// colors.
  final Color? color;

  /// Whether to show animations for status changes.
  final bool showAnimation;

  @override
  State<AuraMessageStatus> createState() => _AuraMessageStatusState();
}

class _AuraMessageStatusState extends State<AuraMessageStatus>
    with TickerProviderStateMixin {
  AnimationController? _rotationController;
  AnimationController? _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    if (!widget.showAnimation) return;

    if (widget.status == AuraMessageDeliveryStatus.sending) {
      _rotationController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );

      _rotationAnimation = Tween<double>(
        begin: 0,
        end: 1,
      ).animate(_rotationController!);

      unawaited(_rotationController!.repeat());
    } else {
      _scaleController = AnimationController(
        duration: DesignDuration.normal,
        vsync: this,
      );

      _scaleAnimation =
          Tween<double>(
            begin: 0,
            end: 1,
          ).animate(
            CurvedAnimation(
              parent: _scaleController!,
              curve: Curves.elasticOut,
            ),
          );

      unawaited(_scaleController!.forward());
    }
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

  void _disposeControllers() {
    _rotationController?.dispose();
    _scaleController?.dispose();
    _rotationController = null;
    _scaleController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final icon = _getStatusIcon();
    final color = widget.color ?? _getStatusColor(auraColors);

    Widget statusIcon = Icon(
      icon,
      size: _getIconSize(),
      color: color,
      semanticLabel: _getSemanticLabel(),
    );

    if (widget.showAnimation) {
      if (widget.status == AuraMessageDeliveryStatus.sending &&
          _rotationController != null) {
        // Rotating animation for sending status
        statusIcon = AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: child,
            );
          },
          child: statusIcon,
        );
      } else if (_scaleController != null) {
        // Scale animation for other statuses
        statusIcon = AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: statusIcon,
        );
      }
    }

    return Container(
      padding: EdgeInsets.all(_getPadding()),
      child: statusIcon,
    );
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
      AuraMessageStatusSize.small => 2.0,
      AuraMessageStatusSize.medium => 4.0,
      AuraMessageStatusSize.large => 6.0,
    };
  }

  String _getSemanticLabel() {
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

  /// The message was interrupted before completion (e.g. app crash, network
  /// loss). Loaded from DB with truncated content.
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
