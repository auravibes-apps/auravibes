// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// ignore_for_file: avoid-returning-widgets
// Required: Existing helper builders return widgets.
// ignore_for_file: avoid-non-null-assertion
// Required: Existing nullable API contracts still use explicit assertions.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

import 'package:auravibes_ui/src/atoms/aura_message_status.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// A message bubble component for chat interfaces.
///
/// This component displays chat messages with proper styling for user and AI
/// messages, including different states and content types.
class AuraMessageBubble extends StatelessWidget {
  /// Creates a Aura message bubble.
  const AuraMessageBubble({
    required this.content,
    required this.isUser,
    super.key,
    this.status = AuraMessageDeliveryStatus.sent,
    this.timestamp,
    this.contentType = AuraMessageContentType.text,
    this.onTap,
    this.onLongPress,
    this.maxWidth,
  });

  /// The content of the message.
  final String content;

  /// Whether this message is from the user (true) or AI (false).
  final bool isUser;

  /// The delivery status of the message.
  final AuraMessageDeliveryStatus status;

  /// The timestamp when the message was sent.
  final DateTime? timestamp;

  /// The type of content in the message.
  final AuraMessageContentType contentType;

  /// Called when the message bubble is tapped.
  final VoidCallback? onTap;

  /// Called when the message bubble is long pressed.
  final VoidCallback? onLongPress;

  /// Maximum width of the message bubble.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? MediaQuery.sizeOf(context).width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: isUser ? DesignSpacing.xl : DesignSpacing.md,
            right: isUser ? DesignSpacing.md : DesignSpacing.xl,
            bottom: DesignSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: _getPadding(),
                decoration: _getDecoration(auraColors),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContent(auraColors),
                    if (timestamp != null) ...[
                      const SizedBox(height: DesignSpacing.xs),
                      _buildTimestamp(auraColors),
                    ],
                  ],
                ),
              ),
              if (status != AuraMessageDeliveryStatus.sent) ...[
                const SizedBox(height: DesignSpacing.xs / 2),
                AuraMessageStatus(
                  status: status,
                ),
              ],
            ],
          ),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  EdgeInsets _getPadding() {
    return switch (contentType) {
      AuraMessageContentType.text => const EdgeInsets.symmetric(
        vertical: DesignSpacing.sm,
        horizontal: DesignSpacing.md,
      ),
      AuraMessageContentType.image => const EdgeInsets.all(DesignSpacing.xs),
      AuraMessageContentType.file => const EdgeInsets.all(DesignSpacing.sm),
    };
  }

  BoxDecoration _getDecoration(AuraColorScheme auraColors) {
    final baseColor = isUser ? auraColors.primary : auraColors.surfaceVariant;

    final errorColor = status == AuraMessageDeliveryStatus.error
        ? auraColors.error.withValues(alpha: 0.1)
        : null;

    return BoxDecoration(
      color: errorColor ?? baseColor,
      border: status == AuraMessageDeliveryStatus.error
          ? Border.fromBorderSide(BorderSide(color: auraColors.error))
          : null,
      borderRadius: BorderRadius.circular(DesignBorderRadius.xl),
      boxShadow: [
        if (status != AuraMessageDeliveryStatus.error) DesignShadows.sm,
      ],
    );
  }

  Widget _buildContent(AuraColorScheme auraColors) {
    final textColor = isUser ? auraColors.onPrimary : auraColors.onSurface;

    return switch (contentType) {
      AuraMessageContentType.text => GptMarkdown(
        content,
        key: ValueKey(content),
        style: TextStyle(
          color: textColor,
          fontSize: DesignTypography.fontSizeBase,
          height: DesignTypography.lineHeightBase,
          fontFamily: DesignTypography.bodyFontFamily,
        ),
      ),
      AuraMessageContentType.image => ClipRRect(
        borderRadius: BorderRadius.circular(DesignBorderRadius.md),
        child: Image.network(
          content,
          errorBuilder: (context, error, stackTrace) => Container(
            padding: const EdgeInsets.all(DesignSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 20,
                  color: textColor,
                ),
                const SizedBox(width: DesignSpacing.sm),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
          fit: BoxFit.cover,
        ),
      ),
      AuraMessageContentType.file => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: DesignSpacing.sm),
          Flexible(
            child: Text(
              content,
              style: TextStyle(
                color: textColor,
                fontSize: DesignTypography.fontSizeBase,
                fontFamily: DesignTypography.bodyFontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    };
  }

  Widget _buildTimestamp(AuraColorScheme auraColors) {
    final textColor = isUser
        ? auraColors.onPrimary.withValues(alpha: 0.7)
        : auraColors.onSurfaceVariant;

    return Text(
      _formatTimestamp(timestamp!),
      style: TextStyle(
        color: textColor,
        fontSize: DesignTypography.fontSizeXs,
        fontFamily: DesignTypography.bodyFontFamily,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// The delivery status of a message.

/// The type of content in a message.
enum AuraMessageContentType {
  /// Plain text content.
  text,

  /// Image content.
  image,

  /// File attachment.
  file,
}
