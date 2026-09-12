// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/usecases/local_chat_attachment_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
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

typedef _ChatInputActionsRequest = ({
  WidgetRef ref,
  _ChatInputHooks hooks,
  ChatInputWidget input,
  bool isEmpty,
});

typedef _ChatInputStateAssemblyRequest = ({
  WidgetRef ref,
  _ChatInputHooks hooks,
  ChatInputWidget input,
  _ChatInputActions actions,
});

class const ChatInputWidget({
  required final String workspaceId,
  required final FutureOr<void> Function(ChatDraft draft) onSendMessage,
  required final VoidCallback onToolsPress,
  required final Widget modelSheetControl,
  required final Widget agentSheetControl,
  required final Widget modelCompactControl,
  required final Widget agentCompactControl,
  final List<String> modalitiesInput = const [],
  final VoidCallback? onSkillsPress,
  final VoidCallback? onContinueAgent,
  final String? continueDisabledHint,
  final Widget? disabledHint,
  final String? compactDisabledHint,
  final bool disabled = false,
  final bool isBusy = false,
  final bool? showStopButton,
  final VoidCallback? onStop,
  final VoidCallback? onCompact,
  final bool canCompact = true,
  final bool isCompacting = false,
  super.key,
}) extends HookConsumerWidget {
  static const _maxInputLines = 2;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _ChatInputLayout(state: _ChatInputHooksFactory.state(ref, this));
}

class const _ChatInputDraftHooks({
  required final TextEditingController controller,
  required final FocusNode focusNode,
  required final ValueNotifier<List<MessageAttachmentToCreate>> attachments,
  required final ValueNotifier<bool> isSending,
});

class const _ChatInputRecordingHooks({
  required final ValueNotifier<bool> isRecording,
  required final ValueNotifier<bool> isStartingRecording,
  required final ValueNotifier<Duration> recordingElapsed,
  required final ObjectRef<Timer?> recordingTimer,
  required final ObjectRef<Future<void>?> recordingStart,
});

class const _ChatInputHooks({
  required final _ChatInputDraftHooks draft,
  required final _ChatInputRecordingHooks recording,
});

typedef _ChatInputStateRequest = ({
  _ChatInputActions actions,
  _ChatInputHooks hooks,
  ChatInputWidget input,
  bool isEmpty,
  _ChatInputCapabilities capabilities,
});

abstract final class _ChatInputHooksFactory {
  static _ChatInputDraftHooks draft() => _ChatInputDraftHooks(
    controller: useTextEditingController(),
    focusNode: useFocusNode(),
    attachments: useState(<MessageAttachmentToCreate>[]),
    isSending: useState(false),
  );

  static _ChatInputRecordingHooks recording() => _ChatInputRecordingHooks(
    isRecording: useState(false),
    isStartingRecording: useState(false),
    recordingElapsed: useState(Duration.zero),
    recordingTimer: useRef<Timer?>(null),
    recordingStart: useRef<Future<void>?>(null),
  );

  static _ChatInputHooks hooks() =>
      _ChatInputHooks(draft: draft(), recording: recording());

  static _ChatInputState state(WidgetRef ref, ChatInputWidget input) {
    final hooks = _ChatInputHooksFactory.hooks();
    final actions = _createAndRegisterActions(
      ref: ref,
      hooks: hooks,
      input: input,
    );

    return _assembleChatInputState((
      ref: ref,
      hooks: hooks,
      input: input,
      actions: actions,
    ));
  }

  static void registerDispose(_ChatInputActions actions) {
    Dispose? disposeDraft() => actions.disposeDraft;

    useEffect(disposeDraft, const []);
  }

  static bool isEmpty(_ChatInputHooks hooks) => useListenableSelector(
    hooks.draft.controller,
    () => hooks.draft.controller.text.trim().isEmpty,
  );

  static _ChatInputActions _createAndRegisterActions({
    required WidgetRef ref,
    required _ChatInputHooks hooks,
    required ChatInputWidget input,
  }) {
    final actions = _createChatInputActions((
      ref: ref,
      hooks: hooks,
      input: input,
      isEmpty: _ChatInputHooksFactory.isEmpty(hooks),
    ));
    _ChatInputHooksFactory.registerDispose(actions);

    return actions;
  }
}

typedef _ChatInputAttachmentCapabilities = ({
  bool supportsLocalAttachments,
  bool supportsAudio,
  bool supportsImage,
  bool supportsFile,
});

typedef _ChatInputAttachmentCapabilitiesRequest = ({
  bool supportsLocalAttachments,
  bool? supportsAttachments,
  List<String> modalitiesInput,
});

class const _ChatInputCapabilities({
  required final _ChatInputAttachmentCapabilities attachments,
  required final bool isMacOS,
});

abstract final class _ChatInputCapabilitiesFactory {
  static _ChatInputCapabilities create(
    WorkspaceCapabilities? workspaceCapabilities,
    List<String> modalitiesInput,
  ) => _ChatInputCapabilities(
    attachments: _createAttachmentCapabilities(
      workspaceCapabilities,
      modalitiesInput,
    ),
    isMacOS: defaultTargetPlatform == TargetPlatform.macOS,
  );

  static _ChatInputAttachmentCapabilities _createAttachmentCapabilities(
    WorkspaceCapabilities? workspaceCapabilities,
    List<String> modalitiesInput,
  ) {
    return _createAttachmentCapabilitiesFrom((
      supportsLocalAttachments: _supportsLocalAttachments(
        workspaceCapabilities,
      ),
      supportsAttachments: workspaceCapabilities?.attachments,
      modalitiesInput: modalitiesInput,
    ));
  }

  static _ChatInputAttachmentCapabilities _createAttachmentCapabilitiesFrom(
    _ChatInputAttachmentCapabilitiesRequest request,
  ) => (
    supportsLocalAttachments: request.supportsLocalAttachments,
    supportsAudio: _supportsChatInputAudio(request),
    supportsImage: _supportsChatInputImage(request),
    supportsFile: _supportsChatInputFile(request),
  );

  static bool _supportsLocalAttachments(WorkspaceCapabilities? capabilities) =>
      (capabilities?.attachments ?? false) && !kIsWeb;

  static bool _supportsAudioAttachment(
    bool supportsLocalAttachments,
    List<String> modalitiesInput,
  ) =>
      supportsLocalAttachments &&
      ChatAttachmentModality.supports(.audio, modalitiesInput);

  static bool _supportsImageAttachment(
    bool? supportsAttachments,
    List<String> modalitiesInput,
  ) =>
      (supportsAttachments ?? false) &&
      ChatAttachmentModality.supports(.image, modalitiesInput);

  static bool _supportsFileAttachment(
    bool supportsLocalAttachments,
    List<String> modalitiesInput,
  ) =>
      supportsLocalAttachments &&
      ChatAttachmentModality.supportsFiles(modalitiesInput);
}

bool _supportsChatInputAudio(_ChatInputAttachmentCapabilitiesRequest request) =>
    _ChatInputCapabilitiesFactory._supportsAudioAttachment(
      request.supportsLocalAttachments,
      request.modalitiesInput,
    );

bool _supportsChatInputImage(_ChatInputAttachmentCapabilitiesRequest request) =>
    _ChatInputCapabilitiesFactory._supportsImageAttachment(
      request.supportsAttachments,
      request.modalitiesInput,
    );

bool _supportsChatInputFile(_ChatInputAttachmentCapabilitiesRequest request) =>
    _ChatInputCapabilitiesFactory._supportsFileAttachment(
      request.supportsLocalAttachments,
      request.modalitiesInput,
    );

_ChatInputCapabilities _watchChatInputCapabilities(
  WidgetRef ref,
  ChatInputWidget input,
) {
  final workspaceCapabilities = ref.watch(
    workspaceSessionForRouteProvider(input.workspaceId)
        .select((session) => session.value?.capabilities),
  );

  return _ChatInputCapabilitiesFactory.create(
    workspaceCapabilities,
    input.modalitiesInput,
  );
}

_ChatInputActions _createChatInputActions(_ChatInputActionsRequest request) =>
    _ChatInputActions(
      ref: request.ref,
      hooks: request.hooks,
      input: request.input,
      isEmpty: request.isEmpty,
    );

_ChatInputState _assembleChatInputState(
  _ChatInputStateAssemblyRequest request,
) {
  final input = request.input;

  return _createChatInputState((
    actions: request.actions,
    isEmpty: request.actions.isEmpty,
    hooks: request.hooks,
    input: input,
    capabilities: _watchChatInputCapabilities(request.ref, input),
  ));
}

_ChatInputState _createChatInputState(_ChatInputStateRequest request) {
  final input = request.input;

  return _ChatInputState(
    actions: request.actions,
    capabilities: request.capabilities,
    hooks: request.hooks,
    input: input,
    isEmpty: request.isEmpty,
    shouldShowStopButton: input.showStopButton ?? input.isBusy,
  );
}

class const _ChatInputState({
  required final _ChatInputActions actions,
  required final _ChatInputCapabilities capabilities,
  required final _ChatInputHooks hooks,
  required final ChatInputWidget input,
  required final bool isEmpty,
  required final bool shouldShowStopButton,
});

class const _ChatInputLayout({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(child: _ChatInputGestureDetector(state: state));
  }
}

class const _ChatInputGestureDetector({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: _ChatInputSafeArea(state: state),
      onTap: state.hooks.draft.focusNode.requestFocus,
      behavior: .translucent,
    );
  }
}

class const _ChatInputSafeArea({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(top: false, child: _ChatInputPadding(state: state));
  }
}

class const _ChatInputPadding({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: _ChatInputField(
        state: state,
        footer: _ChatInputFooter(state: state),
        header: _ChatInputAgentSelector(
          compactControl: state.input.agentCompactControl,
          sheetControl: state.input.agentSheetControl,
        ),
      ),
    );
  }
}

class const _ChatInputField({
  required final _ChatInputState state,
  required final Widget footer,
  required final Widget header,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = this.state;

    return _ChatInputFieldView(
      actions: state.actions,
      controller: state.hooks.draft.controller,
      focusNode: state.hooks.draft.focusNode,
      footer: footer,
      header: header,
      isRecording: state.hooks.recording.isRecording.value,
    );
  }
}

class _ChatInputFieldView extends StatelessWidget {
  new({
    required _ChatInputActions actions,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Widget footer,
    required Widget header,
    required bool isRecording,
  }) : input = AuraInput(
         controller: controller,
         placeholder: const TextLocale(
           LocaleKeys.chats_screens_chat_conversation_message_placeholder,
         ),
         textInputAction: .send,
         readOnly: isRecording,
         maxLines: ChatInputWidget._maxInputLines,
         onSubmitted: (_) => unawaited(actions.sendMessage()),
         onTapOutside: (_) => focusNode.unfocus(),
         focusNode: focusNode,
         header: header,
         footer: footer,
       );

  final AuraInput input;

  @override
  Widget build(BuildContext context) => input;
}

class const _ChatInputAgentSelector({
  required final Widget compactControl,
  required final Widget sheetControl,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        child: compactControl,
        onTap: () => _showSelectorSheet(
          context: context,
          title: const TextLocale(LocaleKeys.agents_title),
          child: sheetControl,
        ),
      ),
    );
  }
}

class const _ChatInputActions({
  required final WidgetRef ref,
  required final _ChatInputHooks hooks,
  required final ChatInputWidget input,
  required final bool isEmpty,
});

extension on _ChatInputActions {
  _ChatInputDraftHooks get _draft => hooks.draft;
  _ChatInputRecordingHooks get _recording => hooks.recording;
}

extension _ChatInputDraftActions on _ChatInputActions {
  void disposeDraft() {
    if (_recording.isRecording.value || _recording.isStartingRecording.value) {
      unawaited(
        ref.read(localChatAttachmentUsecaseProvider).cancelVoiceRecording(),
      );
    }
    _draft.attachments.value.forEach(deleteUnsentAttachment);
    _recording.recordingTimer.value?.cancel();
  }

  void deleteUnsentAttachment(MessageAttachmentToCreate attachment) {
    unawaited(
      ref
          .read(localChatAttachmentUsecaseProvider)
          .deleteAttachment(attachment.localPath),
    );
  }

  void clearRecordingState() {
    _recording.recordingTimer.value?.cancel();
    _recording.recordingTimer.value = null;
    _recording.recordingElapsed.value = Duration.zero;
    _recording.isRecording.value = false;
    _recording.isStartingRecording.value = false;
  }

  Future<void> sendMessage() async {
    if (input.disabled || isEmpty) return;

    _draft.isSending.value = true;
    try {
      await _sendCurrentDraft();
    } finally {
      _resetSendingState();
    }
  }

  Future<void> _sendCurrentDraft() async {
    final draft = await _currentDraft();
    if (draft.text.isEmpty && draft.attachments.isEmpty) return;

    await _sendDraft(draft);
  }

  Future<ChatDraft> _currentDraft() async => .new(
    text: _draft.controller.text.trim(),
    attachments: await _collectDraftAttachments(),
  );
}

extension _ChatInputAttachmentActions on _ChatInputActions {
  Future<void> addPath(String path, {required String displayName}) async {
    final attachment = await _copyAttachment(path, displayName);
    if (!_supportsAttachment(attachment)) {
      deleteUnsentAttachment(attachment);
      _logger.warning('Unsupported attachment type: ${attachment.mimeType}');

      return;
    }
    _draft.attachments.value = [..._draft.attachments.value, attachment];
  }

  void pickFiles() => unawaited(_pickFiles());

  void pickImage(ImageSource source) => unawaited(_pickImage(source));
}

extension _ChatInputRecordingActions on _ChatInputActions {
  void startRecording() => unawaited(_startRecording());

  void stopRecording() {
    unawaited(_stopRecordingAndAddAttachment());
  }

  Future<void> _stopRecordingAndAddAttachment() async {
    final attachment = await _stopRecordingAttachment();
    if (attachment == null) {
      _logger.warning('Voice recording stopped without attachment');

      return;
    }

    _draft.attachments.value = [
      ..._draft.attachments.value,
      _withVoiceDisplayName(attachment, _draft.attachments.value),
    ];
    _logger.fine('Added voice attachment to draft');
  }

  void cancelRecording() {
    unawaited(_cancelRecording());
  }

  Future<void> _cancelRecording() async {
    if (_recording.isStartingRecording.value) return;

    await ref.read(localChatAttachmentUsecaseProvider).cancelVoiceRecording();
    clearRecordingState();
  }
}

extension _ChatInputFileActions on _ChatInputActions {
  Future<MessageAttachmentToCreate> _copyAttachment(
    String path,
    String displayName,
  ) {
    return ref
        .read(localChatAttachmentUsecaseProvider)
        .copyIntoAppStorage(
          path,
          displayName: AttachmentDisplayNames.unique(
            displayName,
            _draft.attachments.value.map(
              (attachment) => attachment.displayName,
            ),
          ),
        );
  }

  bool _supportsAttachment(MessageAttachmentToCreate attachment) {
    return ChatAttachmentModality.supports(
      attachment.modality,
      input.modalitiesInput,
      mimeType: attachment.mimeType,
    );
  }
}

extension _ChatInputFilePickerActions on _ChatInputActions {
  Future<void> _pickFiles() async {
    try {
      await _pickAndAddFiles();
    } on Object catch (error, stackTrace) {
      _logger.warning('Failed to attach files', error, stackTrace);
    }
  }

  Future<void> _pickAndAddFiles() async {
    final extensions = ChatAttachmentModality.pickerAllowedExtensions(
      input.modalitiesInput,
    );
    await _addPickedFiles(await _pickFilesFromDevice(extensions));
  }

  Future<fp.FilePickerResult?> _pickFilesFromDevice(
    List<String>? allowedExtensions,
  ) {
    return fp.FilePicker.pickFiles(
      allowedExtensions: allowedExtensions,
      type: allowedExtensions == null ? fp.FileType.any : fp.FileType.custom,
    );
  }

  Future<void> _addPickedFiles(fp.FilePickerResult? result) async {
    for (final file in result?.files ?? const <fp.PlatformFile>[]) {
      final path = file.path;
      if (path == null) continue;

      await addPath(path, displayName: file.name);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      await _pickAndAddImage(source);
    } on Object catch (error, stackTrace) {
      _logger.warning('Failed to attach image', error, stackTrace);
    }
  }

  Future<void> _pickAndAddImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    if (file == null) return;

    await addPath(file.path, displayName: _imageAttachmentLabelKey.tr());
  }
}

extension _ChatInputRecordingLifecycleActions on _ChatInputActions {
  Future<void> _startRecording() async {
    if (!_canStartRecording) return;

    _draft.focusNode.unfocus();
    _prepareRecording();
    try {
      await _startVoiceRecording();
      _finishStartingRecording();
    } on Object catch (_) {
      clearRecordingState();
    }
  }

  bool get _canStartRecording =>
      !input.disabled &&
      !_recording.isRecording.value &&
      !_recording.isStartingRecording.value;

  void _prepareRecording() {
    _recording.isRecording.value = true;
    _recording.isStartingRecording.value = true;
    _recording.recordingElapsed.value = Duration.zero;
  }

  Future<void> _startVoiceRecording() {
    final start = ref
        .read(localChatAttachmentUsecaseProvider)
        .startVoiceRecording();
    _recording.recordingStart.value = start;

    return start;
  }

  void _finishStartingRecording() {
    final startedAt = DateTime.now();
    _recording.isStartingRecording.value = false;
    _recording.recordingTimer.value?.cancel();
    _recording.recordingTimer.value = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        _updateRecordingElapsed(startedAt);
      },
    );
  }

  void _updateRecordingElapsed(DateTime startedAt) {
    _recording.recordingElapsed.value = DateTime.now().difference(startedAt);
  }
}

extension _ChatInputMessageActions on _ChatInputActions {
  Future<List<MessageAttachmentToCreate>> _collectDraftAttachments() async {
    final draftAttachments = [..._draft.attachments.value];
    if (!_recording.isRecording.value) return draftAttachments;

    final attachment = await _stopRecordingAttachment();
    if (attachment == null) return draftAttachments;

    draftAttachments.add(_withVoiceDisplayName(attachment, draftAttachments));

    return draftAttachments;
  }

  Future<void> _sendDraft(ChatDraft draft) async {
    try {
      await _sendDraftToConversation(draft);
    } on Object catch (error, stackTrace) {
      _draft.attachments.value = draft.attachments;
      _logger.warning('Failed to send draft', error, stackTrace);
    }
  }

  Future<void> _sendDraftToConversation(ChatDraft draft) async {
    final sendResult = input.onSendMessage(draft);
    _draft.controller.clear();
    _draft.attachments.value = const [];
    await _awaitSendResult(sendResult, draft);
  }

  Future<void> _awaitSendResult(
    FutureOr<void> sendResult,
    ChatDraft draft,
  ) async {
    try {
      await sendResult;
    } on Object catch (error, stackTrace) {
      _logger.warning('Failed to send draft', error, stackTrace);
      _restoreDraftAfterSendFailure(draft);
    }
  }

  void _restoreDraftAfterSendFailure(ChatDraft draft) {
    if (!ref.context.mounted) return;
    if (_draft.controller.text.isEmpty && _draft.attachments.value.isEmpty) {
      _draft.controller.text = draft.text;
      _draft.attachments.value = draft.attachments;
    }
  }

  void _resetSendingState() {
    if (ref.context.mounted) _draft.isSending.value = false;
  }
}

extension _ChatInputRecordingResultActions on _ChatInputActions {
  Future<MessageAttachmentToCreate?> _stopRecordingAttachment() async {
    if (!await _finishRecordingStart()) return null;

    return await _stopVoiceRecording();
  }

  Future<bool> _finishRecordingStart() async {
    if (!_recording.isStartingRecording.value) return true;

    try {
      await _recording.recordingStart.value;

      return true;
    } on Object catch (_) {
      clearRecordingState();

      return false;
    }
  }

  Future<MessageAttachmentToCreate?> _stopVoiceRecording() async {
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
      displayName: AttachmentDisplayNames.unique(
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
    builder: (context) => _SelectorSheet(title: title, child: child),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
  );
}

class const _SelectorSheet({
  required final Widget title,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _SelectorSheetFrame(title: title, child: child);
}

class const _SelectorSheetFrame({
  required final Widget title,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _SelectorSheetInsets(title: title, child: child);
}

class const _SelectorSheetInsets({
  required final Widget title,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SelectorSheetAnimated(
      title: title,
      child: child,
      maxHeight: _selectorSheetMaxHeight(context),
      bottomInset: _selectorSheetBottomInset(context),
    );
  }
}

double _selectorSheetBottomInset(BuildContext context) {
  final viewInsets = MediaQuery.viewInsetsOf(context);

  return viewInsets.bottom == 0
      ? MediaQuery.paddingOf(context).bottom
      : viewInsets.bottom;
}

double _selectorSheetMaxHeight(BuildContext context) =>
    MediaQuery.sizeOf(context).height * 0.75;

class const _SelectorSheetAnimated({
  required final Widget title,
  required final Widget child,
  required final double maxHeight,
  required final double bottomInset,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: _SelectorSheetContainer(
        title: title,
        child: child,
        maxHeight: maxHeight,
      ),
      curve: Curves.easeOut,
      duration: context.auraTheme.animation.fast,
    );
  }
}

class const _SelectorSheetContainer({
  required final Widget title,
  required final Widget child,
  required final double maxHeight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(context.auraTheme.fromBorderRadius(.xl));

    return _SelectorSheetSurface(
      decoration: .new(
        color: context.auraColors.surface,
        borderRadius: BorderRadius.vertical(top: radius),
      ),
      maxHeight: maxHeight,
      title: title,
      child: child,
    );
  }
}

class const _SelectorSheetSurface({
  required final BoxDecoration decoration,
  required final double maxHeight,
  required final Widget title,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: decoration,
      constraints: .new(maxHeight: maxHeight),
      child: _SelectorSheetContent(title: title, child: child),
    );
  }
}

class const _SelectorSheetContent({
  required final Widget title,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        AuraText(child: title, style: .heading5),
        const SizedBox(height: 16),
        Flexible(child: child),
      ],
    );
  }
}

abstract final class _ChatInputAttachmentMenuFactory {
  static AuraPopupMenuItem item(_AttachmentMenuItemRequest request) =>
      AuraPopupMenuItem(
        title: TextLocale(request.titleKey),
        onTap: request.enabled ? request.onTap : null,
        leading: AuraIcon(request.icon),
        trailing: request.enabled ? null : const _AttachmentUnsupportedHint(),
      );
}

class const _AttachmentUnsupportedHint() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTooltip(
      message: _attachmentUnsupportedKey.tr(),
      child: const AuraIcon(Icons.info_outline),
    );
  }
}

typedef _AttachmentMenuItemRequest = ({
  String titleKey,
  IconData icon,
  bool enabled,
  VoidCallback onTap,
});

List<AuraPopupMenuItem> _attachmentMenuItems(_ChatInputState state) => [
  ..._attachmentPickerItems(state),
  ..._conversationMenuItems(state),
];

List<AuraPopupMenuItem> _attachmentPickerItems(_ChatInputState state) => [
  _fileMenuItem(state),
  ..._photoMenuItems(state),
  ..._cameraMenuItems(state),
];

AuraPopupMenuItem _fileMenuItem(_ChatInputState state) =>
    _ChatInputAttachmentMenuFactory.item((
      titleKey: _attachFileKey,
      icon: Icons.attach_file,
      enabled: state.capabilities.attachments.supportsFile,
      onTap: state.actions.pickFiles,
    ));

List<AuraPopupMenuItem> _photoMenuItems(_ChatInputState state) {
  if (state.capabilities.isMacOS) return const [];

  return [_photoMenuItem(state)];
}

AuraPopupMenuItem _photoMenuItem(_ChatInputState state) =>
    _ChatInputAttachmentMenuFactory.item((
      titleKey: _attachPhotoKey,
      icon: Icons.photo_outlined,
      enabled: _supportsImageAttachments(state),
      onTap: () => state.actions.pickImage(.gallery),
    ));

List<AuraPopupMenuItem> _cameraMenuItems(_ChatInputState state) {
  if (!_isMobilePlatform) return const [];

  return [_cameraMenuItem(state)];
}

AuraPopupMenuItem _cameraMenuItem(_ChatInputState state) =>
    _ChatInputAttachmentMenuFactory.item((
      titleKey: _attachCameraKey,
      icon: Icons.photo_camera_outlined,
      enabled: _supportsImageAttachments(state),
      onTap: () => state.actions.pickImage(.camera),
    ));

bool _supportsImageAttachments(_ChatInputState state) =>
    state.capabilities.attachments.supportsLocalAttachments &&
    state.capabilities.attachments.supportsImage;

bool get _isMobilePlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

List<AuraPopupMenuItem> _conversationMenuItems(_ChatInputState state) => [
  _toolsMenuItem(state),
  if (state.input.onSkillsPress case final onSkillsPress?)
    _skillsMenuItem(onSkillsPress),
  ...?_continueMenuItem(state),
  if (state.input.onCompact case final onCompact?)
    _compactMenuItem(state, onCompact),
];

AuraPopupMenuItem _toolsMenuItem(_ChatInputState state) => AuraPopupMenuItem(
  title: const TextLocale(LocaleKeys.menu_tools),
  onTap: state.input.onToolsPress,
  leading: const AuraIcon(Icons.build_circle_outlined),
);

AuraPopupMenuItem _skillsMenuItem(VoidCallback onTap) => AuraPopupMenuItem(
  title: const TextLocale(LocaleKeys.skills_selector_title),
  onTap: onTap,
  leading: const AuraIcon(Icons.psychology_alt_outlined),
);

List<AuraPopupMenuItem>? _continueMenuItem(_ChatInputState state) {
  final onTap = state.input.onContinueAgent;
  final disabledHint = state.input.continueDisabledHint;
  if (onTap == null && disabledHint == null) return null;

  return [
    AuraPopupMenuItem(
      title: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_continue_agent,
      ),
      onTap: onTap,
      leading: const AuraIcon(Icons.play_circle_outline),
      trailing: onTap != null || disabledHint == null
          ? null
          : _DisabledMenuItemHint(localeKey: disabledHint),
    ),
  ];
}

AuraPopupMenuItem _compactMenuItem(_ChatInputState state, VoidCallback onTap) {
  final enabled = _canCompact(state);
  final disabledHint = state.input.compactDisabledHint;

  return AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.compaction_manual_button_tooltip),
    onTap: enabled ? onTap : null,
    leading: const AuraIcon(Icons.compress_outlined),
    trailing: enabled || disabledHint == null
        ? null
        : _DisabledMenuItemHint(localeKey: disabledHint),
  );
}

class const _DisabledMenuItemHint({required final String localeKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTooltip(
    message: localeKey.tr(),
    child: const AuraIcon(Icons.info_outline),
  );
}

bool _canCompact(_ChatInputState state) =>
    state.input.onCompact != null &&
    state.input.canCompact &&
    !state.input.disabled &&
    !state.input.isBusy &&
    !state.input.isCompacting;

class const _ChatInputFooter({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ChatInputFooterContent(state: state);
}

class const _ChatInputFooterContent({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: .infinity,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _ChatInputAttachments(state: state),
          _ChatInputDisabledHintSection(hint: state.input.disabledHint),
          _ChatInputControls(state: state),
        ],
      ),
    );
  }
}

class const _ChatInputAttachments({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final attachments = state.hooks.draft.attachments.value;

    return _ChatInputAttachmentVisibility(
      attachments: attachments,
      onRemove: _removeAttachment,
      enabled: !state.hooks.recording.isRecording.value,
      visible: attachments.isNotEmpty,
    );
  }

  void _removeAttachment(MessageAttachmentToCreate attachment) {
    state.actions.deleteUnsentAttachment(attachment);
    final attachments = state.actions.hooks.draft.attachments;
    attachments.value = [
      for (final item in attachments.value)
        if (item != attachment) item,
    ];
  }
}

class const _ChatInputAttachmentVisibility({
  required final List<MessageAttachmentToCreate> attachments,
  required final ValueChanged<MessageAttachmentToCreate> onRemove,
  required final bool enabled,
  required final bool visible,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      child: Column(
        children: [
          _AttachmentChips(
            attachments: attachments,
            onRemove: onRemove,
            enabled: enabled,
          ),
          const AuraSizedBox(height: .xs),
        ],
      ),
      visible: visible,
    );
  }
}

class const _ChatInputDisabledHintSection({required final Widget? hint})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (hint) {
    final Widget value => _ChatInputDisabledHint(child: value),
    null => const SizedBox.shrink(),
  };
}

class const _ChatInputDisabledHint({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChatInputDisabledHintText(child: child),
        const AuraSizedBox(height: .xs),
      ],
    );
  }
}

class const _ChatInputDisabledHintText({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: Row(
        children: [
          const AuraIcon(Icons.info_outline, size: .small),
          const SizedBox(width: 6),
          Expanded(child: child),
        ],
      ),
      style: .bodySmall,
    );
  }
}

class const _ChatInputControls({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ChatInputControlRow(state: state);
}

class const _ChatInputControlRow({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final input = state.input;

    return Row(
      children: [
        _ChatInputModeControls(state: state),
        if (input.onStop case final onStop?)
          _ChatInputStopControls(state: state, onStop: onStop),
        _ChatInputSendButton(state: state),
      ],
    );
  }
}

class const _ChatInputModeControls({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isRecording = state.hooks.recording.isRecording.value;
    if (isRecording) return _ChatInputRecordingControls(state: state);

    return Expanded(
      child: Row(
        children: [
          Expanded(child: _ChatInputBrowseControls(state: state)),
          if (state.capabilities.attachments.supportsAudio)
            _ChatInputAudioControl(state: state),
        ],
      ),
    );
  }
}

class const _ChatInputBrowseControls({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AttachmentMenu(state: state),
        const AuraSizedBox(width: .xs),
        Expanded(child: _ModelSelectorButton(state: state)),
        const AuraSizedBox(width: .xs),
      ],
    );
  }
}

class const _ChatInputRecordingControls({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(child: _ChatInputRecordingRow(state: state));
  }
}

class const _ChatInputRecordingRow({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RecordingCancelButton(state: state),
        const AuraSizedBox(width: .xs),
        _RecordingIndicatorSlot(state: state),
        _RecordingStopControlsSlot(state: state),
      ],
    );
  }
}

class const _RecordingIndicatorSlot({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _RecordingIndicator(
        elapsed: state.hooks.recording.recordingElapsed.value,
      ),
    );
  }
}

class const _RecordingStopControlsSlot({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        const AuraSizedBox(width: .xs),
        _RecordingStopButton(state: state),
        const AuraSizedBox(width: .xs),
      ],
    );
  }
}

class const _ChatInputAudioControl({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        _RecordingButton(
          icon: Icons.mic_none_outlined,
          onPressed: state.actions.startRecording,
          disabled: state.input.disabled,
          tooltip: _recordVoiceKey.tr(),
        ),
        const AuraSizedBox(width: .xs),
      ],
    );
  }
}

class const _ChatInputStopControls({
  required final _ChatInputState state,
  required final VoidCallback onStop,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        _StopGenerationButton(
          onStop: onStop,
          visible: state.shouldShowStopButton,
        ),
        const AuraSizedBox(width: .xs),
      ],
    );
  }
}

class const _AttachmentMenu({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPopupMenuButton(
      items: _attachmentMenuItems(state),
      icon: Icons.tune_rounded,
      tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip.tr(),
    );
  }
}

class const _ModelSelectorButton({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final input = state.input;

    return GestureDetector(
      child: input.modelCompactControl,
      onTap: () => _showSelectorSheet(
        context: context,
        title: const TextLocale(LocaleKeys.models_screens_select_model),
        child: input.modelSheetControl,
      ),
    );
  }
}

class const _RecordingButton({
  required final IconData icon,
  required final VoidCallback onPressed,
  required final bool disabled,
  required final String tooltip,
  final AuraTint? tint,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AuraIconButton(
        icon: icon,
        onPressed: onPressed,
        disabled: disabled,
        tint: tint,
        tooltip: tooltip,
      ),
    );
  }
}

class const _RecordingCancelButton({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _RecordingButton(
      icon: Icons.close_rounded,
      onPressed: state.actions.cancelRecording,
      disabled: state.hooks.recording.isStartingRecording.value,
      tooltip: _cancelRecordingKey.tr(),
    );
  }
}

class const _RecordingStopButton({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _RecordingButton(
      icon: Icons.stop_rounded,
      onPressed: state.actions.stopRecording,
      disabled: state.hooks.recording.isStartingRecording.value,
      tooltip: _stopRecordingKey.tr(),
      tint: .error,
    );
  }
}

class const _StopGenerationButton({
  required final VoidCallback onStop,
  required final bool visible,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      child: _StopGenerationButtonContent(onStop: onStop),
      visible: visible,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
    );
  }
}

class const _StopGenerationButtonContent({required final VoidCallback onStop})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTooltip(
      message: LocaleKeys.chats_screens_chat_conversation_stop_generation.tr(),
      child: AuraButton(
        onPressed: onStop,
        child: const AuraIcon(Icons.stop_rounded),
        variant: .outlined,
        tint: .error,
        size: .small,
      ),
    );
  }
}

class const _ChatInputSendButton({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ChatInputSendButtonView(
    onPressed: () => unawaited(state.actions.sendMessage()),
    disabled: _isSendButtonDisabled(state),
  );
}

class const _ChatInputSendButtonView({
  required final VoidCallback onPressed,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraButton(
      onPressed: onPressed,
      child: const AuraIcon(Icons.arrow_upward),
      size: .small,
      disabled: disabled,
    );
  }
}

bool _isSendButtonDisabled(_ChatInputState state) {
  final isRecording = state.hooks.recording.isRecording.value;

  return state.isEmpty && !isRecording ||
      state.input.disabled ||
      state.hooks.draft.isSending.value;
}

class const _AttachmentChips({
  required final List<MessageAttachmentToCreate> attachments,
  required final ValueChanged<MessageAttachmentToCreate> onRemove,
  final bool enabled = true,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.auraTheme.fromSpacing(.xs),
      runSpacing: context.auraTheme.fromSpacing(.xs),
      children: [
        for (final attachment in attachments)
          _AttachmentChip(
            attachment: attachment,
            enabled: enabled,
            onRemove: onRemove,
          ),
      ],
    );
  }
}

class const _AttachmentChip({
  required final MessageAttachmentToCreate attachment,
  required final bool enabled,
  required final ValueChanged<MessageAttachmentToCreate> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Icon(_attachmentIcon(attachment.modality)),
      label: Text(attachment.displayName),
      onDeleted: enabled ? () => onRemove(attachment) : null,
    );
  }
}

class const _RecordingIndicator({required final Duration elapsed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: _RecordingIndicatorRow(elapsed: elapsed),
    style: .bodySmall,
  );
}

class const _RecordingIndicatorRow({required final Duration elapsed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.graphic_eq, size: 18, color: context.auraColors.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${_recordingStatusKey.tr()} ${_formatElapsed(elapsed)}',
            overflow: .ellipsis,
          ),
        ),
      ],
    );
  }
}

String _formatElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

  return '$minutes:$seconds';
}

abstract final class AttachmentDisplayNames {
  @visibleForTesting
  static String unique(String displayName, Iterable<String> existingNames) {
    if (!existingNames.contains(displayName)) return displayName;

    final extension = p.extension(displayName);
    final baseName = extension.isEmpty
        ? displayName
        : p.basenameWithoutExtension(displayName);

    return _findAvailableAttachmentName(baseName, extension, existingNames);
  }
}

String _findAvailableAttachmentName(
  String baseName,
  String extension,
  Iterable<String> existingNames,
) {
  var index = 1;
  while (true) {
    final candidate = '$baseName ($index)$extension';
    if (!existingNames.contains(candidate)) return candidate;
    index += 1;
  }
}

IconData _attachmentIcon(MessageAttachmentModality modality) {
  return switch (modality) {
    .image => Icons.image_outlined,
    .audio => Icons.mic_none_outlined,
    .file => Icons.insert_drive_file_outlined,
  };
}
