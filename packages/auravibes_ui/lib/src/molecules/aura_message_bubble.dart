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
    this.manageAlignment = true,
    this.now,
    this.imageProvider,
    this.imageSemanticLabel = 'Image message',
    this.imageErrorLabel = 'Failed to load image',
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

  /// Whether the bubble manages its chat-side placement.
  ///
  /// Set to false when a parent controls placement, such as Widgetbook's
  /// an external alignment wrapper.
  final bool manageAlignment;

  /// Supplies the current time for deterministic timestamp rendering.
  final DateTime Function()? now;

  /// An optional local image provider used instead of [content].
  final ImageProvider<Object>? imageProvider;

  /// Semantic label for image content.
  final String? imageSemanticLabel;

  /// Semantic label shown when image content fails to load.
  final String imageErrorLabel;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final timestamp = this.timestamp;
    final startSpacing = isUser ? AuraSpacing.xl : AuraSpacing.md;
    final endSpacing = isUser ? AuraSpacing.md : AuraSpacing.xl;

    final bubble = GestureDetector(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: manageAlignment
            ? EdgeInsetsDirectional.only(
                start: context.auraTheme.fromSpacing(startSpacing),
                end: context.auraTheme.fromSpacing(endSpacing),
                bottom: context.auraTheme.fromSpacing(.sm),
              )
            : EdgeInsets.only(bottom: context.auraTheme.fromSpacing(.sm)),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: _getPadding(spacing: context.auraTheme.spacing),
              decoration: _getDecoration(
                auraColors,
                borderRadius: context.auraTheme.fromBorderRadius(.xl),
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
                    imageProvider: imageProvider,
                    imageSemanticLabel: imageSemanticLabel,
                    imageErrorLabel: imageErrorLabel,
                  ),
                  if (timestamp != null) ...[
                    const AuraSizedBox(height: .xs),
                    _AuraMessageBubbleTimestamp(
                      timestamp: timestamp,
                      textColor: isUser
                          ? auraColors.onPrimary.withValues(alpha: 0.7)
                          : auraColors.onSurfaceVariant,
                      now: now,
                    ),
                  ],
                ],
              ),
            ),
            if (status != AuraMessageDeliveryStatus.sent) ...[
              SizedBox(height: context.auraTheme.fromSpacing(.xs) / 2),
              AuraMessageStatus(status: status),
            ],
          ],
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );

    if (!manageAlignment) return bubble;

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: bubble,
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
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      boxShadow: [
        if (status != AuraMessageDeliveryStatus.error) DesignShadows.sm,
      ],
    );
  }

  static String _formatTimestamp(DateTime timestamp, {DateTime? now}) {
    final difference = (now ?? DateTime.now()).difference(timestamp);

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
  static const _attachmentIconSize = 20.0;
  const _AuraMessageBubbleContent({
    required this.content,
    required this.contentType,
    required this.textColor,
    required this.imageProvider,
    required this.imageSemanticLabel,
    required this.imageErrorLabel,
  });

  final String content;
  final AuraMessageContentType contentType;
  final Color textColor;
  final ImageProvider<Object>? imageProvider;
  final String? imageSemanticLabel;
  final String imageErrorLabel;

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
          Radius.circular(context.auraTheme.fromBorderRadius(.md)),
        ),
        child: Image(
          image: imageProvider ?? NetworkImage(content),
          errorBuilder: (context, error, stackTrace) => Container(
            padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image,
                  size: _attachmentIconSize,
                  color: textColor,
                ),
                const AuraSizedBox(width: .sm),
                Text(imageErrorLabel, style: TextStyle(color: textColor)),
              ],
            ),
          ),
          semanticLabel: imageSemanticLabel,
          fit: BoxFit.cover,
        ),
      ),
      AuraMessageContentType.file => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file, size: _attachmentIconSize, color: textColor),
          const AuraSizedBox(width: .sm),
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
    required this.now,
  });

  final DateTime timestamp;
  final Color textColor;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final typography = context.auraTheme.typography;

    return Text(
      AuraMessageBubble._formatTimestamp(timestamp, now: now?.call()),
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
