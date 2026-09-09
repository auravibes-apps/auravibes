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
    if (transition == AuraContentTransition.none ||
        !TickerMode.valuesOf(context).enabled ||
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return child;
    }

    return AnimatedSwitcher(
      child: child,
      duration: DesignDuration.fast,
      transitionBuilder: (child, animation) => switch (transition) {
        .fade => FadeTransition(opacity: animation, child: child),
        .slide => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
        .scale => ScaleTransition(scale: animation, child: child),
        .none => child,
      },
    );
  }
}
