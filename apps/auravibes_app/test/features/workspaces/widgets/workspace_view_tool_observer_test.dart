import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_tool_observer.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _Views extends Mock implements ManageWorkspaceViewsUsecase;

class _ViewData extends Mock implements WorkspaceViewData;

MessageEntity _message(List<MessageToolCallEntity> calls) => MessageEntity(
  id: 'message',
  conversationId: 'chat',
  content: '',
  messageType: .toolCall,
  isUser: false,
  status: .sent,
  createdAt: .new(2026),
  updatedAt: .new(2026),
  metadata: .new(toolCalls: calls),
);

MessageToolCallEntity _call(
  String id,
  String view, {
  String action = 'createView',
}) => MessageToolCallEntity(
  id: id,
  name: workspaceCommandToolName,
  argumentsRaw: jsonEncode({'action': action}),
  responseRaw: jsonEncode({'id': view, 'kind': 'view'}),
  resultStatus: .success,
);

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'opens only new successful authorized views once, not history or failures',
    (tester) async {
      final stream = StreamController<List<MessageEntity>>();
      addTearDown(stream.close);
      final views = _Views();
      when(() => views.open('allowed')).thenAnswer((_) async => _ViewData());
      when(() => views.open('denied'))
          .thenThrow(const WorkspaceTableException(denied: true));
      var retryCount = 0;
      when(() => views.open('retry')).thenAnswer((_) async {
        retryCount++;
        if (retryCount == 1) throw StateError('transient');

        return _ViewData();
      });
      final container = ProviderContainer(
        overrides: [
          chatMessagesProvider(
            'ws',
            'chat',
          ).overrideWith((ref) => stream.stream),
          workspaceViewUsecaseProvider('ws').overrideWith((ref) async => views),
        ],
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: EasyLocalization(
            supportedLocales: const [Locale('en')],
            path: 'assets/i18n',
            startLocale: const Locale('en'),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                home: const Scaffold(
                  body: WorkspaceViewToolObserver(
                    workspaceId: 'ws',
                    conversationId: 'chat',
                    child: SizedBox(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      });
      await tester.pumpAndSettle();
      final provider = workspaceOpenViewProvider('ws', 'chat');
      final subscription = container.listen(provider, (_, next) {
        final _ = next;
      });
      addTearDown(subscription.close);
      stream.add([
        _message([_call('old', 'allowed')]),
      ]);
      await tester.pump();
      expect(container.read(provider), isNull);
      stream.add([
        _message([_call('old', 'allowed'), _call('new', 'allowed')]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider)?.id, 'allowed');
      verify(() => views.open('allowed')).called(1);
      container.read(provider.notifier).close();
      stream.add([
        _message([
          _call('old', 'allowed'),
          _call('new', 'allowed'),
          _call('bad', 'denied', action: 'saveView'),
        ]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider), isNull);
      verify(() => views.open('denied')).called(1);
      expect(find.byType(SnackBarAction), findsNothing);
      final _ = verifyNever(() => views.open('allowed'));
      stream.add([
        _message([_call('retry-call', 'retry')]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider), isNull);
      expect(retryCount, 1);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBarAction), findsOneWidget);
      await tester.tap(find.byType(SnackBarAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider)?.id, 'retry');
      expect(retryCount, 2);
    },
  );
}
