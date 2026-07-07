// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/services/attachment_modality.dart';
import 'package:auravibes_app/features/chats/usecases/local_chat_attachment_usecase.dart';
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

    void deleteUnsentAttachment(MessageAttachmentToCreate attachment) {
      unawaited(
        ref
            .read(localChatAttachmentUsecaseProvider)
            .deleteAttachment(attachment.localPath),
      );
    }

    useEffect(
      () {
        return () {
          if (isRecording.value || isStartingRecording.value) {
            unawaited(
              ref
                  .read(localChatAttachmentUsecaseProvider)
                  .cancelVoiceRecording(),
            );
          }
          attachments.value.forEach(deleteUnsentAttachment);
          recordingTimer.value?.cancel();
        };
      },
      const [],
    );

    final isTextEmpty = useListenableSelector(
      controller,
      () => controller.text.trim().isEmpty,
    );
    final isEmpty = isTextEmpty && attachments.value.isEmpty;

    void clearRecordingState() {
      recordingTimer.value?.cancel();
      recordingTimer.value = null;
      recordingElapsed.value = Duration.zero;
      isRecording.value = false;
      isStartingRecording.value = false;
    }

    MessageAttachmentToCreate withVoiceDisplayName(
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

    final sendMessage = useCallback(
      () async {
        if (disabled || isSending.value || isEmpty && !isRecording.value) {
          return;
        }

        isSending.value = true;
        try {
          final message = controller.text.trim();
          final draftAttachments = [...attachments.value];
          if (isRecording.value) {
            if (isStartingRecording.value) {
              try {
                await recordingStart.value;
              } on Object catch (_) {
                clearRecordingState();

                return;
              }
            }

            final MessageAttachmentToCreate? attachment;
            try {
              attachment = await ref
                  .read(localChatAttachmentUsecaseProvider)
                  .stopVoiceRecording();
            } on Object catch (_) {
              clearRecordingState();

              return;
            }
            clearRecordingState();
            if (attachment != null) {
              draftAttachments.add(
                withVoiceDisplayName(attachment, draftAttachments),
              );
            }
          }

          if (message.isEmpty && draftAttachments.isEmpty) return;

          try {
            await onSendMessage(
              ChatDraft(text: message, attachments: draftAttachments),
            );
          } on Object catch (error, stackTrace) {
            _logger.warning('Failed to send draft', error, stackTrace);

            return;
          }
          controller.clear();
          attachments.value = const [];
        } finally {
          isSending.value = false;
        }
      },
      [
        attachments.value,
        controller,
        disabled,
        isSending.value,
        isRecording.value,
        isStartingRecording.value,
        onSendMessage,
        ref,
        isEmpty,
      ],
    );

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
              allowMultiple: true,
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

            await addPath(
              file.path,
              displayName: _imageAttachmentLabelKey.tr(),
            );
          } on Object catch (error, stackTrace) {
            _logger.warning('Failed to attach image', error, stackTrace);
          }
        })(),
      );
    }

    void startRecording() {
      unawaited(
        (() async {
          if (disabled || isRecording.value || isStartingRecording.value) {
            return;
          }

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
          if (isStartingRecording.value) {
            try {
              await recordingStart.value;
            } on Object catch (_) {
              clearRecordingState();

              return;
            }
          }

          final MessageAttachmentToCreate? attachment;
          try {
            attachment = await ref
                .read(localChatAttachmentUsecaseProvider)
                .stopVoiceRecording();
          } on Object catch (_) {
            clearRecordingState();

            return;
          }
          clearRecordingState();
          if (attachment == null) {
            _logger.warning('Voice recording stopped without attachment');

            return;
          }

          attachments.value = [
            ...attachments.value,
            withVoiceDisplayName(attachment, attachments.value),
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

    final shouldShowStopButton = showStopButton ?? isBusy;
    const supportsLocalAttachments = !kIsWeb;
    final supportsAudio =
        supportsLocalAttachments &&
        supportsAttachmentModality(
          MessageAttachmentModality.audio,
          modalitiesInput,
        );
    final supportsImage = supportsAttachmentModality(
      MessageAttachmentModality.image,
      modalitiesInput,
    );
    final supportsFile =
        supportsLocalAttachments && supportsFileAttachments(modalitiesInput);
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    const continueAgentKey =
        LocaleKeys.chats_screens_chat_conversation_continue_agent;
    const stopGenerationKey =
        LocaleKeys.chats_screens_chat_conversation_stop_generation;
    const optionsTooltipKey =
        LocaleKeys.chats_screens_chat_conversation_options_tooltip;
    const messagePlaceholderKey =
        LocaleKeys.chats_screens_chat_conversation_message_placeholder;
    const compactTooltipKey = LocaleKeys.compaction_manual_button_tooltip;

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
                unawaited(sendMessage());
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
              footer: GestureDetector(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (attachments.value.isNotEmpty) ...[
                        _AttachmentChips(
                          attachments: attachments.value,
                          onRemove: (attachment) {
                            deleteUnsentAttachment(attachment);
                            attachments.value = [
                              for (final item in attachments.value)
                                if (item != attachment) item,
                            ];
                          },
                          enabled: !isRecording.value,
                        ),
                        const AuraSizedBox(height: .xs),
                      ],
                      if (disabledHint case final Widget disabledHint) ...[
                        AuraText(
                          child: Row(
                            children: [
                              const AuraIcon(
                                Icons.info_outline,
                                size: AuraIconSize.small,
                              ),
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
                          if (!isRecording.value) ...[
                            AuraPopupMenuButton(
                              items: [
                                _attachmentMenuItem(
                                  titleKey: _attachFileKey,
                                  icon: Icons.attach_file,
                                  enabled: supportsFile,
                                  onTap: pickFiles,
                                ),
                                if (!isMacOS)
                                  _attachmentMenuItem(
                                    titleKey: _attachPhotoKey,
                                    icon: Icons.photo_outlined,
                                    enabled:
                                        supportsLocalAttachments &&
                                        supportsImage,
                                    onTap: () => pickImage(ImageSource.gallery),
                                  ),
                                if (defaultTargetPlatform ==
                                        TargetPlatform.android ||
                                    defaultTargetPlatform == TargetPlatform.iOS)
                                  _attachmentMenuItem(
                                    titleKey: _attachCameraKey,
                                    icon: Icons.photo_camera_outlined,
                                    enabled:
                                        supportsLocalAttachments &&
                                        supportsImage,
                                    onTap: () => pickImage(ImageSource.camera),
                                  ),
                                AuraPopupMenuItem(
                                  title: const TextLocale(
                                    LocaleKeys.menu_tools,
                                  ),
                                  onTap: onToolsPress,
                                  leading: const AuraIcon(
                                    Icons.build_circle_outlined,
                                  ),
                                ),
                                if (onSkillsPress case final onSkillsPress?)
                                  AuraPopupMenuItem(
                                    title: const TextLocale(
                                      LocaleKeys.skills_selector_title,
                                    ),
                                    onTap: onSkillsPress,
                                    leading: const AuraIcon(
                                      Icons.psychology_alt_outlined,
                                    ),
                                  ),
                                if (onContinueAgent != null)
                                  AuraPopupMenuItem(
                                    title: const TextLocale(continueAgentKey),
                                    onTap: onContinueAgent,
                                    leading: const AuraIcon(
                                      Icons.play_circle_outline,
                                    ),
                                  ),
                                if (onCompact != null &&
                                    !disabled &&
                                    !isBusy &&
                                    !isCompacting)
                                  AuraPopupMenuItem(
                                    title: const TextLocale(compactTooltipKey),
                                    onTap: onCompact,
                                    leading: const AuraIcon(
                                      Icons.compress_outlined,
                                    ),
                                  ),
                              ],
                              icon: Icons.tune_rounded,
                              tooltip: optionsTooltipKey.tr(),
                            ),
                            const AuraSizedBox(width: .xs),
                            Expanded(
                              child: GestureDetector(
                                child: modelCompactControl,
                                onTap: () => _showSelectorSheet(
                                  context: context,
                                  title: const TextLocale(
                                    LocaleKeys.models_screens_select_model,
                                  ),
                                  child: modelSheetControl,
                                ),
                              ),
                            ),
                            const AuraSizedBox(width: .xs),
                          ],
                          if (isRecording.value) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AuraIconButton(
                                icon: Icons.close_rounded,
                                onPressed: cancelRecording,
                                disabled: isStartingRecording.value,
                                tooltip: _cancelRecordingKey.tr(),
                              ),
                            ),
                            const AuraSizedBox(width: .xs),
                            Expanded(
                              child: _RecordingIndicator(
                                elapsed: recordingElapsed.value,
                              ),
                            ),
                            const AuraSizedBox(width: .xs),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AuraIconButton(
                                icon: Icons.stop_rounded,
                                onPressed: stopRecording,
                                disabled: isStartingRecording.value,
                                tint: AuraTint.error,
                                tooltip: _stopRecordingKey.tr(),
                              ),
                            ),
                            const AuraSizedBox(width: .xs),
                          ] else if (supportsAudio) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AuraIconButton(
                                icon: Icons.mic_none_outlined,
                                onPressed: startRecording,
                                disabled: disabled,
                                tooltip: _recordVoiceKey.tr(),
                              ),
                            ),
                            const AuraSizedBox(width: .xs),
                          ],
                          if (onStop case final onStop?) ...[
                            Visibility(
                              child: AuraTooltip(
                                message: stopGenerationKey.tr(),
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
                            onPressed: () => unawaited(sendMessage()),
                            child: const AuraIcon(Icons.arrow_upward),
                            size: AuraButtonSize.small,
                            disabled:
                                isEmpty && !isRecording.value ||
                                disabled ||
                                isSending.value,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                onTap: () => focusNode.hasFocus,
                behavior: HitTestBehavior.opaque,
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
