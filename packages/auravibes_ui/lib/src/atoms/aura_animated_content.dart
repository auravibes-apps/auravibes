import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

part 'aura_content_transition.dart';

/// A brief fade between keyed children, disabled for reduced motion.
class AuraAnimatedContent extends StatelessWidget {
  /// Give children distinct keys when replacing content of the same type.
  const new({
    required this.child,
    super.key,
    this.transition = AuraContentTransition.fade,
  });

  /// Content to display.
  final Widget child;

  /// Requested transition; accessibility and ticker settings take precedence.
  final AuraContentTransition transition;

  @override
  Widget build(BuildContext context) {
    if (_animationsDisabled(context)) {
      return child;
    }

    return AnimatedSwitcher(
      child: child,
      duration: DesignDuration.fast,
      transitionBuilder: _buildTransition,
    );
  }

  bool _animationsDisabled(BuildContext context) =>
      transition == AuraContentTransition.none ||
      !TickerMode.valuesOf(context).enabled ||
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  Widget _buildTransition(Widget child, Animation<double> animation) {
    return _AuraAnimatedTransition(
      transition: transition,
      animation: animation,
      child: child,
    );
  }
}

class const _AuraAnimatedTransition({
  required final AuraContentTransition transition,
  required final Animation<double> animation,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (transition) {
    .fade => FadeTransition(opacity: animation, child: child),
    .slide => _AuraAnimatedSlideTransition(animation: animation, child: child),
    .scale => ScaleTransition(scale: animation, child: child),
    .none => child,
  };
}

class const _AuraAnimatedSlideTransition({
  required final Animation<double> animation,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
}
