import 'package:auravibes_ui/src/atoms/aura_message_status.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

const _messageIconSize = 20.0;

/// A message bubble component for chat interfaces.
///
/// This component displays chat messages with proper styling for user and AI
/// messages, including different states and content types.
class AuraMessageBubble extends StatelessWidget {
  /// Creates a Aura message bubble.
  const new({
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
    return _AuraMessageBubbleLayout(message: this);
  }
}

class const _AuraMessageBubbleLayout({required final AuraMessageBubble message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => message.manageAlignment
      ? Align(
          alignment: _messageAlignment(message.isUser),
          child: _AuraMessageBubbleGesture(message: message),
        )
      : _AuraMessageBubbleGesture(message: message);
}

class const _AuraMessageBubbleGesture({
  required final AuraMessageBubble message,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _AuraMessageBubbleFrame(message: message),
    onTap: message.onTap,
    onLongPress: message.onLongPress,
  );
}

class const _AuraMessageBubbleFrame({required final AuraMessageBubble message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: .new(maxWidth: _messageMaxWidth(context, message)),
      margin: _messageMargin(context, message),
      child: _AuraMessageBubbleColumn(message: message),
    );
  }
}

class const _AuraMessageBubbleColumn({required final AuraMessageBubble message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: message.isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      _AuraMessageBubbleCard(message: message),
      if (message.status != AuraMessageDeliveryStatus.sent)
        _AuraMessageStatus(status: message.status),
    ],
  );
}

class const _AuraMessageStatus({
  required final AuraMessageDeliveryStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs) / 2),
    child: AuraMessageStatus(status: status),
  );
}

class const _AuraMessageBubbleCard({required final AuraMessageBubble message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return _AuraMessageBubbleCardSurface(
      message: message,
      auraColors: auraColors,
      child: _AuraMessageBubbleCardContent(message: message),
    );
  }
}

class const _AuraMessageBubbleCardSurface({
  required final AuraMessageBubble message,
  required final AuraColorScheme auraColors,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _messageDecorationFor(context, message, auraColors),
      child: _AuraMessageBubbleCardPadding(message: message, child: child),
    );
  }
}

class const _AuraMessageBubbleCardPadding({
  required final AuraMessageBubble message,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: _messagePaddingFor(context, message), child: child);
  }
}

class const _AuraMessageBubbleCardContent({
  required final AuraMessageBubble message,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      _AuraMessageBubbleContent(message: message),
      _AuraOptionalMessageTimestamp(message: message),
    ],
  );
}

class const _AuraOptionalMessageTimestamp({
  required final AuraMessageBubble message,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (message.timestamp) {
    null => const SizedBox.shrink(),
    final timestamp => _AuraMessageBubbleTimestamp(
      timestamp: timestamp,
      isUser: message.isUser,
      now: message.now,
    ),
  };
}

class const _AuraMessageBubbleContent({
  required final AuraMessageBubble message,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraMessageTypeContent(
    message: message,
    textColor: _messageContentTextColor(context, message),
  );
}

class const _AuraMessageTypeContent({
  required final AuraMessageBubble message,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (message.contentType) {
    .text => _AuraTextMessage(content: message.content, textColor: textColor),
    .image => _AuraImageMessage(message: message, textColor: textColor),
    .file => _AuraFileMessage(message: message, textColor: textColor),
  };
}

class const _AuraTextMessage({
  required final String content,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GptMarkdown(
    content,
    key: ValueKey(content),
    style: _messageBodyStyle(context, textColor),
  );
}

class const _AuraImageMessage({
  required final AuraMessageBubble message,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.all(
      .circular(context.auraTheme.fromBorderRadius(.md)),
    ),
    child: _AuraImageView(message: message, textColor: textColor),
  );
}

class const _AuraImageView({
  required final AuraMessageBubble message,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Image(
    image: message.imageProvider ?? NetworkImage(message.content),
    errorBuilder: _errorBuilder,
    semanticLabel: message.imageSemanticLabel,
    fit: .cover,
  );

  Widget _errorBuilder(BuildContext _, Object _, StackTrace? _) =>
      _AuraImageError(label: message.imageErrorLabel, color: textColor);
}

class const _AuraImageError({
  required final String label,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    child: _AuraImageErrorRow(label: label, color: color),
  );
}

class const _AuraImageErrorRow({
  required final String label,
  required final Color color,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      Icon(Icons.broken_image, size: _messageIconSize, color: color),
      const AuraSizedBox(width: .sm),
      Text(label, style: .new(color: color)),
    ],
  );
}

class const _AuraFileMessage({
  required final AuraMessageBubble message,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AuraFileRow(message: message, textColor: textColor);
}

class const _AuraFileRow({
  required final AuraMessageBubble message,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      Icon(Icons.attach_file, size: _messageIconSize, color: textColor),
      const AuraSizedBox(width: .sm),
      Flexible(
        child: _AuraFileName(message: message, textColor: textColor),
      ),
    ],
  );
}

class const _AuraFileName({
  required final AuraMessageBubble message,
  required final Color textColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    message.content,
    style: _messageFileStyle(context, textColor),
    overflow: .ellipsis,
  );
}

class const _AuraMessageBubbleTimestamp({
  required final DateTime timestamp,
  required final bool isUser,
  required final DateTime Function()? now,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: context.auraTheme.fromSpacing(.xs)),
    child: _AuraMessageBubbleTimestampText(
      timestamp: timestamp,
      isUser: isUser,
      now: now,
    ),
  );
}

class const _AuraMessageBubbleTimestampText({
  required final DateTime timestamp,
  required final bool isUser,
  required final DateTime Function()? now,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    _formatMessageTimestamp(timestamp, now: now?.call()),
    style: _messageTimestampStyle(
      context,
      _messageTimestampColor(context, isUser),
    ),
  );
}

AlignmentGeometry _messageAlignment(bool isUser) =>
    isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart;

double _messageMaxWidth(BuildContext context, AuraMessageBubble message) =>
    message.maxWidth ?? MediaQuery.sizeOf(context).width * 0.75;

TextStyle _messageBodyStyle(BuildContext context, Color color) {
  final typography = context.auraTheme.typography;

  return TextStyle(
    color: color,
    fontSize: typography.fontSizeBase,
    height: typography.lineHeightBase,
    fontFamily: typography.bodyFontFamily,
  );
}

TextStyle _messageFileStyle(BuildContext context, Color color) {
  final typography = context.auraTheme.typography;

  return TextStyle(
    color: color,
    fontSize: typography.fontSizeBase,
    fontFamily: typography.bodyFontFamily,
  );
}

Color _messageTimestampColor(BuildContext context, bool isUser) {
  final colors = context.auraColors;

  return isUser
      ? colors.onPrimary.withValues(alpha: 0.7)
      : colors.onSurfaceVariant;
}

Color _messageContentTextColor(
  BuildContext context,
  AuraMessageBubble message,
) {
  final colors = context.auraColors;

  return message.isUser ? colors.onPrimary : colors.onSurface;
}

TextStyle _messageTimestampStyle(BuildContext context, Color color) {
  final typography = context.auraTheme.typography;

  return TextStyle(
    color: color,
    fontSize: typography.fontSizeXs,
    fontFamily: typography.bodyFontFamily,
  );
}

EdgeInsetsGeometry _messageMargin(
  BuildContext context,
  AuraMessageBubble message,
) => message.manageAlignment
    ? _managedMessageMargin(context, message.isUser)
    : _unmanagedMessageMargin(context);

EdgeInsets _unmanagedMessageMargin(BuildContext context) =>
    EdgeInsets.only(bottom: context.auraTheme.fromSpacing(.sm));

EdgeInsetsDirectional _managedMessageMargin(BuildContext context, bool isUser) {
  final spacing = context.auraTheme;

  return EdgeInsetsDirectional.only(
    start: spacing.fromSpacing(_messageStartSpacing(isUser)),
    end: spacing.fromSpacing(_messageEndSpacing(isUser)),
    bottom: spacing.fromSpacing(.sm),
  );
}

AuraSpacing _messageStartSpacing(bool isUser) => isUser ? .xl : .md;

AuraSpacing _messageEndSpacing(bool isUser) => isUser ? .md : .xl;

EdgeInsets _messagePadding({
  required AuraMessageContentType contentType,
  required AuraSpacingScale spacing,
}) => switch (contentType) {
  .text => EdgeInsets.symmetric(vertical: spacing.sm, horizontal: spacing.md),
  .image => EdgeInsets.all(spacing.xs),
  .file => EdgeInsets.all(spacing.sm),
};

EdgeInsets _messagePaddingFor(
  BuildContext context,
  AuraMessageBubble message,
) => _messagePadding(
  contentType: message.contentType,
  spacing: context.auraTheme.spacing,
);

typedef _MessageDecorationValues = ({
  Color color,
  Border? border,
  List<BoxShadow> boxShadow,
});

_MessageDecorationValues _messageDecorationValues(
  AuraMessageBubble message,
  AuraColorScheme auraColors,
) => (
  color: _messageBackground(message, auraColors),
  border: _messageBorder(message, auraColors),
  boxShadow: _messageBoxShadow(message),
);

BoxDecoration _messageDecorationFor(
  BuildContext context,
  AuraMessageBubble message,
  AuraColorScheme auraColors,
) => _messageDecoration(
  _messageDecorationValues(message, auraColors),
  context.auraTheme.fromBorderRadius(.xl),
);

BoxDecoration _messageDecoration(
  _MessageDecorationValues decoration,
  double borderRadius,
) => BoxDecoration(
  color: decoration.color,
  border: decoration.border,
  borderRadius: BorderRadius.all(.circular(borderRadius)),
  boxShadow: decoration.boxShadow,
);

Color _messageBackground(
  AuraMessageBubble message,
  AuraColorScheme auraColors,
) => message.status == AuraMessageDeliveryStatus.error
    ? auraColors.error.withValues(alpha: 0.1)
    : _messageBaseColor(message, auraColors);

Color _messageBaseColor(
  AuraMessageBubble message,
  AuraColorScheme auraColors,
) => message.isUser ? auraColors.primary : auraColors.surfaceVariant;

Border? _messageBorder(AuraMessageBubble message, AuraColorScheme auraColors) =>
    message.status == AuraMessageDeliveryStatus.error
    ? Border.fromBorderSide(.new(color: auraColors.error))
    : null;

List<BoxShadow> _messageBoxShadow(AuraMessageBubble message) => [
  if (message.status != AuraMessageDeliveryStatus.error) DesignShadows.sm,
];

String _formatMessageTimestamp(DateTime timestamp, {DateTime? now}) {
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
