// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: no-equal-arguments
// Required: UI geometry uses repeated values for symmetric layout.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: prefer-extracting-callbacks
// Required: Component callbacks stay colocated with UI state.
// ignore_for_file: prefer-moving-to-variable
// Required: UI components repeat theme and layout lookups intentionally.
import 'dart:async';

import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A typing indicator component that shows animated dots.
///
/// This component displays an animated typing indicator typically used to show
/// that the AI is processing or typing a response.
class AuraTypingIndicator extends StatefulWidget {
  /// Creates a Aura typing indicator.
  const AuraTypingIndicator({
    super.key,
    this.size = AuraTypingIndicatorSize.medium,
    this.color,
    this.showContainer = true,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  /// The size of the typing indicator.
  final AuraTypingIndicatorSize size;

  /// The color of the dots. If null, uses the theme's primary color.
  final Color? color;

  /// Whether to show the container background.
  final bool showContainer;

  /// The duration of the animation cycle.
  final Duration animationDuration;

  @override
  State<AuraTypingIndicator> createState() => _AuraTypingIndicatorState();
}

class _AuraTypingIndicatorState extends State<AuraTypingIndicator>
    with TickerProviderStateMixin {
  AnimationController _animationController = throw StateError(
    '_animationController is not initialized',
  );
  List<Animation<double>> _dotAnimations = const [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Create staggered animations for each dot
    _dotAnimations = List.generate(3, (index) {
      final begin = index * 0.2; // Stagger by 20% of the animation
      final end = begin + 0.4; // Each dot animates for 40% of the cycle

      return Tween<double>(
        begin: 0.4,
        end: 1,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            begin,
            end,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    unawaited(_animationController.repeat());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final dotColor = widget.color ?? auraColors.onSurfaceVariant;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _dotAnimations[index],
          builder: (context, child) {
            return Opacity(
              opacity: _dotAnimations[index].value,
              child: Container(
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
                width: _getDotSize(),
                height: _getDotSize(),
                margin: EdgeInsets.symmetric(
                  horizontal: _getDotSpacing() / 2,
                ),
              ),
            );
          },
        );
      }),
    );

    if (!widget.showContainer) {
      return Semantics(
        child: content,
        label: 'AI is typing',
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: _getContainerPadding(),
        decoration: BoxDecoration(
          color: auraColors.surfaceVariant,
          borderRadius: const BorderRadius.all(
            Radius.circular(DesignBorderRadius.lg),
          ).copyWith(bottomLeft: const Radius.circular(DesignBorderRadius.sm)),
          boxShadow: const [DesignShadows.sm],
        ),
        margin: const EdgeInsets.only(
          left: DesignSpacing.md,
          right: DesignSpacing.xl,
          bottom: DesignSpacing.sm,
        ),
        child: Semantics(
          child: content,
          label: 'AI is typing',
        ),
      ),
    );
  }

  double _getDotSize() {
    return switch (widget.size) {
      AuraTypingIndicatorSize.small => 4.0,
      AuraTypingIndicatorSize.medium => 6.0,
      AuraTypingIndicatorSize.large => 8.0,
    };
  }

  double _getDotSpacing() {
    return switch (widget.size) {
      AuraTypingIndicatorSize.small => 4.0,
      AuraTypingIndicatorSize.medium => 6.0,
      AuraTypingIndicatorSize.large => 8.0,
    };
  }

  EdgeInsets _getContainerPadding() {
    return switch (widget.size) {
      AuraTypingIndicatorSize.small => const EdgeInsets.symmetric(
        vertical: DesignSpacing.xs,
        horizontal: DesignSpacing.sm,
      ),
      AuraTypingIndicatorSize.medium => const EdgeInsets.symmetric(
        vertical: DesignSpacing.sm,
        horizontal: DesignSpacing.md,
      ),
      AuraTypingIndicatorSize.large => const EdgeInsets.symmetric(
        vertical: DesignSpacing.md,
        horizontal: DesignSpacing.lg,
      ),
    };
  }
}

/// The size of a [AuraTypingIndicator].
enum AuraTypingIndicatorSize {
  /// A small typing indicator.
  small,

  /// A medium typing indicator (default).
  medium,

  /// A large typing indicator.
  large,
}
