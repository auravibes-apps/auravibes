// Required: Existing thresholds and limits use numeric values.
// Required: UI callbacks stay local to their widgets.
import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_draft.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/chats/usecases/local_chat_attachment_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_attachment_draft_preview.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_provider.dart';
import 'package:auravibes_app/features/skills/providers/conversation_skill_selector_state.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_asset_chooser.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/stable_ui_selector.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter_file_drop/flutter_file_drop.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

final _logger = Logger('chat_input_widget');

const double _chatInputHorizontalPadding = 16;
const double _chatInputVerticalPadding = 8;
const double _recordingButtonHorizontalPadding = 4;
const int _chatInputModelSheetModelFlex = 2;

typedef _ToolAccessModeOption = ({
  ConversationToolAccessMode mode,
  String label,
  String compactLabel,
  String description,
  String identifier,
});

typedef _ToolAccessModePresentation = ({
  String buttonLabel,
  String semanticLabel,
  bool iconOnly,
});

const _toolAccessModeOptions = <_ToolAccessModeOption>[
  (
    mode: ConversationToolAccessMode.defaultMode,
    label: LocaleKeys.chat_input_tool_access_default_label,
    compactLabel: LocaleKeys.chat_input_tool_access_default_compact_label,
    description: LocaleKeys.chat_input_tool_access_default_description,
    identifier: 'chat_tool_access_default',
  ),
  (
    mode: ConversationToolAccessMode.allowAll,
    label: LocaleKeys.chat_input_tool_access_allow_all_label,
    compactLabel: LocaleKeys.chat_input_tool_access_allow_all_compact_label,
    description: LocaleKeys.chat_input_tool_access_allow_all_description,
    identifier: 'chat_tool_access_allow_all',
  ),
];

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
const String _cameraAttachmentErrorKey =
    LocaleKeys.chats_screens_chat_conversation_camera_attachment_error;
const String _clearAllAttachmentsKey =
    LocaleKeys.chats_screens_chat_conversation_clear_all_attachments;
const Duration _maxVoiceRecordingDuration = .new(minutes: 2);
const double _chatInputCornerRadiusDelta = 4;

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
  required final Widget Function(VoidCallback onPressed) modelCompactControl,
  required final Widget Function(VoidCallback onPressed) agentCompactControl,
  final ValueChanged<bool>? onDraftStatusChanged,
  final String? conversationId,
  final bool autofocus = false,
  final ConversationToolAccessMode toolAccessMode =
      ConversationToolAccessMode.defaultMode,
  final ValueChanged<ConversationToolAccessMode>? onToolAccessModeChanged,
  final double topPadding = _chatInputVerticalPadding,
  final Widget? reasoningSettingsControl,
  final ChatDraft? draftToLoad,
  final List<String> modalitiesInput = const [],
  final VoidCallback? onSkillsPress,
  final VoidCallback? onContinueAgent,
  final String? continueDisabledHint,
  final Widget? disabledHint,
  final String? compactDisabledHint,
  final bool disabled = false,
  final bool acceptDroppedFilesWhenDisabled = false,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = _ChatInputHooksFactory.state(ref, this);
    _reportDraftStatus(context, this, state);

    return _ChatInputLayout(state: state);
  }
}

class const _ChatInputDraftHooks({
  required final TextEditingController controller,
  required final FocusNode focusNode,
  required final ValueNotifier<List<MessageAttachmentToCreate>> attachments,
  required final ValueNotifier<bool> isSending,
  required final ChatAttachmentAudioPreviewCoordinator audioPreviewCoordinator,
});

class const _ChatInputRecordingHooks({
  required final ValueNotifier<bool> isRecording,
  required final ValueNotifier<bool> isStartingRecording,
  required final ValueNotifier<Duration> recordingElapsed,
  required final ObjectRef<Timer?> recordingTimer,
  required final ObjectRef<Future<void>?> recordingStart,
  required final ObjectRef<Future<MessageAttachmentToCreate?>?> recordingStop,
});

class const _ChatInputHooks({
  required final _ChatInputDraftHooks draft,
  required final _ChatInputRecordingHooks recording,
  required final ObjectRef<LocalChatAttachmentUsecase?> attachmentUsecase,
});

typedef _ChatInputStateRequest = ({
  _ChatInputActions actions,
  _ChatInputHooks hooks,
  ChatInputWidget input,
  bool isEmpty,
  _ChatInputCapabilities capabilities,
});

abstract final class _ChatInputHooksFactory {
  static _ChatInputDraftHooks draft(ChatDraft? initialDraft) =>
      _ChatInputDraftHooks(
        controller: useTextEditingController(text: initialDraft?.text),
        focusNode: useFocusNode(),
        attachments: useState(
          initialDraft?.attachments ?? <MessageAttachmentToCreate>[],
        ),
        isSending: useState(false),
        audioPreviewCoordinator: useMemoized(
          ChatAttachmentAudioPreviewCoordinator.new,
        ),
      );

  static _ChatInputRecordingHooks recording() => _ChatInputRecordingHooks(
    isRecording: useState(false),
    isStartingRecording: useState(false),
    recordingElapsed: useState(Duration.zero),
    recordingTimer: useRef<Timer?>(null),
    recordingStart: useRef<Future<void>?>(null),
    recordingStop: useRef<Future<MessageAttachmentToCreate?>?>(null),
  );

  static _ChatInputHooks hooks(ChatDraft? initialDraft) => _ChatInputHooks(
    draft: draft(initialDraft),
    recording: recording(),
    attachmentUsecase: useRef<LocalChatAttachmentUsecase?>(null),
  );

  static _ChatInputState state(WidgetRef ref, ChatInputWidget input) {
    final initialDraft = _initialConversationDraft(ref, input);
    final hooks = _ChatInputHooksFactory.hooks(initialDraft);
    final actions = _createAndRegisterActions(
      ref: ref,
      hooks: hooks,
      input: input,
    );
    _registerDraftEffects(ref, input, actions, hooks.draft);

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

  static bool isEmpty(_ChatInputHooks hooks) {
    final isTextEmpty = useListenableSelector(
      hooks.draft.controller,
      () => hooks.draft.controller.text.trim().isEmpty,
    );
    final areAttachmentsEmpty = useListenableSelector(
      hooks.draft.attachments,
      () => hooks.draft.attachments.value.isEmpty,
    );

    return isTextEmpty && areAttachmentsEmpty;
  }

  static bool hasDraft(_ChatInputHooks hooks, {required bool isEmpty}) {
    final isRecording = useListenableSelector(
      hooks.recording.isRecording,
      () => hooks.recording.isRecording.value,
    );
    final isStartingRecording = useListenableSelector(
      hooks.recording.isStartingRecording,
      () => hooks.recording.isStartingRecording.value,
    );

    return !isEmpty || isRecording || isStartingRecording;
  }

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

ChatDraft? _initialConversationDraft(WidgetRef ref, ChatInputWidget input) {
  final conversationId = input.conversationId;
  if (conversationId == null) return null;

  final draftProvider = conversationDraftProvider(
    input.workspaceId,
    conversationId,
  );
  final _ = ref.watch(draftProvider.select((draft) => draft != null));

  return ref.read(draftProvider);
}

void _registerDraftEffects(
  WidgetRef ref,
  ChatInputWidget input,
  _ChatInputActions actions,
  _ChatInputDraftHooks draft,
) {
  useEffect(() => _loadDraftEffect(actions, input.draftToLoad), [
    input.draftToLoad,
  ]);
  useEffect(() => _saveConversationDraft(ref, input, draft), [
    input.workspaceId,
    input.conversationId,
  ]);
}

Dispose? _saveConversationDraft(
  WidgetRef ref,
  ChatInputWidget input,
  _ChatInputDraftHooks draft,
) {
  final conversationId = input.conversationId;
  if (conversationId == null) return null;

  final draftNotifier = ref.read(
    conversationDraftProvider(input.workspaceId, conversationId).notifier,
  );

  return _listenForConversationDraftChanges(draftNotifier, draft);
}

Dispose _listenForConversationDraftChanges(
  ConversationDraft draftNotifier,
  _ChatInputDraftHooks draft,
) {
  void save() => _saveCurrentConversationDraft(draftNotifier, draft);
  draft.controller.addListener(save);
  draft.attachments.addListener(save);

  return () {
    draft.controller.removeListener(save);
    draft.attachments.removeListener(save);
  };
}

void _saveCurrentConversationDraft(
  ConversationDraft draftNotifier,
  _ChatInputDraftHooks draft,
) {
  final current = ChatDraft(
    text: draft.controller.text,
    attachments: draft.attachments.value,
  );
  if (draft.isSending.value && current.isEmpty) return;

  draftNotifier.save(current);
}

void _reportDraftStatus(
  BuildContext context,
  ChatInputWidget input,
  _ChatInputState state,
) {
  final hasDraft = _ChatInputHooksFactory.hasDraft(
    state.hooks,
    isEmpty: state.isEmpty,
  );
  useEffect(() => _scheduleDraftStatusUpdate(context, input, hasDraft), [
    hasDraft,
    input.onDraftStatusChanged,
  ]);
}

VoidCallback? _scheduleDraftStatusUpdate(
  BuildContext context,
  ChatInputWidget input,
  bool hasDraft,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    input.onDraftStatusChanged?.call(hasDraft);
  });

  return null;
}

Dispose? _loadDraftEffect(_ChatInputActions actions, ChatDraft? draft) {
  if (draft == null) return null;

  var disposed = false;
  scheduleMicrotask(() {
    if (!disposed) actions.loadDraft(draft);
  });

  return () => disposed = true;
}

typedef _ChatInputAttachmentCapabilities = ({
  bool supportsExisting,
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
  required final bool supportsDrop,
  required final bool isMacOS,
  required final bool isLocalWorkspace,
});

abstract final class _ChatInputCapabilitiesFactory {
  static _ChatInputCapabilities create(
    WorkspaceCapabilities? workspaceCapabilities,
    List<String> modalitiesInput, {
    required bool isLocalWorkspace,
  }) => _ChatInputCapabilities(
    attachments: _createAttachmentCapabilities(
      workspaceCapabilities,
      modalitiesInput,
    ),
    supportsDrop: _supportsDrop(workspaceCapabilities),
    isMacOS: defaultTargetPlatform == TargetPlatform.macOS,
    isLocalWorkspace: isLocalWorkspace,
  );

  static bool _supportsDrop(WorkspaceCapabilities? capabilities) =>
      (capabilities?.attachments ?? false) &&
      (!kIsWeb || capabilities == WorkspaceCapabilities.cloud);

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
    supportsExisting:
        request.supportsAttachments == true &&
        MessageAttachmentModality.values.any(
          (modality) => ChatAttachmentModality.supports(
            modality,
            request.modalitiesInput,
          ),
        ),
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
  final workspaceSession = ref.watch(
    workspaceSessionForRouteProvider(input.workspaceId),
  );

  return _ChatInputCapabilitiesFactory.create(
    workspaceSession.value?.capabilities,
    input.modalitiesInput,
    isLocalWorkspace: workspaceSession.value?.workspace is LocalWorkspaceRef,
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

class const _ChatInputDropOverlay({required final bool isHighlighted})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: _ChatInputDropSurface(isHighlighted: isHighlighted),
    ),
  );
}

class const _ChatInputDropSurface({required final bool isHighlighted})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = context.auraColors.primary;
    final radius = context.auraTheme.fromBorderRadius(.xl);

    return DecoratedBox(
      key: isHighlighted ? const ValueKey('chat_input_drop_highlight') : null,
      decoration: _chatInputDropDecoration(isHighlighted, color, radius),
      child: _ChatInputDropLabel(color: color),
    );
  }
}

class const _ChatInputDropLabel({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: .center,
    mainAxisSize: .min,
    children: [
      Icon(Icons.file_upload_outlined, size: 36, color: color),
      const SizedBox(height: 8),
      const TextLocale(LocaleKeys.chat_input_drop_files_to_attach),
    ],
  );
}

BoxDecoration _chatInputDropDecoration(
  bool isHighlighted,
  Color color,
  double radius,
) => isHighlighted
    ? BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(radius),
      )
    : const BoxDecoration();

class const _ChatInputDropStack({
  required final Widget child,
  required final bool isActive,
  required final bool isHighlighted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (isActive) _ChatInputDropOverlay(isHighlighted: isHighlighted),
    ],
  );
}

void _handleChatInputDropPreview(
  ValueNotifier<bool> isActive,
  ValueNotifier<bool> isHovered,
  DropPreview preview,
) {
  final hasFiles = preview.items.any((item) => item.kind == DropItemKind.file);
  isActive.value = hasFiles;
  isHovered.value = hasFiles;
}

void _clearChatInputDropState(
  ValueNotifier<bool> isActive,
  ValueNotifier<bool> isHovered,
) {
  isActive.value = false;
  isHovered.value = false;
}

Future<void> _handleChatInputDrop(
  _ChatInputState state,
  DropResult result,
) async {
  if (!state.capabilities.supportsDrop ||
      (state.input.disabled && !state.input.acceptDroppedFilesWhenDisabled)) {
    return;
  }

  for (final resultItem in result.items) {
    final item = resultItem.item;
    if (!resultItem.accepted || item is! DropFile) continue;

    await _addDroppedChatFile(state, item);
  }
}

Future<void> _addDroppedChatFile(_ChatInputState state, DropFile file) async {
  try {
    await _readAndAttachDroppedChatFile(state, file);
  } on DropFileReadException catch (error, stackTrace) {
    _handleDroppedChatFileReadError(state, error, stackTrace);
  } on Object catch (error, stackTrace) {
    _logger.warning('Failed to attach dropped file', error, stackTrace);
  }
}

Future<void> _readAndAttachDroppedChatFile(
  _ChatInputState state,
  DropFile file,
) async {
  final bytes = await file.readAsBytes(
    maxBytes: ChatAttachmentModality.maxChatAttachmentBytes,
  );
  if (!state.actions.ref.context.mounted) return;

  await state.actions.addDroppedFile(
    bytes,
    fileName: file.name ?? 'attachment',
  );
}

void _handleDroppedChatFileReadError(
  _ChatInputState state,
  DropFileReadException error,
  StackTrace stackTrace,
) {
  if (error.reason == DropFileReadFailure.maxBytesExceeded) {
    if (state.actions.ref.context.mounted) {
      state.actions._showAttachmentError(
        const ChatAttachmentTooLargeException().localizationKey,
      );
    }

    return;
  }

  _logger.warning('Failed to read dropped file', error, stackTrace);
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: _chatInputHorizontalPadding,
      top: state.input.topPadding,
      right: _chatInputHorizontalPadding,
      bottom: _chatInputVerticalPadding,
    ),
    child: Align(
      alignment: .topCenter,
      child: _ChatInputFieldComposition(state: state),
    ),
  );
}

class const _ChatInputToolAccessMode({
  required final ConversationToolAccessMode value,
  required final ValueChanged<ConversationToolAccessMode> onChanged,
}) extends StatefulWidget {
  @override
  State<_ChatInputToolAccessMode> createState() =>
      _ChatInputToolAccessModeState();
}

class _ChatInputToolAccessModeState extends State<_ChatInputToolAccessMode> {
  final _focusNode = FocusNode();
  final _popupController = AuraPopupMenuController();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _toolAccessModePresentation(context, widget.value);

    return _ChatInputToolAccessModePopup(
      selectedMode: widget.value,
      buttonLabel: presentation.buttonLabel,
      semanticLabel: presentation.semanticLabel,
      iconOnly: presentation.iconOnly,
      onPressed: _popupController.toggle,
      onSelected: _selectMode,
      controller: _popupController,
      focusNode: _focusNode,
    );
  }

  void _selectMode(ConversationToolAccessMode mode) {
    widget.onChanged(mode);
  }
}

_ToolAccessModePresentation _toolAccessModePresentation(
  BuildContext context,
  ConversationToolAccessMode mode,
) {
  final selected = _toolAccessModeOptionFor(mode);

  return (
    buttonLabel: _toolAccessModeButtonLabel(context, selected),
    semanticLabel: _toolAccessModeSemanticLabel(selected),
    iconOnly: MediaQuery.sizeOf(context).width <= 480,
  );
}

_ToolAccessModeOption _toolAccessModeOptionFor(
  ConversationToolAccessMode mode,
) => _toolAccessModeOptions.firstWhere((option) => option.mode == mode);

String _toolAccessModeButtonLabel(
  BuildContext context,
  _ToolAccessModeOption option,
) => MediaQuery.sizeOf(context).width <= 400
    ? option.compactLabel
    : option.label;

String _toolAccessModeSemanticLabel(_ToolAccessModeOption selected) =>
    '${LocaleKeys.chat_input_tool_access_label.tr()}: ${selected.label.tr()}';

class const _ChatInputToolAccessModePopup({
  required final ConversationToolAccessMode selectedMode,
  required final String buttonLabel,
  required final String semanticLabel,
  required final bool iconOnly,
  required final VoidCallback onPressed,
  required final ValueChanged<ConversationToolAccessMode> onSelected,
  required final AuraPopupMenuController controller,
  required final FocusNode focusNode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTooltip(
    message: semanticLabel,
    child: AuraPopupMenu(
      child: _ChatInputToolAccessModeButton(
        buttonLabel: buttonLabel,
        semanticLabel: semanticLabel,
        iconOnly: iconOnly,
        onPressed: onPressed,
      ),
      items: _toolAccessModeMenuItems(selectedMode, onSelected),
      controller: controller,
      focusNode: focusNode,
    ),
  );
}

List<AuraPopupMenuEntry> _toolAccessModeMenuItems(
  ConversationToolAccessMode selectedMode,
  ValueChanged<ConversationToolAccessMode> onSelected,
) => [
  for (final option in _toolAccessModeOptions)
    _toolAccessModeMenuItem(option, selectedMode, onSelected),
];

AuraPopupMenuEntry _toolAccessModeMenuItem(
  _ToolAccessModeOption option,
  ConversationToolAccessMode selectedMode,
  ValueChanged<ConversationToolAccessMode> onSelected,
) => AuraPopupMenuItem(
  title: _ChatInputToolAccessModeMenuItemTitle(option: option),
  onTap: () => onSelected(option.mode),
  trailing: option.mode == selectedMode
      ? const AuraIcon(Icons.check_rounded, size: .small)
      : null,
  identifier: option.identifier,
);

class const _ChatInputToolAccessModeButton({
  required final String buttonLabel,
  required final String semanticLabel,
  required final bool iconOnly,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => iconOnly
      ? _ChatInputToolAccessModeIconButton(
          semanticLabel: semanticLabel,
          onPressed: onPressed,
        )
      : _ChatInputToolAccessModeTextButton(
          buttonLabel: buttonLabel,
          semanticLabel: semanticLabel,
          onPressed: onPressed,
        );
}

class const _ChatInputToolAccessModeIconButton({
  required final String semanticLabel,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.security_outlined,
    onPressed: onPressed,
    identifier: 'chat_tool_access_mode',
    semanticLabel: semanticLabel,
  );
}

class const _ChatInputToolAccessModeTextButton({
  required final String buttonLabel,
  required final String semanticLabel,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: _ChatInputToolAccessModeButtonLabel(buttonLabel: buttonLabel),
    variant: .ghost,
    size: .small,
    identifier: 'chat_tool_access_mode',
    semanticLabel: semanticLabel,
  );
}

class const _ChatInputToolAccessModeButtonLabel({
  required final String buttonLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      const AuraIcon(Icons.security_outlined, size: .small),
      const AuraSizedBox(width: .sm),
      TextLocale(
        buttonLabel,
        style: const .new(fontWeight: .w600),
        overflow: .ellipsis,
        maxLines: 1,
      ),
      const AuraSizedBox(width: .xs),
      const AuraIcon(Icons.keyboard_arrow_down_rounded, size: .small),
    ],
  );
}

class const _ChatInputToolAccessModeMenuItemTitle({
  required final _ToolAccessModeOption option,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      TextLocale(option.label),
      TextLocale(
        option.description,
        style: .new(
          color: context.auraColors.onSurfaceVariant,
          fontSize: context.auraTheme.typography.fontSizeSm,
        ),
      ),
    ],
  );
}

class const _ChatInputFieldComposition({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final field = _ChatInputField(
      state: state,
      footer: _ChatInputFooter(state: state),
      header: _ChatInputAgentSelector(state: state),
    );
    if (!state.capabilities.supportsDrop ||
        (state.input.disabled && !state.input.acceptDroppedFilesWhenDisabled)) {
      return field;
    }

    return _ChatInputDropTarget(state: state, child: field);
  }
}

class const _ChatInputDropTarget({
  required final _ChatInputState state,
  required final Widget child,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final isActive = useState(false);
    final isHovered = useState(false);

    return _ChatInputDropRegion(
      state: state,
      child: _ChatInputDropStack(
        child: child,
        isActive: isActive.value,
        isHighlighted: isHovered.value,
      ),
      onPreview: (preview) =>
          _handleChatInputDropPreview(isActive, isHovered, preview),
      onLeave: () => _clearChatInputDropState(isActive, isHovered),
    );
  }
}

class const _ChatInputDropRegion({
  required final _ChatInputState state,
  required final Widget child,
  required final ValueChanged<DropPreview> onPreview,
  required final VoidCallback onLeave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DropTarget(
    child: child,
    constraints: .new(allowedKinds: const {.file}),
    onEnter: onPreview,
    onMove: onPreview,
    onLeave: onLeave,
    onDrop: (result) => _handleChatInputDrop(state, result),
  );
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
      autofocus: state.input.autofocus,
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
    required bool autofocus,
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
         autofocus: autofocus,
         maxLines: ChatInputWidget._maxInputLines,
         onSubmitted: (_) => unawaited(actions.sendMessage()),
         onTapOutside: (_) => focusNode.unfocus(),
         focusNode: focusNode,
         header: AuraCornerRadiusScope.adjust(
           delta: _chatInputCornerRadiusDelta,
           child: header,
         ),
         footer: AuraCornerRadiusScope.adjust(
           delta: _chatInputCornerRadiusDelta,
           child: footer,
         ),
       );

  final AuraInput input;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('chat_composer'),
    child: AuraCornerRadiusScope.select(level: .xl, child: input),
    identifier: 'chat_composer',
  );
}

class const _ChatInputAgentSelector({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ChatInputAgentSelectorLayout(
    compactControl: state.input.agentCompactControl,
    sheetControl: state.input.agentSheetControl,
    workspaceId: state.input.workspaceId,
    conversationId: state.input.conversationId,
    onSkillsPress: state.input.onSkillsPress,
  );
}

class const _ChatInputAgentSelectorLayout({
  required final Widget Function(VoidCallback onPressed) compactControl,
  required final Widget sheetControl,
  required final String workspaceId,
  required final String? conversationId,
  required final VoidCallback? onSkillsPress,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: _ChatInputAgentSelectorControl(
            compactControl: compactControl,
            sheetControl: sheetControl,
          ),
        ),
        if (onSkillsPress case final onSkillsPress?) ...[
          const AuraSizedBox(width: .xs),
          _ChatInputSkillsControl(
            workspaceId: workspaceId,
            conversationId: conversationId,
            onPressed: onSkillsPress,
          ),
        ],
      ],
    ),
  );
}

class const _ChatInputAgentSelectorControl({
  required final Widget Function(VoidCallback onPressed) compactControl,
  required final Widget sheetControl,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StableUiSelector(
    identifier: 'chat_agent_selector',
    child: compactControl(() => _showAgentSelectorSheet(context, sheetControl)),
  );
}

void _showAgentSelectorSheet(BuildContext context, Widget sheetControl) {
  _showSelectorSheet(
    context: context,
    title: const TextLocale(LocaleKeys.agents_title),
    child: sheetControl,
  );
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

  LocalChatAttachmentUsecase get _attachmentUsecase {
    final cached = hooks.attachmentUsecase.value;
    if (cached != null) return cached;

    final created = ref.read(localChatAttachmentUsecaseProvider);
    hooks.attachmentUsecase.value = created;

    return created;
  }
}

extension _ChatInputDraftActions on _ChatInputActions {
  void loadDraft(ChatDraft draft) {
    _cacheAttachmentUsecase(draft);
    _deleteReplacedAttachments(draft);
    _draft.controller.value = .new(
      text: draft.text,
      selection: .collapsed(offset: draft.text.length),
    );
    _draft.attachments.value = draft.attachments;
    _draft.focusNode.requestFocus();
  }

  void _cacheAttachmentUsecase(ChatDraft draft) {
    if (draft.attachments.isNotEmpty) {
      final _ = _attachmentUsecase;
    }
  }

  void _deleteReplacedAttachments(ChatDraft draft) {
    final draftAttachmentPaths = draft.attachments
        .map((attachment) => attachment.localPath)
        .toSet();
    for (final attachment in _draft.attachments.value) {
      if (!draftAttachmentPaths.contains(attachment.localPath)) {
        deleteUnsentAttachment(attachment);
      }
    }
  }

  void disposeDraft() {
    _draft.audioPreviewCoordinator.dispose();
    if ((_recording.isRecording.value ||
            _recording.isStartingRecording.value) &&
        _recording.recordingStop.value == null) {
      unawaited(_attachmentUsecase.cancelVoiceRecording());
    }
    if (input.conversationId == null) {
      _draft.attachments.value.forEach(deleteUnsentAttachment);
    }
    _recording.recordingTimer.value?.cancel();
  }

  void discardDraft() {
    _draft.attachments.value.forEach(deleteUnsentAttachment);
    _draft.controller.clear();
    _draft.attachments.value = const [];
    final conversationId = input.conversationId;
    if (conversationId != null) {
      ref
          .read(
            conversationDraftProvider(
              input.workspaceId,
              conversationId,
            ).notifier,
          )
          .clear();
    }
  }

  void deleteUnsentAttachment(MessageAttachmentToCreate attachment) {
    if (attachment.assetId != null) return;
    unawaited(_attachmentUsecase.deleteAttachment(attachment.localPath));
  }

  void clearRecordingState() {
    _recording.recordingTimer.value?.cancel();
    _recording.recordingTimer.value = null;
    _recording.recordingElapsed.value = Duration.zero;
    _recording.isRecording.value = false;
    _recording.isStartingRecording.value = false;
  }

  Future<void> sendMessage() async {
    if (input.disabled || isEmpty || _draft.isSending.value) return;
    for (final attachment in _draft.attachments.value) {
      if (_supportsAttachment(attachment)) continue;
      _showAttachmentError(_modelAttachmentReasonKey(attachment.modality));

      return;
    }

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
    try {
      final attachment = await _copyAttachment(path, displayName);
      await _addAttachment(attachment);
    } on ChatAttachmentTooLargeException catch (error) {
      _showAttachmentError(error.localizationKey);
    }
  }

  Future<void> addDroppedFile(
    Uint8List bytes, {
    required String fileName,
  }) async {
    try {
      final displayName = AttachmentDisplayNames.unique(
        fileName,
        _draft.attachments.value.map((attachment) => attachment.displayName),
      );
      final attachment = await _attachmentUsecase.copyBytesIntoAppStorage(
        bytes,
        fileName: fileName,
        displayName: displayName,
      );
      await _addAttachment(attachment);
    } on ChatAttachmentTooLargeException catch (error) {
      _showAttachmentError(error.localizationKey);
    }
  }

  Future<void> _addAttachment(MessageAttachmentToCreate attachment) async {
    if (!ref.context.mounted) {
      await _discardDetachedAttachment(attachment);

      return;
    }

    if (!_canAddAttachment(attachment)) return;
    if (_alreadySelectedAsset(attachment)) return;

    _draft.attachments.value = [..._draft.attachments.value, attachment];
  }

  Future<void> _discardDetachedAttachment(
    MessageAttachmentToCreate attachment,
  ) async {
    if (attachment.assetId != null) return;
    await _attachmentUsecase.deleteAttachment(attachment.localPath);
  }

  bool _alreadySelectedAsset(MessageAttachmentToCreate attachment) =>
      attachment.assetId != null &&
      _draft.attachments.value.any(
        (value) => value.assetId == attachment.assetId,
      );

  bool _canAddAttachment(MessageAttachmentToCreate attachment) {
    if (input.acceptDroppedFilesWhenDisabled ||
        _supportsAttachment(attachment)) {
      return true;
    }

    deleteUnsentAttachment(attachment);
    _showAttachmentError(_modelAttachmentReasonKey(attachment.modality));
    _logger.warning('Unsupported attachment type: ${attachment.mimeType}');

    return false;
  }

  void _showAttachmentError(String localizationKey) {
    if (!ref.context.mounted) return;

    final _ = AuraSnackBars.show(
      context: ref.context,
      content: TextLocale(localizationKey),
      variant: .error,
    );
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
    if (!_canAddStoppedRecording(attachment)) return;

    final attachments = _draft.attachments.value;
    _draft.attachments.value = [
      ...attachments,
      _withVoiceDisplayName(attachment, attachments),
    ];
    _logger.fine('Added voice attachment to draft');
  }

  bool _canAddStoppedRecording(MessageAttachmentToCreate attachment) {
    if (_draft.isSending.value) return false;
    if (!ref.context.mounted) {
      deleteUnsentAttachment(attachment);

      return false;
    }

    return !_draft.attachments.value.any(
      (existing) => existing.localPath == attachment.localPath,
    );
  }

  void cancelRecording() {
    unawaited(_cancelRecording());
  }

  Future<void> _cancelRecording() async {
    if (_recording.isStartingRecording.value ||
        _recording.recordingStop.value != null) {
      return;
    }

    _recording.recordingTimer.value?.cancel();
    _recording.recordingTimer.value = null;
    try {
      await _attachmentUsecase.cancelVoiceRecording();
    } finally {
      clearRecordingState();
    }
  }
}

extension _ChatInputFileActions on _ChatInputActions {
  Future<MessageAttachmentToCreate> _copyAttachment(
    String path,
    String displayName,
  ) {
    return _attachmentUsecase.copyIntoAppStorage(
      path,
      displayName: AttachmentDisplayNames.unique(
        displayName,
        _draft.attachments.value.map((attachment) => attachment.displayName),
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

extension _ChatInputExistingAssets on _ChatInputActions {
  void selectExistingAsset() => unawaited(_selectExistingAsset());

  Future<void> _selectExistingAsset() async {
    final context = ref.context;
    try {
      final asset = await _chooseExistingAsset(context);
      if (asset == null || !context.mounted) return;
      await _addExistingAsset(asset, context);
    } on Object catch (error, stackTrace) {
      _logger.warning('Existing asset selection failed', error, stackTrace);
      if (!context.mounted) return;
      _showAttachmentError(_existingAssetError(error));
    }
  }

  Future<WorkspaceAsset?> _chooseExistingAsset(BuildContext context) =>
      showDialog<WorkspaceAsset>(
        context: context,
        builder: (_) => WorkspaceAssetChooser(workspaceId: input.workspaceId),
      );

  Future<void> _addExistingAsset(
    WorkspaceAsset asset,
    BuildContext context,
  ) async {
    final select = await ref.read(
      selectWorkspaceAssetAttachmentProvider(input.workspaceId).future,
    );
    final attachment = await select(asset.id);
    if (!context.mounted) return;
    await _addAttachment(attachment);
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

  Future<List<fp.PlatformFile>> _pickFilesFromDevice(
    List<String>? allowedExtensions,
  ) {
    return fp.FilePicker.pickFiles(
      allowedExtensions: allowedExtensions,
      type: allowedExtensions == null ? fp.FileType.any : fp.FileType.custom,
    );
  }

  Future<void> _addPickedFiles(List<fp.PlatformFile> files) async {
    for (final file in files) {
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
      if (source == ImageSource.camera) {
        _showAttachmentError(_cameraAttachmentErrorKey);
      }
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
    } on ChatMicrophonePermissionDeniedException catch (error) {
      clearRecordingState();
      _showAttachmentError(error.localizationKey);
    } on Object catch (_) {
      clearRecordingState();
    }
  }

  bool get _canStartRecording =>
      !input.disabled &&
      !_recording.isRecording.value &&
      !_recording.isStartingRecording.value &&
      _recording.recordingStop.value == null;

  void _prepareRecording() {
    _recording.recordingStop.value = null;
    _recording.isRecording.value = true;
    _recording.isStartingRecording.value = true;
    _recording.recordingElapsed.value = Duration.zero;
  }

  Future<void> _startVoiceRecording() {
    final start = _attachmentUsecase.startVoiceRecording();
    _recording.recordingStart.value = start;

    return start;
  }

  void _finishStartingRecording() {
    _recording.isStartingRecording.value = false;
    _recording.recordingTimer.value?.cancel();
    _recording.recordingTimer.value = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        _updateRecordingElapsed(timer.tick);
      },
    );
  }

  void _updateRecordingElapsed(int tick) {
    final elapsed = Duration(seconds: tick);
    _recording.recordingElapsed.value = elapsed < _maxVoiceRecordingDuration
        ? elapsed
        : _maxVoiceRecordingDuration;
    if (tick >= _maxVoiceRecordingDuration.inSeconds) stopRecording();
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
    final savedDraft = _readSavedConversationDraft();
    final sendResult = input.onSendMessage(draft);
    _draft.controller.clear();
    _draft.attachments.value = const [];
    if (await _awaitSendResult(sendResult, draft)) {
      _clearSavedConversationDraft(savedDraft);
    }
  }

  ChatDraft? _readSavedConversationDraft() {
    final conversationId = input.conversationId;
    if (conversationId == null) return null;

    return ref.read(
      conversationDraftProvider(input.workspaceId, conversationId),
    );
  }

  void _clearSavedConversationDraft(ChatDraft? savedDraft) {
    final conversationId = input.conversationId;
    if (conversationId == null) return;

    ref
        .read(
          conversationDraftProvider(input.workspaceId, conversationId).notifier,
        )
        .clearIfSame(savedDraft);
  }

  Future<bool> _awaitSendResult(
    FutureOr<void> sendResult,
    ChatDraft draft,
  ) async {
    try {
      await sendResult;
      await _deleteWebDraftAttachments(draft);

      return true;
    } on Object catch (error, stackTrace) {
      _logger.warning('Failed to send draft', error, stackTrace);
      _restoreDraftAfterSendFailure(draft);

      return false;
    }
  }

  Future<void> _deleteWebDraftAttachments(ChatDraft draft) async {
    if (!kIsWeb) return;
    for (final attachment in draft.attachments) {
      await _attachmentUsecase.deleteAttachment(attachment.localPath);
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
  Future<MessageAttachmentToCreate?> _stopRecordingAttachment() {
    final activeStop = _recording.recordingStop.value;
    if (activeStop != null) return activeStop;

    _recording.recordingTimer.value?.cancel();
    _recording.recordingTimer.value = null;

    return _shareRecordingStop(_stopRecordingOnce());
  }

  Future<MessageAttachmentToCreate?> _shareRecordingStop(
    Future<MessageAttachmentToCreate?> stop,
  ) {
    final completer = Completer<MessageAttachmentToCreate?>();
    final sharedStop = completer.future;
    _recording.recordingStop.value = sharedStop;
    unawaited(_completeRecordingStop(stop, completer, sharedStop));

    return sharedStop;
  }

  Future<void> _completeRecordingStop(
    Future<MessageAttachmentToCreate?> stop,
    Completer<MessageAttachmentToCreate?> completer,
    Future<MessageAttachmentToCreate?> sharedStop,
  ) async {
    try {
      completer.complete(await stop);
    } on Object catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      _clearRecordingStop(sharedStop);
    }
  }

  void _clearRecordingStop(Future<MessageAttachmentToCreate?> sharedStop) {
    if (identical(_recording.recordingStop.value, sharedStop)) {
      _recording.recordingStop.value = null;
    }
  }

  Future<MessageAttachmentToCreate?> _stopRecordingOnce() async {
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
      final attachment = await _attachmentUsecase.stopVoiceRecording();
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
  FocusManager.instance.primaryFocus?.unfocus();

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
        trailing: request.enabled
            ? null
            : _AttachmentUnsupportedHint(messageKey: request.reasonKey),
      );
}

class const _AttachmentUnsupportedHint({required final String messageKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTooltip(
      message: messageKey.tr(),
      child: const AuraIcon(Icons.info_outline),
    );
  }
}

typedef _AttachmentMenuItemRequest = ({
  String titleKey,
  IconData icon,
  bool enabled,
  String reasonKey,
  VoidCallback onTap,
});

List<AuraPopupMenuItem> _attachmentMenuItems(_ChatInputState state) => [
  ..._attachmentPickerItems(state),
  ..._conversationMenuItems(state),
];

List<AuraPopupMenuItem> _attachmentPickerItems(_ChatInputState state) => [
  _existingAssetMenuItem(state),
  _fileMenuItem(state),
  ..._photoMenuItems(state),
  ..._cameraMenuItems(state),
];

AuraPopupMenuItem _existingAssetMenuItem(_ChatInputState state) =>
    _ChatInputAttachmentMenuFactory.item((
      titleKey: LocaleKeys.workspace_assets_existing,
      icon: Icons.folder_outlined,
      enabled: state.capabilities.attachments.supportsExisting,
      reasonKey: _modelAttachmentReasonKey(.file),
      onTap: state.actions.selectExistingAsset,
    ));

AuraPopupMenuItem _fileMenuItem(_ChatInputState state) =>
    _ChatInputAttachmentMenuFactory.item((
      titleKey: _attachFileKey,
      icon: Icons.attach_file,
      enabled: state.capabilities.attachments.supportsFile,
      reasonKey: _fileAttachmentReasonKey(state),
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
      reasonKey: _imageAttachmentReasonKey(state),
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
      reasonKey: _imageAttachmentReasonKey(state),
      onTap: () => state.actions.pickImage(.camera),
    ));

String _fileAttachmentReasonKey(_ChatInputState state) =>
    _attachmentReasonKey(state, .file);

String _imageAttachmentReasonKey(_ChatInputState state) =>
    _attachmentReasonKey(state, .image);

String _audioAttachmentReasonKey(_ChatInputState state) =>
    _attachmentReasonKey(state, .audio);

String _attachmentReasonKey(
  _ChatInputState state,
  MessageAttachmentModality modality,
) => !state.capabilities.attachments.supportsLocalAttachments
    ? _localAttachmentUnavailableReasonKey(modality)
    : _modelAttachmentReasonKey(modality);

String _localAttachmentUnavailableReasonKey(
  MessageAttachmentModality modality,
) => switch (modality) {
  .file =>
    LocaleKeys
        .chats_screens_chat_conversation_attachment_file_local_unavailable,
  .image =>
    LocaleKeys
        .chats_screens_chat_conversation_attachment_image_local_unavailable,
  .audio =>
    LocaleKeys
        .chats_screens_chat_conversation_attachment_audio_local_unavailable,
};

String _modelAttachmentReasonKey(MessageAttachmentModality modality) =>
    switch (modality) {
      .file =>
        LocaleKeys
            .chats_screens_chat_conversation_attachment_file_model_unsupported,
      .image =>
        LocaleKeys
            .chats_screens_chat_conversation_attachment_image_model_unsupported,
      .audio =>
        LocaleKeys
            .chats_screens_chat_conversation_attachment_audio_model_unsupported,
    };

bool _supportsImageAttachments(_ChatInputState state) =>
    state.capabilities.attachments.supportsLocalAttachments &&
    state.capabilities.attachments.supportsImage;

bool get _isMobilePlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

List<AuraPopupMenuItem> _conversationMenuItems(_ChatInputState state) => [
  _toolsMenuItem(state),
  if (state.input.conversationId != null && !state.isEmpty)
    _discardDraftMenuItem(state),
  if (state.input.onSkillsPress case final onSkillsPress?)
    _skillsMenuItem(onSkillsPress),
  ?_continueMenuItem(state),
  if (state.input.onCompact case final onCompact?)
    _compactMenuItem(state, onCompact),
];

AuraPopupMenuItem _discardDraftMenuItem(_ChatInputState state) =>
    AuraPopupMenuItem(
      title: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_discard_draft,
      ),
      onTap: state.actions.discardDraft,
      leading: const AuraIcon(Icons.delete_outline),
    );

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

AuraPopupMenuItem? _continueMenuItem(_ChatInputState state) {
  final onTap = state.input.onContinueAgent;
  final disabledHint = state.input.continueDisabledHint;
  if (onTap == null && disabledHint == null) return null;

  return AuraPopupMenuItem(
    title: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_continue_agent,
    ),
    onTap: onTap,
    leading: const AuraIcon(Icons.play_circle_outline),
    trailing: _disabledMenuItemHint(onTap != null, disabledHint),
  );
}

AuraPopupMenuItem _compactMenuItem(_ChatInputState state, VoidCallback onTap) {
  final enabled = _canCompact(state);
  final disabledHint = state.input.compactDisabledHint;

  return AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.compaction_manual_button_tooltip),
    onTap: enabled ? onTap : null,
    leading: const AuraIcon(Icons.compress_outlined),
    trailing: _disabledMenuItemHint(enabled, disabledHint),
  );
}

Widget? _disabledMenuItemHint(bool enabled, String? localeKey) =>
    enabled || localeKey == null
    ? null
    : _DisabledMenuItemHint(localeKey: localeKey);

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

class const _LocalWorkspaceNetworkDisclosure() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = 'workspace_network_disclosure.title'.tr(context: context);

    return AuraIconButton(
      icon: Icons.public_outlined,
      onPressed: () =>
          unawaited(_LocalWorkspaceNetworkDisclosure._showDisclosure(context)),
      key: const ValueKey<String>('local_workspace_network_disclosure'),
      size: .small,
      semanticLabel: label,
      tooltip: label,
    );
  }

  static Future<void> _showDisclosure(BuildContext context) =>
      AuraDialogs.alert(
        context: context,
        title: const TextLocale('workspace_network_disclosure.title'),
        message: const TextLocale('workspace_network_disclosure.description'),
        dismissLabel: const TextLocale(LocaleKeys.common_close),
      );
}

class const _ChatInputAttachments({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final attachments = state.hooks.draft.attachments.value;

    return _ChatInputAttachmentVisibility(
      attachments: attachments,
      audioPreviewCoordinator: state.hooks.draft.audioPreviewCoordinator,
      onRemove: _removeAttachment,
      onClearAll: _clearAllAttachments,
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

  void _clearAllAttachments() {
    final attachments = state.hooks.draft.attachments.value;
    state.hooks.draft.attachments.value = const [];
    attachments.forEach(state.actions.deleteUnsentAttachment);
  }
}

class const _ChatInputAttachmentVisibility({
  required final List<MessageAttachmentToCreate> attachments,
  required final ChatAttachmentAudioPreviewCoordinator audioPreviewCoordinator,
  required final ValueChanged<MessageAttachmentToCreate> onRemove,
  required final VoidCallback onClearAll,
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
            audioPreviewCoordinator: audioPreviewCoordinator,
            onRemove: onRemove,
            onClearAll: onClearAll,
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
    final isRecording = state.hooks.recording.isRecording.value;
    final compact = MediaQuery.sizeOf(context).width <= 360;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _ChatInputPrimaryControls(
          state: state,
          isRecording: isRecording,
          compact: compact,
        ),
        _ChatInputCompactDisclosure(compact: compact, state: state),
      ],
    );
  }
}

class const _ChatInputPrimaryControls({
  required final _ChatInputState state,
  required final bool isRecording,
  required final bool compact,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ChatInputLeadingControls(
        state: state,
        isRecording: isRecording,
        compact: compact,
        showNetworkDisclosure: !compact,
      ),
      Expanded(
        child: _ChatInputModelAndTrailingControls(
          state: state,
          isRecording: isRecording,
        ),
      ),
    ],
  );
}

class const _ChatInputCompactDisclosure({
  required final bool compact,
  required final _ChatInputState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!compact || !state.capabilities.isLocalWorkspace) {
      return const SizedBox.shrink();
    }

    return const Align(
      alignment: .centerLeft,
      child: _LocalWorkspaceNetworkDisclosure(),
    );
  }
}

class const _ChatInputModelAndTrailingControls({
  required final _ChatInputState state,
  required final bool isRecording,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(child: _ModelSelectorButton(state: state)),
      if (isRecording) const AuraSizedBox(width: .xs),
      if (isRecording)
        _ChatInputRecordingControls(state: state)
      else if (!kIsWeb)
        _ChatInputAudioControl(state: state),
      _ChatInputStopOrSendButton(state: state),
    ],
  );
}

class const _ChatInputLeadingControls({
  required final _ChatInputState state,
  required final bool isRecording,
  required final bool compact,
  required final bool showNetworkDisclosure,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hasToolAccessMode = state.input.onToolAccessModeChanged != null;

    return Row(
      mainAxisSize: .min,
      children: [
        if (showNetworkDisclosure && state.capabilities.isLocalWorkspace)
          const _LocalWorkspaceNetworkDisclosure(),
        if (!isRecording) _ChatInputBrowseControls(state: state),
        if (!isRecording || hasToolAccessMode)
          _ChatInputControlSpacing(compact: compact),
        _ChatInputToolAccessModeControl(state: state, compact: compact),
      ],
    );
  }
}

class const _ChatInputToolAccessModeControl({
  required final _ChatInputState state,
  required final bool compact,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onChanged = state.input.onToolAccessModeChanged;
    if (onChanged == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: .min,
      children: [
        _ChatInputToolAccessMode(
          value: state.input.toolAccessMode,
          onChanged: onChanged,
        ),
        _ChatInputControlSpacing(compact: compact),
      ],
    );
  }
}

class const _ChatInputControlSpacing({required final bool compact})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraSizedBox(width: compact ? .none : .xs);
}

class const _ChatInputStopOrSendButton({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onStop = state.input.onStop;
    if (state.shouldShowStopButton && state.isEmpty && onStop != null) {
      return _StopGenerationButtonContent(onStop: onStop);
    }

    return _ChatInputSendButton(state: state);
  }
}

class const _ChatInputSkillsControl({
  required final String workspaceId,
  required final String? conversationId,
  required final VoidCallback onPressed,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConversationId = conversationId;
    final count = currentConversationId == null
        ? 0
        : _loadedSkillCount(
            ref.watch(
              conversationSkillSelectorProvider(
                workspaceId,
                currentConversationId,
              ),
            ),
          );
    final semanticLabel = LocaleKeys.chat_input_skills_control_count.tr(
      context: context,
      namedArgs: {'count': '$count'},
    );

    return _ChatInputSkillsButton(
      count: count,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
    );
  }
}

int _loadedSkillCount(AsyncValue<ConversationSkillSelectorState> selector) =>
    switch (selector) {
      AsyncData(:final value) => value.loaded.length,
      AsyncLoading(:final value?, hasValue: true) => value.loaded.length,
      AsyncLoading() || AsyncError() => 0,
    };

class const _ChatInputSkillsButton({
  required final int count,
  required final String semanticLabel,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTooltip(
    message: semanticLabel,
    child: _ChatInputSkillsButtonSemantics(
      count: count,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
    ),
  );
}

class const _ChatInputSkillsButtonSemantics({
  required final int count,
  required final String semanticLabel,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('chat_skills_button'),
    child: AuraButton(
      onPressed: onPressed,
      child: _ChatInputSkillsCount(count: count),
      variant: .outlined,
      size: .small,
    ),
    button: true,
    identifier: 'chat_skills_button',
    label: semanticLabel,
  );
}

class const _ChatInputSkillsCount({required final int count})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      const AuraIcon(Icons.psychology_alt_outlined, size: .small),
      const AuraSizedBox(width: .xs),
      Text('$count'),
    ],
  );
}

class const _ChatInputBrowseControls({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AttachmentMenu(state: state);
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
          disabled:
              state.input.disabled ||
              !state.capabilities.attachments.supportsAudio,
          tooltip: _audioRecordingTooltip(state),
          selectorId: 'chat_voice_button',
        ),
      ],
    );
  }
}

String _audioRecordingTooltip(_ChatInputState state) =>
    state.capabilities.attachments.supportsAudio
    ? _recordVoiceKey.tr()
    : _audioAttachmentReasonKey(state).tr();

class const _AttachmentMenu({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPopupMenuButton(
      items: _attachmentMenuItems(state),
      icon: Icons.tune_rounded,
      identifier: 'chat_attachment_options_button',
      tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip.tr(),
    );
  }
}

class const _ModelSelectorButton({required final _ChatInputState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTooltip(
      message: LocaleKeys.chats_screens_chat_conversation_model_effort_selector
          .tr(context: context),
      child: StableUiSelector(
        identifier: 'chat_model_selector',
        child: state.input.modelCompactControl(
          () => _showModelEffortSelector(context, state),
        ),
      ),
    );
  }
}

void _showModelEffortSelector(BuildContext context, _ChatInputState state) {
  _showSelectorSheet(
    context: context,
    title: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_model_effort_selector,
    ),
    child: _ChatInputModelEffortSheetContent(
      modelControl: state.input.modelSheetControl,
      reasoningControl: state.input.reasoningSettingsControl,
    ),
  );
}

class const _ChatInputModelEffortSheetContent({
  required final Widget modelControl,
  required final Widget? reasoningControl,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reasoningControl = this.reasoningControl;
    if (reasoningControl == null) return modelControl;

    return Column(
      children: [
        Expanded(flex: _chatInputModelSheetModelFlex, child: modelControl),
        const Divider(height: 1),
        Expanded(child: SingleChildScrollView(child: reasoningControl)),
      ],
    );
  }
}

class const _RecordingButton({
  required final IconData icon,
  required final VoidCallback onPressed,
  required final bool disabled,
  required final String tooltip,
  final AuraTint? tint,
  final String? selectorId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final selectorId = this.selectorId;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _recordingButtonHorizontalPadding,
      ),
      child: AuraIconButton(
        icon: icon,
        onPressed: onPressed,
        disabled: disabled,
        tint: tint,
        identifier: selectorId,
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
      disabled:
          state.hooks.recording.isStartingRecording.value ||
          state.hooks.recording.recordingStop.value != null,
      tooltip: _cancelRecordingKey.tr(),
      selectorId: 'chat_voice_cancel_button',
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
      disabled:
          state.hooks.recording.isStartingRecording.value ||
          state.hooks.recording.recordingStop.value != null,
      tooltip: _stopRecordingKey.tr(),
      tint: .error,
      selectorId: 'chat_voice_stop_button',
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
        identifier: 'chat_stop_generation',
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
      identifier: 'chat_send_button',
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
  required final ChatAttachmentAudioPreviewCoordinator audioPreviewCoordinator,
  required final ValueChanged<MessageAttachmentToCreate> onRemove,
  required final VoidCallback onClearAll,
  final bool enabled = true,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.auraTheme.fromSpacing(.xs),
      runSpacing: context.auraTheme.fromSpacing(.xs),
      children: [
        for (final attachment in attachments)
          ChatAttachmentDraftPreview(
            attachment: attachment,
            onRemove: onRemove,
            audioPreviewCoordinator: audioPreviewCoordinator,
            enabled: enabled,
          ),
        if (attachments.length > 1)
          _ClearAllAttachmentsButton(enabled: enabled, onPressed: onClearAll),
      ],
    );
  }
}

class const _ClearAllAttachmentsButton({
  required final bool enabled,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = _clearAllAttachmentsKey.tr();

    return AuraIconButton(
      icon: Icons.clear_all,
      onPressed: enabled ? onPressed : null,
      disabled: !enabled,
      identifier: 'chat_clear_all_attachments',
      semanticLabel: label,
      tooltip: label,
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
            '${_recordingStatusKey.tr()} ${_formatElapsed(elapsed)} / ${_formatElapsed(_maxVoiceRecordingDuration)}',
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
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

String _existingAssetError(Object error) => switch (error) {
  final WorkspaceAssetException error => error.localizationKey,
  _ => CloudAppErrors.localizationKey(error),
};
