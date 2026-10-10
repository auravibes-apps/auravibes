import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/widgets/chat_attachment_image.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/number_formatter.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

class const ChatAttachmentDraftPreview({
  required final MessageAttachmentToCreate attachment,
  required final ValueChanged<MessageAttachmentToCreate> onRemove,
  final ChatAttachmentAudioPreviewCoordinator? audioPreviewCoordinator,
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
        audioPreviewCoordinator: audioPreviewCoordinator,
        key: ObjectKey(attachment),
      ),
      onDeleted: enabled ? () => onRemove(attachment) : null,
    );
  }
}

/// Coordinates mutually exclusive draft audio previews within one composer.
class ChatAttachmentAudioPreviewCoordinator {
  int _generation = 0;
  ChatAttachmentAudioPreviewOwner? _activeOwner;
  Future<void> Function()? _stopActive;

  Future<bool> activate(
    ChatAttachmentAudioPreviewOwner owner,
    Future<void> Function() stopActive,
  ) async {
    if (identical(_activeOwner, owner)) return true;
    final generation = ++_generation;
    final previousStop = _stopActive;
    _activeOwner = owner;
    _stopActive = stopActive;
    if (previousStop != null) await previousStop();

    return generation == _generation && identical(_activeOwner, owner);
  }

  void release(ChatAttachmentAudioPreviewOwner owner) {
    if (!identical(_activeOwner, owner)) return;
    _generation++;
    _activeOwner = null;
    _stopActive = null;
  }

  void dispose() {
    _generation++;
    _activeOwner = null;
    _stopActive = null;
  }
}

/// Identity token for one attachment's local audio preview.
class ChatAttachmentAudioPreviewOwner();

class const _AttachmentDraftChipLabel({
  required final MessageAttachmentToCreate attachment,
  required final bool enabled,
  required final double maxWidth,
  required final ChatAttachmentAudioPreviewCoordinator? audioPreviewCoordinator,
  super.key,
}) extends StatefulWidget {
  @override
  State<_AttachmentDraftChipLabel> createState() =>
      _AttachmentDraftChipLabelState();
}

class _AttachmentDraftChipLabelState extends State<_AttachmentDraftChipLabel> {
  var _hasPlaybackError = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: .new(maxWidth: widget.maxWidth),
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _AttachmentDraftChipLabelRow(
          attachment: widget.attachment,
          enabled: widget.enabled,
          audioPreviewCoordinator: widget.audioPreviewCoordinator,
          onPlaybackErrorChanged: _setPlaybackError,
        ),
        if (_hasPlaybackError) const _AttachmentDraftAudioPreviewError(),
      ],
    ),
  );

  void _setPlaybackError(bool hasError) {
    if (mounted) setState(() => _hasPlaybackError = hasError);
  }
}

class const _AttachmentDraftChipLabelRow({
  required final MessageAttachmentToCreate attachment,
  required final bool enabled,
  required final ChatAttachmentAudioPreviewCoordinator? audioPreviewCoordinator,
  required final ValueChanged<bool> onPlaybackErrorChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      if (attachment.modality == .audio) ...[
        _AttachmentDraftAudioPlayer(
          localPath: attachment.localPath,
          enabled: enabled,
          audioPreviewCoordinator: audioPreviewCoordinator,
          onPlaybackErrorChanged: onPlaybackErrorChanged,
          key: ObjectKey(attachment),
        ),
        const SizedBox(width: 4),
      ],
      Flexible(child: _AttachmentDraftLabel(attachment: attachment)),
    ],
  );
}

class const _AttachmentDraftAudioPreviewError() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      LocaleKeys.chats_screens_chat_conversation_audio_preview_error.tr(),
    ),
    style: .caption,
    tint: .error,
  );
}

class const _AttachmentDraftAudioPlayer({
  required final String localPath,
  required final bool enabled,
  required final ChatAttachmentAudioPreviewCoordinator? audioPreviewCoordinator,
  required final ValueChanged<bool> onPlaybackErrorChanged,
  super.key,
}) extends StatefulWidget {
  @override
  State<_AttachmentDraftAudioPlayer> createState() =>
      _AttachmentDraftAudioPlayerState();
}

class _AttachmentDraftAudioPlayerState
    extends State<_AttachmentDraftAudioPlayer> {
  final _previewOwner = ChatAttachmentAudioPreviewOwner();
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _completionSubscription;
  bool _isPlaying = false;
  var _playbackRequest = 0;
  Future<void>? _stoppingPlayback;

  @override
  void dispose() {
    _playbackRequest++;
    widget.audioPreviewCoordinator?.release(_previewOwner);
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
    final playbackRequest = ++_playbackRequest;
    final existingStop = _stoppingPlayback;
    if (existingStop != null) await existingStop;
    if (!_isCurrentRequest(playbackRequest)) return;

    final player = _preparePlayer();
    if (!await _activatePreview(playbackRequest)) return;

    _setPlaying(true);
    widget.onPlaybackErrorChanged(false);
    try {
      await _loadAndPlay(player, playbackRequest);
    } on Object {
      await _handlePlaybackFailure(playbackRequest);
    }
  }

  AudioPlayer _preparePlayer() {
    final player = _player ??= .new();
    _listenForCompletion(player);

    return player;
  }

  Future<bool> _activatePreview(int playbackRequest) async {
    final coordinator = widget.audioPreviewCoordinator;
    if (coordinator == null) return _isCurrentRequest(playbackRequest);
    final canPlay = await coordinator.activate(_previewOwner, _stopPlayback);

    return canPlay && _isCurrentRequest(playbackRequest);
  }

  Future<void> _stopPlayback() {
    final existingStop = _stoppingPlayback;
    if (existingStop != null) return existingStop;

    _playbackRequest++;
    _setPlaying(false);
    final stopping = _stopPlayer();
    _stoppingPlayback = stopping;

    return stopping.whenComplete(() {
      if (identical(_stoppingPlayback, stopping)) _stoppingPlayback = null;
      widget.audioPreviewCoordinator?.release(_previewOwner);
    });
  }

  Future<void> _stopPlayer() async {
    try {
      await _player?.stop();
    } on Object {
      // A failed stop still leaves the preview in its stopped state.
    }
  }

  void _setPlaying(bool isPlaying) {
    if (mounted) setState(() => _isPlaying = isPlaying);
  }
}

extension on _AttachmentDraftAudioPlayerState {
  Future<void> _loadAndPlay(AudioPlayer player, int playbackRequest) async {
    final _ = await player.setFilePath(widget.localPath);
    if (!_isCurrentRequest(playbackRequest)) return;
    unawaited(
      player.play().catchError((Object _) async {
        await _handlePlaybackFailure(playbackRequest);
      }),
    );
  }

  bool _isCurrentRequest(int playbackRequest) =>
      mounted && playbackRequest == _playbackRequest;

  Future<void> _handlePlaybackFailure(int playbackRequest) async {
    if (playbackRequest != _playbackRequest) return;
    _setPlaying(false);
    final stopping = _stopPlayer();
    _stoppingPlayback = stopping;
    try {
      await stopping;
    } finally {
      if (identical(_stoppingPlayback, stopping)) _stoppingPlayback = null;
    }
    if (playbackRequest != _playbackRequest) return;
    widget.audioPreviewCoordinator?.release(_previewOwner);
    _setPlaying(false);
    widget.onPlaybackErrorChanged(true);
  }

  void _listenForCompletion(AudioPlayer player) {
    _completionSubscription ??= player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        widget.audioPreviewCoordinator?.release(_previewOwner);
        _setPlaying(false);
      }
    });
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
    final metadata = _attachmentMetadata(
      attachment,
      Localizations.localeOf(context),
    );

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

String _attachmentMetadata(
  MessageAttachmentToCreate attachment,
  Locale locale,
) {
  final values = <String>[
    if (attachment.mimeType.trim().isNotEmpty) attachment.mimeType,
    if (attachment.sizeBytes >= 0)
      _formatAttachmentSize(attachment.sizeBytes, locale),
  ];

  return values.join(' - ');
}

String _formatAttachmentSize(int sizeBytes, Locale locale) {
  const bytesPerUnit = 1024;
  if (sizeBytes < bytesPerUnit) {
    return '${NumberFormatter.count(sizeBytes, locale)} B';
  }

  final kilobytes = sizeBytes / bytesPerUnit;
  if (kilobytes < bytesPerUnit) {
    return '${NumberFormatter.decimal(kilobytes, locale, 1)} KB';
  }

  return '${NumberFormatter.decimal(kilobytes / bytesPerUnit, locale, 1)} MB';
}

IconData _attachmentIcon(MessageAttachmentModality modality) {
  return switch (modality) {
    .image => Icons.image_outlined,
    .audio => Icons.mic_none_outlined,
    .file => Icons.insert_drive_file_outlined,
  };
}
