import 'package:auravibes_ui/src/atoms/aura_message_status.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
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
    final timestamp = this.timestamp;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? MediaQuery.sizeOf(context).width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: context.auraTheme.fromSpacing(
              isUser ? AuraSpacing.xl : AuraSpacing.md,
            ),
            right: context.auraTheme.fromSpacing(
              isUser ? AuraSpacing.md : AuraSpacing.xl,
            ),
            bottom: context.auraTheme.fromSpacing(AuraSpacing.sm),
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: _getPadding(
                  spacing: context.auraTheme.spacing,
                ),
                decoration: _getDecoration(
                  auraColors,
                  borderRadius: context.auraTheme.fromBorderRadius(
                    AuraBorderRadius.xl,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AuraMessageBubbleContent(
                      content: content,
                      contentType: contentType,
                      textColor: isUser
                          ? auraColors.onPrimary
                          : auraColors.onSurface,
                    ),
                    if (timestamp != null) ...[
                      const AuraSizedBox(height: AuraSpacing.xs),
                      _AuraMessageBubbleTimestamp(
                        timestamp: timestamp,
                        textColor: isUser
                            ? auraColors.onPrimary.withValues(alpha: 0.7)
                            : auraColors.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
              if (status != AuraMessageDeliveryStatus.sent) ...[
                SizedBox(
                  height: context.auraTheme.fromSpacing(AuraSpacing.xs) / 2,
                ),
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

  EdgeInsets _getPadding({required AuraSpacingScale spacing}) {
    return switch (contentType) {
      AuraMessageContentType.text => EdgeInsets.symmetric(
        vertical: spacing.sm,
        horizontal: spacing.md,
      ),
      AuraMessageContentType.image => EdgeInsets.all(spacing.xs),
      AuraMessageContentType.file => EdgeInsets.all(spacing.sm),
    };
  }

  BoxDecoration _getDecoration(
    AuraColorScheme auraColors, {
    required double borderRadius,
  }) {
    final baseColor = isUser ? auraColors.primary : auraColors.surfaceVariant;

    final errorColor = status == AuraMessageDeliveryStatus.error
        ? auraColors.error.withValues(alpha: 0.1)
        : null;

    return BoxDecoration(
      color: errorColor ?? baseColor,
      border: status == AuraMessageDeliveryStatus.error
          ? Border.fromBorderSide(BorderSide(color: auraColors.error))
          : null,
      borderRadius: BorderRadius.all(
        Radius.circular(borderRadius),
      ),
      boxShadow: [
        if (status != AuraMessageDeliveryStatus.error) DesignShadows.sm,
      ],
    );
  }

  static String _formatTimestamp(DateTime timestamp) {
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

class _AuraMessageBubbleContent extends StatelessWidget {
  const _AuraMessageBubbleContent({
    required this.content,
    required this.contentType,
    required this.textColor,
  });

  final String content;
  final AuraMessageContentType contentType;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final typography = context.auraTheme.typography;

    return switch (contentType) {
      AuraMessageContentType.text => GptMarkdown(
        content,
        key: ValueKey(content),
        style: TextStyle(
          color: textColor,
          fontSize: typography.fontSizeBase,
          height: typography.lineHeightBase,
          fontFamily: typography.bodyFontFamily,
        ),
      ),
      AuraMessageContentType.image => ClipRRect(
        borderRadius: BorderRadius.all(
          Radius.circular(
            context.auraTheme.fromBorderRadius(AuraBorderRadius.md),
          ),
        ),
        child: Image.network(
          content,
          errorBuilder: (context, error, stackTrace) => Container(
            padding: EdgeInsets.all(
              context.auraTheme.fromSpacing(AuraSpacing.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 20,
                  color: textColor,
                ),
                const AuraSizedBox(width: AuraSpacing.sm),
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
          const AuraSizedBox(width: AuraSpacing.sm),
          Flexible(
            child: Text(
              content,
              style: TextStyle(
                color: textColor,
                fontSize: typography.fontSizeBase,
                fontFamily: typography.bodyFontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    };
  }
}

class _AuraMessageBubbleTimestamp extends StatelessWidget {
  const _AuraMessageBubbleTimestamp({
    required this.timestamp,
    required this.textColor,
  });

  final DateTime timestamp;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final typography = context.auraTheme.typography;

    return Text(
      AuraMessageBubble._formatTimestamp(timestamp),
      style: TextStyle(
        color: textColor,
        fontSize: typography.fontSizeXs,
        fontFamily: typography.bodyFontFamily,
      ),
    );
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
