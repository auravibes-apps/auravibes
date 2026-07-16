// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/services/attachment_modality.dart';
import 'package:auravibes_app/features/chats/usecases/local_chat_attachment_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/experimental/scope.dart';

final _logger = Logger('chat_input_widget');

const String _attachmentUnsupportedKey =
    LocaleKeys.chats_screens_chat_conversation_attachment_unsupported;
const String _attachFileKey =
    LocaleKeys.chats_screens_chat_conversation_attach_file;
const String _attachPhotoKey =
    LocaleKeys.chats_screens_chat_conversation_attach_photo;
const String _attachCameraKey =
    LocaleKeys.chats_screens_chat_conversation_attach_camera;
const String _stopRecordingKey =
    LocaleKeys.chats_screens_chat_conversation_stop_recording;
const String _recordVoiceKey =
    LocaleKeys.chats_screens_chat_conversation_record_voice;
const String _cancelRecordingKey =
    LocaleKeys.chats_screens_chat_conversation_cancel_recording;
const String _recordingStatusKey =
    LocaleKeys.chats_screens_chat_conversation_recording_status;
const String _voiceRecordLabelKey =
    LocaleKeys.chats_screens_chat_conversation_voice_record_label;
const String _imageAttachmentLabelKey =
    LocaleKeys.chats_screens_chat_conversation_image_attachment_label;

@Dependencies([workspaceSession])
class ChatInputWidget extends HookConsumerWidget {
  const ChatInputWidget({
    required this.onSendMessage,
    required this.onToolsPress,
    required this.modelSheetControl,
    required this.agentSheetControl,
    required this.modelCompactControl,
    required this.agentCompactControl,
    this.modalitiesInput = const [],
    this.onSkillsPress,
    this.onContinueAgent,
    this.disabledHint,
    this.disabled = false,
    this.isBusy = false,
    this.showStopButton,
    this.onStop,
    this.onCompact,
    this.isCompacting = false,
    super.key,
  });

  final bool disabled;
  final bool isBusy;
  final bool? showStopButton;
  final FutureOr<void> Function(ChatDraft draft) onSendMessage;
  final VoidCallback onToolsPress;
  final VoidCallback? onSkillsPress;
  final VoidCallback? onContinueAgent;
  final List<String> modalitiesInput;
  final Widget modelSheetControl;
  final Widget agentSheetControl;
  final Widget modelCompactControl;
  final Widget agentCompactControl;
  final Widget? disabledHint;
  final VoidCallback? onStop;
  final VoidCallback? onCompact;
  final bool isCompacting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final attachments = useState(<MessageAttachmentToCreate>[]);
    final isSending = useState(false);
    final isRecording = useState(false);
    final isStartingRecording = useState(false);
    final recordingElapsed = useState(Duration.zero);
    final recordingTimer = useRef<Timer?>(null);
    final recordingStart = useRef<Future<void>?>(null);
    final workspaceCapabilities = ref.watch(
      workspaceSessionProvider.select((session) => session.capabilities),
    );

    final isTextEmpty = useListenableSelector(
      controller,
      () => controller.text.trim().isEmpty,
    );
    final isEmpty = isTextEmpty && attachments.value.isEmpty;
    final actions = _ChatInputActions(
      ref: ref,
      controller: controller,
      focusNode: focusNode,
      attachments: attachments,
      isSending: isSending,
      isRecording: isRecording,
      isStartingRecording: isStartingRecording,
      recordingElapsed: recordingElapsed,
      recordingTimer: recordingTimer,
      recordingStart: recordingStart,
      modalitiesInput: modalitiesInput,
      onSendMessage: onSendMessage,
      disabled: disabled,
      isEmpty: isEmpty,
    );

    useEffect(
      () {
        return actions.disposeDraft;
      },
      const [],
    );

    final shouldShowStopButton = showStopButton ?? isBusy;
    final supportsLocalAttachments =
        workspaceCapabilities.attachments && !kIsWeb;
    final supportsAudio =
        supportsLocalAttachments &&
        supportsAttachmentModality(
          MessageAttachmentModality.audio,
          modalitiesInput,
        );
    final supportsImage =
        workspaceCapabilities.attachments &&
        supportsAttachmentModality(
          MessageAttachmentModality.image,
          modalitiesInput,
        );
    final supportsFile =
        supportsLocalAttachments && supportsFileAttachments(modalitiesInput);
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    const messagePlaceholderKey =
        LocaleKeys.chats_screens_chat_conversation_message_placeholder;

    return TextFieldTapRegion(
      child: GestureDetector(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: AuraInput(
              controller: controller,
              placeholder: const TextLocale(messagePlaceholderKey),
              textInputAction: TextInputAction.send,
              readOnly: isRecording.value,
              maxLines: 2,
              onSubmitted: (value) {
                unawaited(actions.sendMessage());
              },
              onTapOutside: (_) => focusNode.unfocus(),
              focusNode: focusNode,
              header: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  child: agentCompactControl,
                  onTap: () => _showSelectorSheet(
                    context: context,
                    title: const TextLocale(LocaleKeys.agents_title),
                    child: agentSheetControl,
                  ),
                ),
              ),
              footer: _ChatInputFooter(
                actions: actions,
                attachments: attachments.value,
                disabled: disabled,
                isBusy: isBusy,
                isCompacting: isCompacting,
                isEmpty: isEmpty,
                isMacOS: isMacOS,
                isRecording: isRecording.value,
                isSending: isSending.value,
                isStartingRecording: isStartingRecording.value,
                modelCompactControl: modelCompactControl,
                modelSheetControl: modelSheetControl,
                onToolsPress: onToolsPress,
                recordingElapsed: recordingElapsed.value,
                shouldShowStopButton: shouldShowStopButton,
                supportsAudio: supportsAudio,
                supportsFile: supportsFile,
                supportsImage: supportsImage,
                supportsLocalAttachments: supportsLocalAttachments,
                disabledHint: disabledHint,
                onCompact: onCompact,
                onContinueAgent: onContinueAgent,
                onSkillsPress: onSkillsPress,
                onStop: onStop,
              ),
            ),
          ),
        ),
        onTap: focusNode.requestFocus,
        behavior: HitTestBehavior.translucent,
      ),
    );
  }
}

class _ChatInputActions {
  const _ChatInputActions({
    required this.ref,
    required this.controller,
    required this.focusNode,
    required this.attachments,
    required this.isSending,
    required this.isRecording,
    required this.isStartingRecording,
    required this.recordingElapsed,
    required this.recordingTimer,
    required this.recordingStart,
    required this.modalitiesInput,
    required this.onSendMessage,
    required this.disabled,
    required this.isEmpty,
  });

  final WidgetRef ref;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueNotifier<List<MessageAttachmentToCreate>> attachments;
  final ValueNotifier<bool> isSending;
  final ValueNotifier<bool> isRecording;
  final ValueNotifier<bool> isStartingRecording;
  final ValueNotifier<Duration> recordingElapsed;
  final ObjectRef<Timer?> recordingTimer;
  final ObjectRef<Future<void>?> recordingStart;
  final List<String> modalitiesInput;
  final FutureOr<void> Function(ChatDraft draft) onSendMessage;
  final bool disabled;
  final bool isEmpty;

  void disposeDraft() {
    if (isRecording.value || isStartingRecording.value) {
      unawaited(
        ref.read(localChatAttachmentUsecaseProvider).cancelVoiceRecording(),
      );
    }
    attachments.value.forEach(deleteUnsentAttachment);
    recordingTimer.value?.cancel();
  }

  void deleteUnsentAttachment(MessageAttachmentToCreate attachment) {
    unawaited(
      ref
          .read(localChatAttachmentUsecaseProvider)
          .deleteAttachment(attachment.localPath),
    );
  }

  void clearRecordingState() {
    recordingTimer.value?.cancel();
    recordingTimer.value = null;
    recordingElapsed.value = Duration.zero;
    isRecording.value = false;
    isStartingRecording.value = false;
  }

  Future<void> sendMessage() async {
    if (disabled || isSending.value || isEmpty && !isRecording.value) return;

    isSending.value = true;
    try {
      final message = controller.text.trim();
      final draftAttachments = [...attachments.value];
      if (isRecording.value) {
        final attachment = await _stopRecordingAttachment();
        if (attachment != null) {
          draftAttachments.add(
            _withVoiceDisplayName(attachment, draftAttachments),
          );
        }
      }

      if (message.isEmpty && draftAttachments.isEmpty) return;

      final draft = ChatDraft(text: message, attachments: draftAttachments);
      FutureOr<void> sendResult;
      try {
        sendResult = onSendMessage(draft);
      } on Object catch (error, stackTrace) {
        attachments.value = draftAttachments;
        _logger.warning('Failed to send draft', error, stackTrace);

        return;
      }
      controller.clear();
      attachments.value = const [];
      try {
        await sendResult;
      } on Object catch (error, stackTrace) {
        if (controller.text.isEmpty && attachments.value.isEmpty) {
          controller.text = message;
          attachments.value = draftAttachments;
        }
        _logger.warning('Failed to send draft', error, stackTrace);

        return;
      }
    } finally {
      isSending.value = false;
    }
  }

  Future<void> addPath(String path, {required String displayName}) async {
    final attachment = await ref
        .read(localChatAttachmentUsecaseProvider)
        .copyIntoAppStorage(
          path,
          displayName: uniqueAttachmentDisplayName(
            displayName,
            attachments.value.map((attachment) => attachment.displayName),
          ),
        );
    if (!supportsAttachmentModality(
      attachment.modality,
      modalitiesInput,
      mimeType: attachment.mimeType,
    )) {
      deleteUnsentAttachment(attachment);
      _logger.warning('Unsupported attachment type: ${attachment.mimeType}');

      return;
    }
    attachments.value = [...attachments.value, attachment];
  }

  void pickFiles() {
    unawaited(
      (() async {
        try {
          final allowedExtensions = filePickerAllowedExtensions(
            modalitiesInput,
          );
          final result = await fp.FilePicker.pickFiles(
            allowedExtensions: allowedExtensions,
            type: allowedExtensions == null
                ? fp.FileType.any
                : fp.FileType.custom,
          );
          for (final file in result?.files ?? const <fp.PlatformFile>[]) {
            final path = file.path;
            if (path == null) continue;

            await addPath(path, displayName: file.name);
          }
        } on Object catch (error, stackTrace) {
          _logger.warning('Failed to attach files', error, stackTrace);
        }
      })(),
    );
  }

  void pickImage(ImageSource source) {
    unawaited(
      (() async {
        try {
          final file = await ImagePicker().pickImage(source: source);
          if (file == null) return;

          await addPath(file.path, displayName: _imageAttachmentLabelKey.tr());
        } on Object catch (error, stackTrace) {
          _logger.warning('Failed to attach image', error, stackTrace);
        }
      })(),
    );
  }

  void startRecording() {
    unawaited(
      (() async {
        if (disabled || isRecording.value || isStartingRecording.value) return;

        final service = ref.read(localChatAttachmentUsecaseProvider);
        focusNode.unfocus();
        isRecording.value = true;
        isStartingRecording.value = true;
        recordingElapsed.value = Duration.zero;
        final start = service.startVoiceRecording();
        recordingStart.value = start;
        try {
          await start;
          final startedAt = DateTime.now();
          isStartingRecording.value = false;
          recordingTimer.value?.cancel();
          recordingTimer.value = Timer.periodic(
            const Duration(seconds: 1),
            (_) {
              recordingElapsed.value = DateTime.now().difference(startedAt);
            },
          );
        } on Object catch (_) {
          clearRecordingState();
        }
      })(),
    );
  }

  void stopRecording() {
    unawaited(
      (() async {
        final attachment = await _stopRecordingAttachment();
        if (attachment == null) {
          _logger.warning('Voice recording stopped without attachment');

          return;
        }

        attachments.value = [
          ...attachments.value,
          _withVoiceDisplayName(attachment, attachments.value),
        ];
        _logger.fine('Added voice attachment to draft');
      })(),
    );
  }

  void cancelRecording() {
    unawaited(
      (() async {
        if (isStartingRecording.value) return;

        await ref
            .read(localChatAttachmentUsecaseProvider)
            .cancelVoiceRecording();
        clearRecordingState();
      })(),
    );
  }

  Future<MessageAttachmentToCreate?> _stopRecordingAttachment() async {
    if (isStartingRecording.value) {
      try {
        await recordingStart.value;
      } on Object catch (_) {
        clearRecordingState();

        return null;
      }
    }

    try {
      final attachment = await ref
          .read(localChatAttachmentUsecaseProvider)
          .stopVoiceRecording();
      clearRecordingState();

      return attachment;
    } on Object catch (_) {
      clearRecordingState();

      return null;
    }
  }

  MessageAttachmentToCreate _withVoiceDisplayName(
    MessageAttachmentToCreate attachment,
    Iterable<MessageAttachmentToCreate> existingAttachments,
  ) {
    return attachment.copyWith(
      displayName: uniqueAttachmentDisplayName(
        _voiceRecordLabelKey.tr(),
        existingAttachments.map((attachment) => attachment.displayName),
      ),
    );
  }
}

Future<void> _showSelectorSheet({
  required BuildContext context,
  required Widget title,
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      final viewInsets = MediaQuery.viewInsetsOf(context);
      final bottomInset = viewInsets.bottom == 0
          ? MediaQuery.paddingOf(context).bottom
          : viewInsets.bottom;
      final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
      final radius = Radius.circular(context.auraTheme.fromBorderRadius(.xl));

      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: BoxDecoration(
            color: context.auraColors.surface,
            borderRadius: BorderRadius.vertical(top: radius),
          ),
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuraText(child: title, style: AuraTextStyle.heading5),
              const SizedBox(height: 16),
              Flexible(child: child),
            ],
          ),
        ),
        curve: Curves.easeOut,
        duration: context.auraTheme.animation.fast,
      );
    },
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
  );
}

AuraPopupMenuItem _attachmentMenuItem({
  required String titleKey,
  required IconData icon,
  required bool enabled,
  required VoidCallback onTap,
}) {
  return AuraPopupMenuItem(
    title: TextLocale(titleKey),
    onTap: enabled ? onTap : null,
    leading: AuraIcon(icon),
    trailing: enabled
        ? null
        : AuraTooltip(
            message: _attachmentUnsupportedKey.tr(),
            child: const AuraIcon(Icons.info_outline),
          ),
  );
}

class _ChatInputFooter extends StatelessWidget {
  const _ChatInputFooter({
    required this.actions,
    required this.attachments,
    required this.disabled,
    required this.isBusy,
    required this.isCompacting,
    required this.isEmpty,
    required this.isMacOS,
    required this.isRecording,
    required this.isSending,
    required this.isStartingRecording,
    required this.modelCompactControl,
    required this.modelSheetControl,
    required this.onToolsPress,
    required this.recordingElapsed,
    required this.shouldShowStopButton,
    required this.supportsAudio,
    required this.supportsFile,
    required this.supportsImage,
    required this.supportsLocalAttachments,
    this.disabledHint,
    this.onCompact,
    this.onContinueAgent,
    this.onSkillsPress,
    this.onStop,
  });

  final _ChatInputActions actions;
  final List<MessageAttachmentToCreate> attachments;
  final bool disabled;
  final Widget? disabledHint;
  final bool isBusy;
  final bool isCompacting;
  final bool isEmpty;
  final bool isMacOS;
  final bool isRecording;
  final bool isSending;
  final bool isStartingRecording;
  final Widget modelCompactControl;
  final Widget modelSheetControl;
  final VoidCallback? onCompact;
  final VoidCallback? onContinueAgent;
  final VoidCallback? onSkillsPress;
  final VoidCallback? onStop;
  final VoidCallback onToolsPress;
  final Duration recordingElapsed;
  final bool shouldShowStopButton;
  final bool supportsAudio;
  final bool supportsFile;
  final bool supportsImage;
  final bool supportsLocalAttachments;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attachments.isNotEmpty) ...[
            _AttachmentChips(
              attachments: attachments,
              onRemove: _removeAttachment,
              enabled: !isRecording,
            ),
            const AuraSizedBox(height: .xs),
          ],
          if (disabledHint case final Widget disabledHint) ...[
            AuraText(
              child: Row(
                children: [
                  const AuraIcon(Icons.info_outline, size: AuraIconSize.small),
                  const SizedBox(width: 6),
                  Expanded(child: disabledHint),
                ],
              ),
              style: AuraTextStyle.bodySmall,
            ),
            const AuraSizedBox(height: .xs),
          ],
          Row(
            children: [
              if (!isRecording) ..._idleControls(context),
              if (isRecording)
                ..._recordingControls()
              else if (supportsAudio)
                ..._audioControls(),
              if (onStop case final onStop?) ...[
                Visibility(
                  child: AuraTooltip(
                    message: LocaleKeys
                        .chats_screens_chat_conversation_stop_generation
                        .tr(),
                    child: AuraButton(
                      onPressed: onStop,
                      child: const AuraIcon(Icons.stop_rounded),
                      variant: AuraButtonVariant.outlined,
                      tint: AuraTint.error,
                      size: AuraButtonSize.small,
                    ),
                  ),
                  visible: shouldShowStopButton,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                ),
                const AuraSizedBox(width: .xs),
              ],
              AuraButton(
                onPressed: () => unawaited(actions.sendMessage()),
                child: const AuraIcon(Icons.arrow_upward),
                size: AuraButtonSize.small,
                disabled: isEmpty && !isRecording || disabled || isSending,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _idleControls(BuildContext context) {
    return [
      AuraPopupMenuButton(
        items: [
          _attachmentMenuItem(
            titleKey: _attachFileKey,
            icon: Icons.attach_file,
            enabled: supportsFile,
            onTap: actions.pickFiles,
          ),
          if (!isMacOS)
            _attachmentMenuItem(
              titleKey: _attachPhotoKey,
              icon: Icons.photo_outlined,
              enabled: supportsLocalAttachments && supportsImage,
              onTap: () => actions.pickImage(ImageSource.gallery),
            ),
          if (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)
            _attachmentMenuItem(
              titleKey: _attachCameraKey,
              icon: Icons.photo_camera_outlined,
              enabled: supportsLocalAttachments && supportsImage,
              onTap: () => actions.pickImage(ImageSource.camera),
            ),
          AuraPopupMenuItem(
            title: const TextLocale(LocaleKeys.menu_tools),
            onTap: onToolsPress,
            leading: const AuraIcon(Icons.build_circle_outlined),
          ),
          if (onSkillsPress case final onSkillsPress?)
            AuraPopupMenuItem(
              title: const TextLocale(LocaleKeys.skills_selector_title),
              onTap: onSkillsPress,
              leading: const AuraIcon(Icons.psychology_alt_outlined),
            ),
          if (onContinueAgent != null)
            AuraPopupMenuItem(
              title: const TextLocale(
                LocaleKeys.chats_screens_chat_conversation_continue_agent,
              ),
              onTap: onContinueAgent,
              leading: const AuraIcon(Icons.play_circle_outline),
            ),
          if (onCompact != null && !disabled && !isBusy && !isCompacting)
            AuraPopupMenuItem(
              title: const TextLocale(
                LocaleKeys.compaction_manual_button_tooltip,
              ),
              onTap: onCompact,
              leading: const AuraIcon(Icons.compress_outlined),
            ),
        ],
        icon: Icons.tune_rounded,
        tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip
            .tr(),
      ),
      const AuraSizedBox(width: .xs),
      Expanded(
        child: GestureDetector(
          child: modelCompactControl,
          onTap: () => _showSelectorSheet(
            context: context,
            title: const TextLocale(LocaleKeys.models_screens_select_model),
            child: modelSheetControl,
          ),
        ),
      ),
      const AuraSizedBox(width: .xs),
    ];
  }

  List<Widget> _recordingControls() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AuraIconButton(
          icon: Icons.close_rounded,
          onPressed: actions.cancelRecording,
          disabled: isStartingRecording,
          tooltip: _cancelRecordingKey.tr(),
        ),
      ),
      const AuraSizedBox(width: .xs),
      Expanded(child: _RecordingIndicator(elapsed: recordingElapsed)),
      const AuraSizedBox(width: .xs),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AuraIconButton(
          icon: Icons.stop_rounded,
          onPressed: actions.stopRecording,
          disabled: isStartingRecording,
          tint: AuraTint.error,
          tooltip: _stopRecordingKey.tr(),
        ),
      ),
      const AuraSizedBox(width: .xs),
    ];
  }

  List<Widget> _audioControls() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AuraIconButton(
          icon: Icons.mic_none_outlined,
          onPressed: actions.startRecording,
          disabled: disabled,
          tooltip: _recordVoiceKey.tr(),
        ),
      ),
      const AuraSizedBox(width: .xs),
    ];
  }

  void _removeAttachment(MessageAttachmentToCreate attachment) {
    actions.deleteUnsentAttachment(attachment);
    actions.attachments.value = [
      for (final item in actions.attachments.value)
        if (item != attachment) item,
    ];
  }
}

class _AttachmentChips extends StatelessWidget {
  const _AttachmentChips({
    required this.attachments,
    required this.onRemove,
    this.enabled = true,
  });

  final List<MessageAttachmentToCreate> attachments;
  final ValueChanged<MessageAttachmentToCreate> onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.auraTheme.fromSpacing(.xs),
      runSpacing: context.auraTheme.fromSpacing(.xs),
      children: [
        for (final attachment in attachments)
          InputChip(
            avatar: Icon(_attachmentIcon(attachment.modality)),
            label: Text(attachment.displayName),
            onDeleted: enabled ? () => onRemove(attachment) : null,
          ),
      ],
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator({required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return AuraText(
      child: Row(
        children: [
          Icon(
            Icons.graphic_eq,
            size: 18,
            color: colors.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_recordingStatusKey.tr()} ${_formatElapsed(elapsed)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      style: AuraTextStyle.bodySmall,
    );
  }
}

String _formatElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

  return '$minutes:$seconds';
}

@visibleForTesting
String uniqueAttachmentDisplayName(
  String displayName,
  Iterable<String> existingNames,
) {
  if (!existingNames.contains(displayName)) return displayName;

  final extension = p.extension(displayName);
  final baseName = extension.isEmpty
      ? displayName
      : p.basenameWithoutExtension(displayName);
  var index = 1;
  while (true) {
    final candidate = '$baseName ($index)$extension';
    if (!existingNames.contains(candidate)) return candidate;
    index += 1;
  }
}

IconData _attachmentIcon(MessageAttachmentModality modality) {
  return switch (modality) {
    MessageAttachmentModality.image => Icons.image_outlined,
    MessageAttachmentModality.audio => Icons.mic_none_outlined,
    MessageAttachmentModality.file => Icons.insert_drive_file_outlined,
  };
}
