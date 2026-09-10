// Required: Component callbacks stay colocated with UI state.
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

const _dotCount = 3;
const _stagger = 0.2;
const _animationSpan = 0.4;
const _initialScale = 0.4;
const _smallDot = 4.0;
const _mediumDot = 6.0;
const _largeDot = 8.0;

/// A typing indicator component that shows animated dots.
///
/// This component displays an animated typing indicator typically used to show
/// that the AI is processing or typing a response.
class AuraTypingIndicator extends StatefulWidget {
  /// Creates a Aura typing indicator.
  const new({
    super.key,
    this.size = AuraTypingIndicatorSize.medium,
    this.color,
    this.showContainer = true,
    this.animationDuration = const Duration(milliseconds: 600),
    this.manageAlignment = true,
    this.semanticLabel = 'AI is typing',
  });

  /// The size of the typing indicator.
  final AuraTypingIndicatorSize size;

  /// The color of the dots. If null, uses the theme's primary color.
  final Color? color;

  /// Whether to show the container background.
  final bool showContainer;

  /// The duration of the animation cycle.
  final Duration animationDuration;

  /// Whether the indicator manages its chat-side placement.
  final bool manageAlignment;

  /// A semantic label announced while typing.
  final String? semanticLabel;

  @override
  State<AuraTypingIndicator> createState() => _AuraTypingIndicatorState();
}

class _AuraTypingIndicatorState extends State<AuraTypingIndicator>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  List<Animation<double>> _dotAnimations = const [];

  @override
  void initState() {
    super.initState();
    final animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animationController = animationController;

    // Create staggered animations for each dot.
    _dotAnimations = .generate(
      _dotCount,
      (index) => _buildDotAnimation(index, animationController),
    );

    final _ = animationController.repeat();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuraTypingIndicatorView(
    indicator: widget,
    dotAnimations: _dotAnimations,
  );

  Animation<double> _buildDotAnimation(
    int index,
    AnimationController animationController,
  ) {
    return Tween<double>(begin: _initialScale, end: 1).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          index * _stagger,
          index * _stagger + _animationSpan,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}

class _AuraTypingIndicatorView extends StatelessWidget {
  _AuraTypingIndicatorView({
    required AuraTypingIndicator indicator,
    required List<Animation<double>> dotAnimations,
  }) : _child = _AuraTypingIndicatorContainer(
         indicator: indicator,
         child: Semantics(
           child: _AuraTypingIndicatorDots(
             indicator: indicator,
             dotAnimations: dotAnimations,
           ),
           label: indicator.semanticLabel,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraTypingIndicatorDots({
  required final AuraTypingIndicator indicator,
  required final List<Animation<double>> dotAnimations,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: .generate(
        _dotCount,
        (index) => _AuraTypingIndicatorDot(
          indicator: indicator,
          animation: dotAnimations[index],
        ),
      ),
    );
  }
}

class const _AuraTypingIndicatorDot({
  required final AuraTypingIndicator indicator,
  required final Animation<double> animation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = indicator.color ?? context.auraColors.onSurfaceVariant;
    final size = _dotSizeFor(indicator.size);

    return _AuraTypingIndicatorAnimatedDot(
      animation: animation,
      child: _AuraTypingIndicatorDotVisual(color: color, size: size),
    );
  }
}

class const _AuraTypingIndicatorAnimatedDot({
  required final Animation<double> animation,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) => Opacity(opacity: animation.value, child: child),
  );
}

class const _AuraTypingIndicatorDotVisual({
  required final Color color,
  required final double size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: color, shape: .circle),
    width: size,
    height: size,
    margin: EdgeInsets.symmetric(horizontal: size / 2),
  );
}

class const _AuraTypingIndicatorContainer({
  required final AuraTypingIndicator indicator,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => indicator.showContainer
      ? _AuraTypingIndicatorAlignment(
          manageAlignment: indicator.manageAlignment,
          child: _AuraTypingIndicatorBox(indicator: indicator, child: child),
        )
      : child;
}

class const _AuraTypingIndicatorAlignment({
  required final bool manageAlignment,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!manageAlignment) return child;

    return Align(alignment: AlignmentDirectional.centerStart, child: child);
  }
}

class const _AuraTypingIndicatorBox({
  required final AuraTypingIndicator indicator,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraTheme = context.auraTheme;

    return Container(
      padding: _containerPadding(indicator.size, spacing: auraTheme.spacing),
      decoration: _containerDecoration(auraTheme, context.auraColors),
      margin: _containerMargin(indicator.manageAlignment, theme: auraTheme),
      child: child,
    );
  }
}

double _dotSizeFor(AuraTypingIndicatorSize size) {
  return switch (size) {
    .small => _smallDot,
    .medium => _mediumDot,
    .large => _largeDot,
  };
}

EdgeInsets _containerPadding(
  AuraTypingIndicatorSize size, {
  required AuraSpacingScale spacing,
}) {
  return switch (size) {
    .small => _typingPadding(spacing.xs, spacing.sm),
    .medium => _typingPadding(spacing.sm, spacing.md),
    .large => _typingPadding(spacing.md, spacing.lg),
  };
}

EdgeInsets _typingPadding(double vertical, double horizontal) =>
    EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);

EdgeInsetsGeometry _containerMargin(
  bool manageAlignment, {
  required AuraTheme theme,
}) {
  return manageAlignment
      ? EdgeInsetsDirectional.only(
          start: theme.fromSpacing(.md),
          end: theme.fromSpacing(.xl),
          bottom: theme.fromSpacing(.sm),
        )
      : EdgeInsets.only(bottom: theme.fromSpacing(.sm));
}

BoxDecoration _containerDecoration(AuraTheme theme, AuraColorScheme colors) =>
    BoxDecoration(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.all(.circular(theme.fromBorderRadius(.lg)))
          .copyWith(bottomLeft: .circular(theme.fromBorderRadius(.sm))),
      boxShadow: const [DesignShadows.sm],
    );

/// The size of a [AuraTypingIndicator].
enum AuraTypingIndicatorSize {
  /// A small typing indicator.
  small,

  /// A medium typing indicator (default).
  medium,

  /// A large typing indicator.
  large,
}
