import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/usecases/restore_compaction_checkpoint_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/compacted_message_details.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_provider_scope.dart';

const _workspaceId = 'workspace-1';
const _conversationId = 'conversation-1';
const _oldCheckpointId = 'summary-old';
const _activeCheckpointId = 'summary-current';
final _createdAt = DateTime(2026, 9, 20, 10);

class _RestoreUsecase extends Mock
    implements RestoreCompactionCheckpointUsecase;

class const _Subject({
  required final RestoreCompactionCheckpointUsecase restoreUsecase,
  required final Locale locale,
  required final List<MessageEntity> messages,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EasyLocalization(
    child: Builder(
      builder: (context) => MaterialApp(
        home: TestProviderScope(
          overrides: [
            conversationByIdStreamProvider(
              _workspaceId,
              conversationId: _conversationId,
            ).overrideWith((_) => Stream.value(_conversation)),
            chatMessagesByConversationProvider(
              _workspaceId,
              _conversationId,
            ).overrideWith((_) => Stream.value(messages)),
            restoreCompactionCheckpointUsecaseProvider.overrideWithValue(
              restoreUsecase,
            ),
          ],
          child: AuraThemeScope(
            theme: .light,
            child: Theme(
              data: .new(),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: CompactedMessageDetails(
                    message: _currentSummary,
                    workspaceId: _workspaceId,
                  ),
                ),
              ),
            ),
          ),
        ),
        locale: context.locale,
        localizationsDelegates: [
          ...context.localizationDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: context.supportedLocales,
      ),
    ),
    supportedLocales: const [Locale('en'), Locale('es')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );
}

final _conversation = ConversationEntity(
  id: _conversationId,
  title: 'Conversation',
  workspaceId: _workspaceId,
  isPinned: false,
  createdAt: _createdAt,
  updatedAt: _createdAt,
  revision: 17,
  activeCompactionCheckpointId: _activeCheckpointId,
);

final List<MessageEntity> _messages = [
  _message('before-user', 'Earlier user message', isUser: true),
  _message('before-assistant', 'Earlier assistant response'),
  _message(
    _oldCheckpointId,
    'Older checkpoint summary',
    messageType: .system,
    createdAt: _createdAt,
    metadata: .new(
      isCompactionSummary: true,
      compactedFromMessageId: 'before-user',
      compactedThroughMessageId: 'before-assistant',
      compactedMessageIds: const ['before-user', 'before-assistant'],
      compactionCreatedAt: _createdAt,
      compactionProviderId: 'openai',
      compactionModelId: 'gpt-test',
    ),
  ),
  _message('replay-user', 'Replay user message', isUser: true),
  _message('replay-assistant', 'Replay assistant response'),
  _message(
    'error-after',
    'Hidden error message',
    messageType: .system,
    status: .error,
  ),
  _message(
    _activeCheckpointId,
    'Current checkpoint summary',
    messageType: .system,
    metadata: const MessageMetadataEntity(
      isCompactionSummary: true,
      compactedFromMessageId: 'replay-user',
      compactedThroughMessageId: 'replay-assistant',
      compactedMessageIds: ['replay-user', 'replay-assistant'],
    ),
  ),
  _message('current-user', 'Current user message', isUser: true),
];

final MessageEntity _currentSummary = _message(
  _activeCheckpointId,
  'Current checkpoint summary',
  messageType: .system,
  metadata: const MessageMetadataEntity(isCompactionSummary: true),
);

MessageEntity _message(
  String id,
  String content, {
  bool isUser = false,
  MessageType messageType = .text,
  MessageStatus status = .sent,
  DateTime? createdAt,
  MessageMetadataEntity? metadata,
}) => MessageEntity(
  id: id,
  conversationId: _conversationId,
  content: content,
  messageType: messageType,
  isUser: isUser,
  status: status,
  createdAt: createdAt ?? _createdAt,
  updatedAt: createdAt ?? _createdAt,
  metadata: metadata,
);

void main() {
  setUpAll(() {
    registerFallbackValue((
      workspaceId: '',
      conversationId: '',
      checkpointMessageId: '',
      expectedConversationRevision: null,
      expectedMessages: null,
    ));
  });

  void stubRestoreUsecase(_RestoreUsecase restoreUsecase) {
    when(() => restoreUsecase.call(any()))
        .thenAnswer((_) => Future<void>.value());
  }

  testWidgets('previews the exact checkpoint replay before restoring', (
    tester,
  ) async {
    final restoreUsecase = _RestoreUsecase();
    stubRestoreUsecase(restoreUsecase);

    await _pump(tester, restoreUsecase);
    await _openHistory(tester);

    await _openPreview(tester);

    expect(find.text('Restore checkpoint preview'), findsOneWidget);
    expect(find.text('Active checkpoint'), findsNWidgets(2));
    expect(find.text('Checkpoint to restore'), findsOneWidget);
    expect(find.text('Older checkpoint summary'), findsOneWidget);
    expect(find.text('Current checkpoint summary'), findsNWidgets(2));
    expect(
      find.text(
        'This checkpoint has a different summary from the active checkpoint.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('replay-user'), findsNWidgets(2));
    expect(find.textContaining('before-user'), findsNWidgets(2));
    expect(find.textContaining('before-assistant'), findsNWidgets(3));
    expect(find.textContaining('openai/gpt-test'), findsNWidgets(2));
    expect(
      find.text('Replay starts after message before-assistant'),
      findsOneWidget,
    );
    expect(find.text('Messages that will be replayed: 3'), findsOneWidget);
    expect(find.textContaining('Sep 20, 2026'), findsNWidgets(2));
    expect(find.text('Replay user message'), findsOneWidget);
    expect(find.text('Replay assistant response'), findsOneWidget);
    expect(find.text('Current user message'), findsOneWidget);
    expect(find.text('Earlier user message'), findsNothing);
    expect(find.text('Earlier assistant response'), findsNothing);
    expect(find.text('Hidden error message'), findsNothing);
    final _ = verifyNever(() => restoreUsecase.call(any()));

    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Active checkpoint'), findsOneWidget);
    expect(find.text('Current checkpoint summary'), findsOneWidget);
    final _ = verifyNever(() => restoreUsecase.call(any()));
  });

  testWidgets('labels matching checkpoint summaries without duplicating text', (
    tester,
  ) async {
    final restoreUsecase = _RestoreUsecase();
    stubRestoreUsecase(restoreUsecase);
    final messages = _messages
        .map(
          (message) => message.id == _oldCheckpointId
              ? message.copyWith(content: 'Current checkpoint summary')
              : message,
        )
        .toList();

    await _pump(tester, restoreUsecase, messages: messages);
    await _openHistory(tester);
    await _openPreview(tester);

    expect(
      find.text(
        'This checkpoint has the same summary as the active checkpoint.',
      ),
      findsOneWidget,
    );
    expect(find.text('Current checkpoint summary'), findsNWidgets(2));
    expect(find.text('Older checkpoint summary'), findsNothing);
  });

  testWidgets('dismissal and repeated input do not restore a checkpoint', (
    tester,
  ) async {
    final restoreUsecase = _RestoreUsecase();
    stubRestoreUsecase(restoreUsecase);

    await _pump(tester, restoreUsecase);
    await _openHistory(tester);
    await _scrollToPreview(tester, 'Preview restore');

    final restoreAction = tester.widget<AuraButton>(
      find.ancestor(
        of: find.text('Preview restore'),
        matching: find.byType(AuraButton),
      ),
    );
    restoreAction.onPressed.call();
    restoreAction.onPressed.call();
    final _ = await tester.pumpAndSettle();

    expect(find.text('Restore checkpoint preview'), findsOneWidget);
    final _ = await tester.binding.handlePopRoute();
    final _ = await tester.pumpAndSettle();

    expect(find.text('Active checkpoint'), findsOneWidget);
    final _ = verifyNever(() => restoreUsecase.call(any()));
  });

  testWidgets('restores only after confirmation and uses the previewed id', (
    tester,
  ) async {
    final restoreUsecase = _RestoreUsecase();
    stubRestoreUsecase(restoreUsecase);

    await _pump(tester, restoreUsecase);
    await _openHistory(tester);
    await _openPreview(tester);

    final confirmation = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Restore checkpoint'),
        matching: find.byType(TextButton),
      ),
    );
    confirmation.onPressed?.call();
    confirmation.onPressed?.call();
    final _ = await tester.pumpAndSettle();

    final request =
        verify(() => restoreUsecase.call(captureAny())).captured.single
            as CompactionCheckpointRestoreRequest;
    expect(request.workspaceId, _workspaceId);
    expect(request.conversationId, _conversationId);
    expect(request.checkpointMessageId, _oldCheckpointId);
    expect(request.expectedConversationRevision, 17);
    expect(request.expectedMessages, _messages);
  });

  testWidgets(
    'reports a stale preview without changing the active checkpoint',
    (tester) async {
      final restoreUsecase = _RestoreUsecase();
      when(() => restoreUsecase.call(any()))
          .thenThrow(const CompactionStalePreviewException());

      await _pump(tester, restoreUsecase);
      await _openHistory(tester);
      await _openPreview(tester);
      await tester.tap(find.text('Restore checkpoint'));
      final _ = await tester.pumpAndSettle();

      expect(
        find.text(
          'This preview is out of date because the conversation changed while '
          'you reviewed it. Open a new preview before restoring.',
        ),
        findsOneWidget,
      );
      expect(find.text('Active checkpoint'), findsOneWidget);
      expect(find.text('Current checkpoint summary'), findsOneWidget);
    },
  );

  testWidgets('localizes preview labels in Spanish', (tester) async {
    final restoreUsecase = _RestoreUsecase();
    stubRestoreUsecase(restoreUsecase);

    await _pump(tester, restoreUsecase, locale: const Locale('es'));
    await tester.tap(find.text('Historial de puntos de control'));
    final _ = await tester.pumpAndSettle();
    final spanishRestoreLabel =
        'Vista previa de restauraci${String.fromCharCode(0xF3)}n';
    await _openPreview(tester, label: spanishRestoreLabel);

    expect(
      find.text('$spanishRestoreLabel del punto de control'),
      findsOneWidget,
    );
    expect(find.text('Punto de control que se restaurará'), findsOneWidget);
    expect(
      find.text(
        'Este punto de control tiene un resumen distinto del punto de control activo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Restaurar punto de control'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  RestoreCompactionCheckpointUsecase restoreUsecase, {
  Locale locale = const Locale('en'),
  List<MessageEntity> messages = _messages,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      _Subject(
        restoreUsecase: restoreUsecase,
        locale: locale,
        messages: messages,
      ),
    );
  });
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _openHistory(WidgetTester tester) async {
  await tester.tap(find.text('Checkpoint history'));
  final _ = await tester.pumpAndSettle();
}

Future<void> _openPreview(
  WidgetTester tester, {
  String label = 'Preview restore',
}) async {
  await _scrollToPreview(tester, label);
  await tester.tap(find.text(label));
  final _ = await tester.pumpAndSettle();
}

Future<void> _scrollToPreview(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  final _ = await tester.pumpAndSettle();
}
