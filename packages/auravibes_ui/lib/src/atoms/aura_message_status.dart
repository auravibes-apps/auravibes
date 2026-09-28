import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

const double _fullTurnRadians = 2 * 3.14159;

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
  Widget build(BuildContext context) => _AuraMessageStatusView(
    status: widget,
    colors: context.auraColors,
    rotationController: _rotationController,
    rotationAnimation: _rotationAnimation,
    scaleController: _scaleController,
    scaleAnimation: _scaleAnimation,
  );
}

extension on _AuraMessageStatusState {
  void _setupAnimations() {
    if (!widget.showAnimation) return;

    if (widget.status == AuraMessageDeliveryStatus.sending) {
      _startRotationAnimation();

      return;
    }

    _startScaleAnimation();
  }

  void _startRotationAnimation() {
    final controller = _newController(const Duration(milliseconds: 1000));
    _rotationController = controller;
    _rotationAnimation = _rotationTween(controller);
    final _ = controller.repeat();
  }

  void _startScaleAnimation() {
    final controller = _newController(DesignDuration.normal);
    _scaleController = controller;
    _scaleAnimation = _scaleTween(controller);
    final _ = controller.forward();
  }

  AnimationController _newController(Duration duration) =>
      AnimationController(duration: duration, vsync: this);

  Animation<double> _rotationTween(AnimationController controller) =>
      Tween<double>(begin: 0, end: 1).animate(controller);

  Animation<double> _scaleTween(AnimationController controller) =>
      Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));

  void _disposeControllers() {
    _rotationController?.dispose();
    _scaleController?.dispose();
    _rotationController = null;
    _scaleController = null;
    _rotationAnimation = null;
    _scaleAnimation = null;
  }
}

class _AuraMessageStatusView extends StatelessWidget {
  new({
    required AuraMessageStatus status,
    required AuraColorScheme colors,
    required AnimationController? rotationController,
    required Animation<double>? rotationAnimation,
    required AnimationController? scaleController,
    required Animation<double>? scaleAnimation,
  }) : _child = Container(
         padding: EdgeInsets.all(_statusPadding(status.size)),
         child: _AuraMessageStatusIcon(
           status: status,
           colors: colors,
           rotationController: rotationController,
           rotationAnimation: rotationAnimation,
           scaleController: scaleController,
           scaleAnimation: scaleAnimation,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraMessageStatusIcon extends StatelessWidget {
  new({
    required AuraMessageStatus status,
    required AuraColorScheme colors,
    required AnimationController? rotationController,
    required Animation<double>? rotationAnimation,
    required AnimationController? scaleController,
    required Animation<double>? scaleAnimation,
  }) : _child = _AuraMessageStatusAnimation(
         status: status.status,
         showAnimation: status.showAnimation,
         icon: Icon(
           _statusIcon(status.status),
           size: _statusIconSize(status.size),
           color: _statusColor(status, colors),
           semanticLabel: _statusSemanticLabel(status),
         ),
         rotationController: rotationController,
         rotationAnimation: rotationAnimation,
         scaleController: scaleController,
         scaleAnimation: scaleAnimation,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraMessageStatusAnimation extends StatelessWidget {
  const new({
    required this._status,
    required this._showAnimation,
    required this._icon,
    required this._rotationController,
    required this._rotationAnimation,
    required this._scaleController,
    required this._scaleAnimation,
  });

  final AuraMessageDeliveryStatus _status;
  final bool _showAnimation;
  final Widget _icon;
  final AnimationController? _rotationController;
  final Animation<double>? _rotationAnimation;
  final AnimationController? _scaleController;
  final Animation<double>? _scaleAnimation;

  @override
  Widget build(BuildContext context) => _AuraMessageStatusAnimationChoice(
    status: _status,
    showAnimation: _showAnimation,
    icon: _icon,
    rotationController: _rotationController,
    rotationAnimation: _rotationAnimation,
    scaleController: _scaleController,
    scaleAnimation: _scaleAnimation,
  );
}

class const _AuraMessageStatusAnimationChoice({
  required final AuraMessageDeliveryStatus status,
  required final bool showAnimation,
  required final Widget icon,
  required final AnimationController? rotationController,
  required final Animation<double>? rotationAnimation,
  required final AnimationController? scaleController,
  required final Animation<double>? scaleAnimation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => showAnimation
      ? _AuraMessageStatusRotationChoice(
          status: status,
          icon: icon,
          rotationController: rotationController,
          rotationAnimation: rotationAnimation,
          scaleController: scaleController,
          scaleAnimation: scaleAnimation,
        )
      : icon;
}

class _AuraMessageStatusRotationChoice extends StatelessWidget {
  new({
    required AuraMessageDeliveryStatus status,
    required Widget icon,
    required AnimationController? rotationController,
    required Animation<double>? rotationAnimation,
    required AnimationController? scaleController,
    required Animation<double>? scaleAnimation,
  }) : _child = switch (status) {
         .sending => _AuraMessageStatusRotationOrScale(
           icon: icon,
           rotationController: rotationController,
           rotationAnimation: rotationAnimation,
           scaleController: scaleController,
           scaleAnimation: scaleAnimation,
         ),
         _ => _AuraMessageStatusScaleChoice(
           icon: icon,
           scaleController: scaleController,
           scaleAnimation: scaleAnimation,
         ),
       };

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraMessageStatusRotationOrScale({
  required final Widget icon,
  required final AnimationController? rotationController,
  required final Animation<double>? rotationAnimation,
  required final AnimationController? scaleController,
  required final Animation<double>? scaleAnimation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rotation = rotationAnimation;
    if (rotationController != null && rotation != null) {
      return _AuraMessageStatusRotation(icon: icon, animation: rotation);
    }

    return _AuraMessageStatusScaleChoice(
      icon: icon,
      scaleController: scaleController,
      scaleAnimation: scaleAnimation,
    );
  }
}

class const _AuraMessageStatusScaleChoice({
  required final Widget icon,
  required final AnimationController? scaleController,
  required final Animation<double>? scaleAnimation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = scaleController;
    final animation = scaleAnimation;
    if (controller == null || animation == null) return icon;

    return _AuraMessageStatusScale(icon: icon, animation: animation);
  }
}

class const _AuraMessageStatusRotation({
  required final Widget icon,
  required final Animation<double> animation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Transform.rotate(
      angle: animation.value * _fullTurnRadians,
      child: child,
    ),
    child: icon,
  );
}

class const _AuraMessageStatusScale({
  required final Widget icon,
  required final Animation<double> animation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) =>
        Transform.scale(scale: animation.value, child: child),
    child: icon,
  );
}

IconData _statusIcon(AuraMessageDeliveryStatus status) => switch (status) {
  .sending => Icons.access_time,
  .unfinished => Icons.more_horiz,
  .sent => Icons.done,
  .delivered => Icons.done_all,
  .read => Icons.done_all,
  .error => Icons.error_outline,
};

Color _statusColor(AuraMessageStatus status, AuraColorScheme colors) {
  final explicitColor = status.color;
  if (explicitColor != null) return explicitColor;

  final tint = status.tint;
  if (tint != null) return colors.colorFor(tint);

  return _statusDefaultColor(status.status, colors);
}

Color _statusDefaultColor(
  AuraMessageDeliveryStatus status,
  AuraColorScheme colors,
) => switch (status) {
  .sending => colors.onSurfaceVariant.withValues(alpha: 0.6),
  .unfinished => colors.warning.withValues(alpha: 0.8),
  .sent => colors.onSurfaceVariant,
  .delivered => colors.info,
  .read => colors.success,
  .error => colors.error,
};

double _statusIconSize(AuraMessageStatusSize size) => switch (size) {
  .small => 12.0,
  .medium => 16.0,
  .large => 20.0,
};

double _statusPadding(AuraMessageStatusSize size) => switch (size) {
  .small => _AuraMessageStatusState._smallPadding,
  .medium => _AuraMessageStatusState._mediumPadding,
  .large => _AuraMessageStatusState._largePadding,
};

String _statusSemanticLabel(AuraMessageStatus status) {
  final semanticLabel = status.semanticLabel;
  if (semanticLabel != null) return semanticLabel;

  return switch (status.status) {
    .sending => 'Message is being sent',
    .unfinished => 'Message was interrupted before completion',
    .sent => 'Message sent successfully',
    .delivered => 'Message delivered',
    .read => 'Message read by recipient',
    .error => 'Message failed to send',
  };
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
