import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/providers/batch_tool_approval_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_selection_provider.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/features/chats/usecases/conversation_busy_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_messages_widget.dart';
import 'package:auravibes_app/features/chats/widgets/chat_tool_approval_card.dart';
import 'package:auravibes_app/features/models/providers/recent_model_selections_notifier.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/models/widgets/compact_workspace_model_selector.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../helpers/test_provider_scope.dart';
import 'fixtures/critical_conversation_action_fixtures.dart';

void main() {
  test('coverage table registers every action and both state expectations', () {
    final registeredActions = criticalConversationActionCases
        .map((scenario) => scenario.action)
        .toSet();

    expect(registeredActions, criticalConversationActions);
    expect(
      criticalConversationActionCases,
      hasLength(criticalConversationActions.length),
    );
    for (final scenario in criticalConversationActionCases) {
      expect(scenario.availableWhen, isNotEmpty);
      expect(scenario.unavailableWhen, isNotEmpty);
    }
  });

  for (final scenario in criticalConversationActionCases) {
    testWidgets(
      '${scenario.action.name} is reachable when ${scenario.availableWhen}',
      (tester) async {
        await _runMacScenario(
          () => _verifyAvailableScenario(tester, scenario.action),
        );
      },
    );

    testWidgets(
      '${scenario.action.name} is unavailable when ${scenario.unavailableWhen}',
      (tester) async {
        await _runMacScenario(
          () => _verifyUnavailableScenario(tester, scenario.action),
        );
      },
    );
  }
}

Future<void> _runMacScenario(Future<void> Function() scenario) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  try {
    await scenario();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<void> _verifyAvailableScenario(
  WidgetTester tester,
  CriticalConversationAction action,
) => switch (action) {
  .send => _sendAvailable(tester),
  .stop => _stopAvailable(tester),
  .retry => _retryAvailable(tester),
  .approve => _approveAvailable(tester),
  .skip => _skipAvailable(tester),
  .attach => _attachAvailable(tester),
  .selectModel => _selectModelAvailable(tester),
};

Future<void> _verifyUnavailableScenario(
  WidgetTester tester,
  CriticalConversationAction action,
) => switch (action) {
  .send => _sendUnavailable(tester),
  .stop => _stopUnavailable(tester),
  .retry => _retryUnavailable(tester),
  .approve || .skip => _approvalUnavailable(tester),
  .attach => _attachUnavailable(tester),
  .selectModel => _selectModelUnavailable(tester),
};

Future<void> _sendAvailable(WidgetTester tester) async {
  ChatDraft? sentDraft;
  await _pumpAndInit(
    tester,
    _inputApp(
      input: _inputSubject(onSendMessage: (draft) => sentDraft = draft),
    ),
  );
  await tester.enterText(find.byType(EditableText), 'A local message');
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey<String>('chat_send_button')));
  await tester.pump();

  expect(sentDraft?.text, 'A local message');
}

Future<void> _sendUnavailable(WidgetTester tester) async {
  var sendCount = 0;
  await _pumpAndInit(
    tester,
    _inputApp(input: _inputSubject(onSendMessage: (_) => sendCount++)),
  );
  final sendButton = find.descendant(
    of: find.byKey(const ValueKey<String>('chat_send_button')),
    matching: find.byType(AuraButton),
  );

  expect(tester.widget<AuraButton>(sendButton).disabled, isTrue);
  await tester.tap(find.byKey(const ValueKey<String>('chat_send_button')));
  await tester.pump();
  expect(sendCount, 0);
}

Future<void> _stopAvailable(WidgetTester tester) async {
  var stopped = false;
  await _pumpAndInit(
    tester,
    _inputApp(
      input: _inputSubject(
        onSendMessage: (_) {},
        isBusy: true,
        onStop: () => stopped = true,
      ),
    ),
  );

  final stopButton = find.byKey(const ValueKey<String>('chat_stop_generation'));
  expect(stopButton, findsOneWidget);
  await tester.tap(stopButton);
  expect(stopped, isTrue);
}

Future<void> _stopUnavailable(WidgetTester tester) async {
  var stopped = false;
  await _pumpAndInit(
    tester,
    _inputApp(
      input: _inputSubject(onSendMessage: (_) {}, onStop: () => stopped = true),
    ),
  );

  expect(
    find.byKey(const ValueKey<String>('chat_stop_generation')).hitTestable(),
    findsNothing,
  );
  expect(stopped, isFalse);
}

Future<void> _retryAvailable(WidgetTester tester) async {
  final message = criticalConversationUserMessage(
    id: 'failed-user-message',
    status: MessageStatus.error,
  );
  final retried = <String>[];
  await _pumpAndInit(
    tester,
    _messageSubject(
      message: message,
      onRetryMessage: (value) async => retried.add(value.id),
    ),
  );

  final retryButton = find.byKey(
    const ValueKey<String>('retry_message_failed-user-message'),
  );
  expect(retryButton, findsOneWidget);
  await tester.tap(retryButton);
  await tester.pump();
  expect(retried, ['failed-user-message']);
}

Future<void> _retryUnavailable(WidgetTester tester) async {
  final message = criticalConversationUserMessage(
    id: 'sent-user-message',
    status: MessageStatus.sent,
  );
  var retried = false;
  await _pumpAndInit(
    tester,
    _messageSubject(
      message: message,
      onRetryMessage: (_) async => retried = true,
    ),
  );

  expect(
    find.byKey(const ValueKey<String>('retry_message_sent-user-message')),
    findsNothing,
  );
  expect(retried, isFalse);
}

Future<void> _approveAvailable(WidgetTester tester) async {
  final actions = CriticalConversationBatchApprovalActions();
  await _pumpAndInit(
    tester,
    _approvalSubject(
      actions: actions,
      pendingCalls: criticalConversationPendingCalls,
    ),
  );

  final approveAll = find.byKey(
    const ValueKey<String>('tool_approval_allow_all'),
  );
  expect(approveAll, findsOneWidget);
  await tester.tap(approveAll);
  await tester.pump();

  expect(actions.approvedCalls.map((call) => call.toolCall.id), [
    'tool-call-1',
    'tool-call-2',
  ]);
}

Future<void> _skipAvailable(WidgetTester tester) async {
  final actions = CriticalConversationBatchApprovalActions();
  await _pumpAndInit(
    tester,
    _approvalSubject(
      actions: actions,
      pendingCalls: criticalConversationPendingCalls,
    ),
  );

  final skipAll = find.byKey(const ValueKey<String>('tool_approval_deny_all'));
  expect(skipAll, findsOneWidget);
  await tester.tap(skipAll);
  await tester.pump();

  expect(actions.skippedCalls.map((call) => call.toolCall.id), [
    'tool-call-1',
    'tool-call-2',
  ]);
}

Future<void> _approvalUnavailable(WidgetTester tester) async {
  await _pumpAndInit(
    tester,
    _approvalSubject(
      actions: CriticalConversationBatchApprovalActions(),
      pendingCalls: const [],
    ),
  );

  expect(
    find.byKey(const ValueKey<String>('tool_approval_allow_all')),
    findsNothing,
  );
  expect(
    find.byKey(const ValueKey<String>('tool_approval_deny_all')),
    findsNothing,
  );
}

Future<void> _attachAvailable(WidgetTester tester) async {
  final previousPicker = fp.FilePickerPlatform.instance;
  final picker = CriticalConversationFilePicker();
  final attachmentService = CriticalConversationAttachmentService();
  addTearDown(() => fp.FilePickerPlatform.instance = previousPicker);
  fp.FilePickerPlatform.instance = picker;

  await _pumpAndInit(
    tester,
    _inputApp(
      input: _inputSubject(
        onSendMessage: (_) {},
        modalitiesInput: const ['text', 'file'],
      ),
      attachmentService: attachmentService,
    ),
  );

  await tester.tap(
    find.byKey(const ValueKey<String>('chat_attachment_options_button')),
  );
  await tester.pump();
  await tester.tap(find.byIcon(Icons.attach_file));
  await tester.pumpAndSettle();

  expect(picker.pickCount, 1);
  expect(attachmentService.copyCount, 1);
  expect(find.text('brief.txt'), findsOneWidget);
}

Future<void> _attachUnavailable(WidgetTester tester) async {
  final previousPicker = fp.FilePickerPlatform.instance;
  final picker = CriticalConversationFilePicker();
  final attachmentService = CriticalConversationAttachmentService();
  addTearDown(() => fp.FilePickerPlatform.instance = previousPicker);
  fp.FilePickerPlatform.instance = picker;

  await _pumpAndInit(
    tester,
    _inputApp(
      input: _inputSubject(
        onSendMessage: (_) {},
        modalitiesInput: const ['text'],
      ),
      attachmentService: attachmentService,
    ),
  );

  await tester.tap(
    find.byKey(const ValueKey<String>('chat_attachment_options_button')),
  );
  await tester.pump();
  expect(find.byIcon(Icons.attach_file), findsOneWidget);
  await tester.tap(find.byIcon(Icons.attach_file));
  await tester.pump();

  expect(picker.pickCount, 0);
  expect(attachmentService.copyCount, 0);
  expect(find.text('brief.txt'), findsNothing);
}

Future<void> _selectModelAvailable(WidgetTester tester) async {
  final changes = <String?>[];
  final recents = CriticalConversationRecentModelsNotifier();
  await _pumpAndInit(
    tester,
    _modelSelectorSubject(
      groupedModels: {
        'fixture-connection': [criticalConversationModelSelection()],
      },
      recents: recents,
      onChanged: changes.add,
    ),
  );

  expect(find.text('Fixture Model'), findsOneWidget);
  await tester.tap(find.text('Fixture Model'));
  await tester.pump();

  expect(changes, [criticalConversationModelSelectionId]);
  expect(recents.recordedIds, [criticalConversationModelSelectionId]);
}

Future<void> _selectModelUnavailable(WidgetTester tester) async {
  final changes = <String?>[];
  await _pumpAndInit(
    tester,
    _modelSelectorSubject(
      groupedModels: const {},
      recents: CriticalConversationRecentModelsNotifier(),
      onChanged: changes.add,
    ),
  );

  expect(changes, isEmpty);
  expect(find.text('Fixture Model'), findsNothing);
  expect(find.text('Model'), findsOneWidget);
}

ChatInputWidget _inputSubject({
  required FutureOr<void> Function(ChatDraft draft) onSendMessage,
  VoidCallback onToolsPress = _ignore,
  bool isBusy = false,
  VoidCallback? onStop,
  List<String> modalitiesInput = const [],
  Widget modelSheetControl = const SizedBox.shrink(),
  Widget Function(VoidCallback onPressed)? modelCompactControl,
}) => ChatInputWidget(
  workspaceId: criticalConversationWorkspaceId,
  onSendMessage: onSendMessage,
  onToolsPress: onToolsPress,
  modelSheetControl: modelSheetControl,
  agentSheetControl: const SizedBox.shrink(),
  modelCompactControl:
      modelCompactControl ??
      (onPressed) => AuraTile(
        child: const Text('Model'),
        onTap: onPressed,
        variant: .outlined,
        size: .small,
      ),
  agentCompactControl: (onPressed) => AuraTile(
    child: const Text('Agent'),
    onTap: onPressed,
    variant: .outlined,
    size: .small,
  ),
  modalitiesInput: modalitiesInput,
  isBusy: isBusy,
  onStop: onStop,
);

Widget _modelSelectorSubject({
  required Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  groupedModels,
  required CriticalConversationRecentModelsNotifier recents,
  required ValueChanged<String?> onChanged,
}) => _localApp(
  overrides: [
    listModelsGroupedByProviderProvider.overrideWith(
      (ref, workspaceId) => Stream.value(groupedModels),
    ),
    recentModelSelectionsProvider(criticalConversationWorkspaceId)
        .overrideWith(() => recents),
  ],
  child: Scaffold(
    body: Portal(
      child: CompactWorkspaceModelSelector(
        workspaceId: criticalConversationWorkspaceId,
        workspaceModelSelectionId: null,
        onChanged: onChanged,
        sheetMode: true,
      ),
    ),
  ),
);

Widget _approvalSubject({
  required CriticalConversationBatchApprovalActions actions,
  required List<PendingToolCall> pendingCalls,
}) => _localApp(
  overrides: [batchToolApprovalUsecaseProvider.overrideWithValue(actions)],
  child: Material(
    child: ChatToolApprovalCard(
      workspaceId: criticalConversationWorkspaceId,
      conversationId: criticalConversationId,
      pendingCalls: pendingCalls,
    ),
  ),
);

Widget _messageSubject({
  required MessageEntity message,
  required Future<void> Function(MessageEntity message) onRetryMessage,
}) => _localApp(
  overrides: [
    conversationSelectedProvider.overrideWithValue(criticalConversationId),
    workspaceSessionForRouteProvider(
      criticalConversationWorkspaceId,
    ).overrideWithValue(
      const AsyncData(
        WorkspaceSession(
          LocalWorkspaceRef(localWorkspaceId: criticalConversationWorkspaceId),
        ),
      ),
    ),
    conversationByIdStreamProvider(
      criticalConversationWorkspaceId,
      conversationId: criticalConversationId,
    ).overrideWith((ref) => Stream.value(null)),
    childConversationsStreamProvider(
      criticalConversationWorkspaceId,
      parentConversationId: criticalConversationId,
    ).overrideWith((ref) => Stream.value(const <ConversationEntity>[])),
    messageConversationByIdProvider.overrideWith((ref, _) => message),
    isMessageStreamingProvider.overrideWith((ref, _) => false),
    conversationBusyStateProvider(
      criticalConversationWorkspaceId,
      criticalConversationId,
    ).overrideWith(
      (ref) async => const ConversationBusyState(
        isStreaming: false,
        hasPendingTools: false,
      ),
    ),
    conversationCompactionExecutionStateProvider(
      criticalConversationWorkspaceId,
      criticalConversationId,
    ).overrideWith((ref) => null),
  ],
  child: ChatPrimaryScrollController(
    child: Scaffold(
      body: ChatMessagesWidget(
        workspaceId: criticalConversationWorkspaceId,
        conversationId: criticalConversationId,
        messages: [message.id],
        messageEntitiesById: {message.id: message},
        onRetryMessage: onRetryMessage,
      ),
    ),
  ),
);

Widget _inputApp({
  required ChatInputWidget input,
  Widget? child,
  CriticalConversationAttachmentService? attachmentService,
  List<Override> overrides = const [],
}) => _localApp(
  overrides: [
    workspaceSessionForRouteProvider(
      criticalConversationWorkspaceId,
    ).overrideWithValue(
      const AsyncData(
        WorkspaceSession(
          LocalWorkspaceRef(localWorkspaceId: criticalConversationWorkspaceId),
        ),
      ),
    ),
    if (attachmentService case final service?)
      localChatAttachmentServiceProvider.overrideWithValue(service),
    ...overrides,
  ],
  child:
      child ??
      AuraSnackBarHost(
        child: Material(child: Portal(child: input)),
      ),
);

Widget _localApp({
  required Widget child,
  List<Override> overrides = const [],
}) => EasyLocalization(
  child: TestProviderScope(
    overrides: overrides,
    child: Builder(
      builder: (context) => MaterialApp(
        home: AuraThemeScope(
          theme: .light,
          child: Theme(
            data: ThemeData(),
            child: AuraLegacyMaterialBridge(child: child),
          ),
        ),
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
      ),
    ),
  ),
  supportedLocales: const [Locale('en')],
  path: 'assets/i18n',
  fallbackLocale: const Locale('en'),
  startLocale: const Locale('en'),
  useOnlyLangCode: true,
  useFallbackTranslations: true,
);

Future<void> _pumpAndInit(WidgetTester tester, Widget subject) async {
  await tester.runAsync(() async => tester.pumpWidget(subject));
  await tester.pump();
  await tester.pump();
}

void _ignore() {
  final _ = Object();
}
