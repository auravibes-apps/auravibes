import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/widgets/chat_attachment_image.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class const ChatAttachmentDraftPreview({
  required final MessageAttachmentToCreate attachment,
  required final ValueChanged<MessageAttachmentToCreate> onRemove,
  final bool enabled = true,
  super.key,
}) extends StatelessWidget {
  static const _thumbnailSize = 40.0;
  static const _maxLabelWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: _AttachmentDraftAvatar(
        attachment: attachment,
        size: _thumbnailSize,
      ),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxLabelWidth),
        child: _AttachmentDraftLabel(attachment: attachment),
      ),
      onDeleted: enabled ? () => onRemove(attachment) : null,
    );
  }
}

class const _AttachmentDraftAvatar({
  required final MessageAttachmentToCreate attachment,
  required final double size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (attachment.modality != .image) {
      return Icon(_attachmentIcon(attachment.modality));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        context.auraTheme.fromBorderRadius(.sm),
      ),
      child: ChatAttachmentImage(
        localPath: attachment.localPath,
        width: size,
        height: size,
      ),
    );
  }
}

class const _AttachmentDraftLabel({
  required final MessageAttachmentToCreate attachment,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final metadata = _attachmentMetadata(attachment);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Text(_attachmentFileName(attachment), overflow: .ellipsis, maxLines: 1),
        if (metadata.isNotEmpty)
          AuraText(
            child: Text(metadata, overflow: .ellipsis, maxLines: 1),
            style: .caption,
          ),
      ],
    );
  }
}

String _attachmentFileName(MessageAttachmentToCreate attachment) {
  if (attachment.fileName.trim().isNotEmpty) return attachment.fileName;

  return attachment.displayName;
}

String _attachmentMetadata(MessageAttachmentToCreate attachment) {
  final values = <String>[
    if (attachment.mimeType.trim().isNotEmpty) attachment.mimeType,
    if (attachment.sizeBytes >= 0) _formatAttachmentSize(attachment.sizeBytes),
  ];

  return values.join(' - ');
}

String _formatAttachmentSize(int sizeBytes) {
  const bytesPerUnit = 1024;
  if (sizeBytes < bytesPerUnit) return '$sizeBytes B';

  final kilobytes = sizeBytes / bytesPerUnit;
  if (kilobytes < bytesPerUnit) {
    return '${kilobytes.toStringAsFixed(1)} KB';
  }

  return '${(kilobytes / bytesPerUnit).toStringAsFixed(1)} MB';
}

IconData _attachmentIcon(MessageAttachmentModality modality) {
  return switch (modality) {
    .image => Icons.image_outlined,
    .audio => Icons.mic_none_outlined,
    .file => Icons.insert_drive_file_outlined,
  };
}
