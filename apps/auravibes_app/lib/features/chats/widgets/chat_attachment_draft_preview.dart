import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/widgets/chat_attachment_image.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

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
      label: _AttachmentDraftChipLabel(
        attachment: attachment,
        enabled: enabled,
        maxWidth: _maxLabelWidth,
      ),
      onDeleted: enabled ? () => onRemove(attachment) : null,
    );
  }
}

class const _AttachmentDraftChipLabel({
  required final MessageAttachmentToCreate attachment,
  required final bool enabled,
  required final double maxWidth,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: .new(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: .min,
        children: [
          if (attachment.modality == .audio) ...[
            _AttachmentDraftAudioPlayer(
              localPath: attachment.localPath,
              enabled: enabled,
              key: ObjectKey(attachment),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(child: _AttachmentDraftLabel(attachment: attachment)),
        ],
      ),
    );
  }
}

class const _AttachmentDraftAudioPlayer({
  required final String localPath,
  required final bool enabled,
  super.key,
}) extends StatefulWidget {
  @override
  State<_AttachmentDraftAudioPlayer> createState() =>
      _AttachmentDraftAudioPlayerState();
}

class _AttachmentDraftAudioPlayerState
    extends State<_AttachmentDraftAudioPlayer> {
  AudioPlayer? _player;
  StreamSubscription<void>? _completionSubscription;
  bool _isPlaying = false;

  @override
  void dispose() {
    final completionSubscription = _completionSubscription;
    if (completionSubscription != null) {
      unawaited(completionSubscription.cancel());
    }
    final player = _player;
    if (player != null) unawaited(_disposePlayer(player));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label =
        (_isPlaying
                ? LocaleKeys
                      .chats_screens_chat_conversation_stop_voice_attachment
                : LocaleKeys
                      .chats_screens_chat_conversation_play_voice_attachment)
            .tr();

    return AuraIconButton(
      icon: _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
      onPressed: widget.enabled ? () => unawaited(_togglePlayback()) : null,
      disabled: !widget.enabled,
      semanticLabel: label,
      tooltip: label,
    );
  }

  Future<void> _togglePlayback() =>
      _isPlaying ? _stopPlayback() : _startPlayback();

  Future<void> _startPlayback() async {
    final player = _player ??= .new();
    _listenForCompletion(player);

    try {
      _setPlaying(true);
      await player.play(DeviceFileSource(widget.localPath));
    } on Object {
      _setPlaying(false);
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _player?.stop();
    } on Object {
      // A failed stop still leaves the preview in its stopped state.
    }
    _setPlaying(false);
  }

  void _listenForCompletion(AudioPlayer player) {
    _completionSubscription ??= player.onPlayerComplete.listen(
      (_) => _setPlaying(false),
    );
  }

  void _setPlaying(bool isPlaying) {
    if (mounted) setState(() => _isPlaying = isPlaying);
  }

  Future<void> _disposePlayer(AudioPlayer player) async {
    try {
      await player.dispose();
    } on Object {
      // The preview is already leaving the tree; there is no UI to report to.
    }
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
