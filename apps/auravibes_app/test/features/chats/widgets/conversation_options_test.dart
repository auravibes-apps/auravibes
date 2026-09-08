import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/features/chats/widgets/sidebar_conversations_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements ConversationRepository;

class _Cloud extends Mock implements CloudConversationUsecase;

void main() {
  for (final sidebar in [false, true]) {
    for (final cloud in [false, true]) {
      for (final confirm in [false, true]) {
        testWidgets('delete sidebar=$sidebar cloud=$cloud confirm=$confirm', (
          tester,
        ) async {
          final conversation = ConversationEntity(
            id: 'conversation',
            title: 'Conversation',
            workspaceId: 'workspace',
            isPinned: false,
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          );
          final repository = _Repository();
          final remote = _Cloud();
          when(() => repository.deleteConversation(conversation.id))
              .thenAnswer((_) async => true);
          when(() => remote.delete(conversation))
              .thenAnswer((_) => Future<void>.value());
          final container = ProviderContainer(
            overrides: [
              conversationsStreamProvider.overrideWith(
                (_, _) => Stream.value([conversation]),
              ),
              streamingTitleProvider.overrideWith((_, _) => null),
              listWorkspaceModelSelectionsProvider.overrideWith(
                (_, _) => Stream.value([]),
              ),
              cloudConversationUsecaseProvider.overrideWithValue(
                cloud ? remote : null,
              ),
              conversationRepositoryProvider.overrideWithValue(repository),
            ],
          );
          addTearDown(container.dispose);
          await tester.runAsync(() async {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: EasyLocalization(
                  child: Builder(
                    builder: (context) => MaterialApp(
                      home: RepaintBoundary(
                        key: const Key('conversation-options'),
                        child: Scaffold(
                          body: Portal(
                            child: sidebar
                                ? const SidebarConversationsWidget(
                                    workspaceId: 'workspace',
                                  )
                                : const ChatListWidget(
                                    workspaceId: 'workspace',
                                  ),
                          ),
                        ),
                      ),
                      theme: ThemeData(extensions: [AuraTheme.light]),
                      locale: context.locale,
                      localizationsDelegates: context.localizationDelegates,
                      supportedLocales: context.supportedLocales,
                    ),
                  ),
                  supportedLocales: const [Locale('en')],
                  path: 'assets/i18n',
                  startLocale: const Locale('en'),
                ),
              ),
            );
          });
          final _ = await tester.pumpAndSettle();
          expect(find.text('Conversation'), findsOneWidget);
          if (sidebar && !cloud && !confirm) {
            await expectLater(
              find.byKey(const Key('conversation-options')),
              matchesGoldenFile('goldens/conversation_options.png'),
            );
          }
          await tester.tap(find.byIcon(Icons.more_vert));
          final _ = await tester.pumpAndSettle();
          await tester.tap(find.text('Delete'));
          final _ = await tester.pumpAndSettle();
          verifyZeroInteractions(repository);
          verifyZeroInteractions(remote);
          await tester.tap(find.text(confirm ? 'Delete' : 'Cancel').last);
          final _ = await tester.pumpAndSettle();
          if (confirm && cloud) {
            verify(() => remote.delete(conversation)).called(1);
          } else if (confirm) {
            verify(() => repository.deleteConversation(conversation.id))
                .called(1);
          }
          verifyNoMoreInteractions(repository);
          verifyNoMoreInteractions(remote);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
