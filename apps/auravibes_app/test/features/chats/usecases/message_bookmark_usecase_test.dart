import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/message_bookmark_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/message_bookmark_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _WorkspaceRepository extends Mock implements WorkspaceRepository;
class _MessageRepository extends Mock implements MessageRepository;
class _CloudConversation extends Mock implements CloudConversationUsecase;

void main() {
  test('resolves an existing local workspace without cloud attach', () async {
    final repository = _WorkspaceRepository();
    final workspace = _localWorkspace('local');
    when(repository.getAllWorkspaces).thenAnswer((_) async => [workspace]);
    final usecase = _usecase(repository);

    expect(
      await usecase.resolveWorkspace(
        _bookmark(workspaceId: 'local'),
        attachAuthorizedWorkspace: ({required account, required workspaceId}) =>
            throw StateError(
              'Local bookmark must not attach a cloud workspace.',
            ),
      ),
      workspace,
    );
  });

  test('reuses a cloud mirror with matching workspace identity', () async {
    final repository = _WorkspaceRepository();
    final mirror = _cloudWorkspace('mirror');
    when(repository.getAllWorkspaces).thenAnswer((_) async => [mirror]);
    final usecase = _usecase(repository);

    expect(
      await usecase.resolveWorkspace(
        _bookmark(
          workspaceId: 'mirror',
          cloudServerUrl: 'https://cloud.example',
          cloudAccountId: 'account',
          cloudWorkspaceId: 42,
        ),
        attachAuthorizedWorkspace: ({required account, required workspaceId}) =>
            throw StateError('Matching mirror must not attach again.'),
      ),
      mirror,
    );
  });

  test(
    'attaches an authorized cloud workspace when mirror is missing',
    () async {
      final repository = _WorkspaceRepository();
      when(repository.getAllWorkspaces).thenAnswer((_) async => const []);
      CloudAccountKey? resolvedAccount;
      int? resolvedWorkspaceId;
      final mirror = _cloudWorkspace('mirror');
      final usecase = _usecase(repository);
      expect(
        await usecase.resolveWorkspace(
          _bookmark(
            cloudServerUrl: 'https://cloud.example/api',
            cloudAccountId: 'account',
            cloudWorkspaceId: 42,
          ),
          attachAuthorizedWorkspace:
              ({required account, required workspaceId}) {
                resolvedAccount = account;
                resolvedWorkspaceId = workspaceId;

                return Future.value(mirror);
              },
        ),
        mirror,
      );
      expect(
        resolvedAccount,
        CloudAccountKeyFactory.fromIdentity(
          'https://cloud.example/api',
          'account',
        ),
      );
      expect(resolvedWorkspaceId, 42);
    },
  );

  test('rejects cloud bookmark without identity metadata', () async {
    final repository = _WorkspaceRepository();
    when(repository.getAllWorkspaces).thenAnswer((_) async => const []);
    final usecase = _usecase(repository);

    await expectLater(
      usecase.resolveWorkspace(
        _bookmark(),
        attachAuthorizedWorkspace: ({required account, required workspaceId}) =>
            throw StateError('Incomplete identity must not attach.'),
      ),
      throwsA(
        isA<CloudAppException>().having(
          (error) => error.localizationKey,
          'localizationKey',
          LocaleKeys.cloud_errors_unavailable,
        ),
      ),
    );
  });

  test('toggles local bookmark through repository', () async {
    final workspaceRepository = _WorkspaceRepository();
    final messageRepository = _MessageRepository();
    when(
      () => messageRepository.bookmarkMessage(
        workspaceId: 'local',
        conversationId: 'conversation',
        messageId: 'message',
      ),
    ).thenAnswer((_) async => true);
    final usecase = MessageBookmarkUseCase(
      workspaceRepository: workspaceRepository,
      messageRepository: messageRepository,
    );

    expect(
      await usecase.toggle((
        workspaceId: 'local',
        conversationId: 'conversation',
        message: _message(),
        isBookmarked: false,
        resolveCloudConversation: () async => null,
      )),
      isFalse,
    );

    verify(
      () => messageRepository.bookmarkMessage(
        workspaceId: 'local',
        conversationId: 'conversation',
        messageId: 'message',
      ),
    ).called(1);
  });

  test('reports local bookmark persistence failure', () async {
    final workspaceRepository = _WorkspaceRepository();
    final messageRepository = _MessageRepository();
    when(
      () => messageRepository.bookmarkMessage(
        workspaceId: 'local',
        conversationId: 'conversation',
        messageId: 'message',
      ),
    ).thenAnswer((_) async => false);
    final usecase = MessageBookmarkUseCase(
      workspaceRepository: workspaceRepository,
      messageRepository: messageRepository,
    );

    await expectLater(
      usecase.toggle((
        workspaceId: 'local',
        conversationId: 'conversation',
        message: _message(),
        isBookmarked: false,
        resolveCloudConversation: () async => null,
      )),
      throwsA(isA<StateError>()),
    );
  });

  test('toggles cloud bookmark using canonical source identity', () async {
    final workspaceRepository = _WorkspaceRepository();
    final messageRepository = _MessageRepository();
    final cloud = _CloudConversation();
    when(
      () => cloud.unbookmarkMessage(
        conversationId: 'fork',
        sourceConversationId: 'root',
        messageId: 'source-message',
      ),
    ).thenAnswer((_) => Future.value());
    final usecase = MessageBookmarkUseCase(
      workspaceRepository: workspaceRepository,
      messageRepository: messageRepository,
    );

    expect(
      await usecase.toggle((
        workspaceId: 'cloud-mirror',
        conversationId: 'fork',
        message: _message(
          sourceConversationId: 'root',
          sourceMessageId: 'source-message',
        ),
        isBookmarked: true,
        resolveCloudConversation: () async => cloud,
      )),
      isTrue,
    );

    verify(
      () => cloud.unbookmarkMessage(
        conversationId: 'fork',
        sourceConversationId: 'root',
        messageId: 'source-message',
      ),
    ).called(1);
    verifyNoMoreInteractions(messageRepository);
  });
}

MessageBookmarkUseCase _usecase(WorkspaceRepository workspaceRepository) =>
    MessageBookmarkUseCase(
      workspaceRepository: workspaceRepository,
      messageRepository: _MessageRepository(),
    );

MessageEntity _message({
  String id = 'message',
  String conversationId = 'conversation',
  String? sourceConversationId,
  String? sourceMessageId,
}) => MessageEntity(
  id: id,
  conversationId: conversationId,
  content: 'Text',
  messageType: .text,
  isUser: true,
  status: .sent,
  createdAt: .new(2026),
  updatedAt: .new(2026),
  sourceConversationId: sourceConversationId,
  sourceMessageId: sourceMessageId,
);

MessageBookmarkEntity _bookmark({
  String? workspaceId,
  String? cloudServerUrl,
  String? cloudAccountId,
  int? cloudWorkspaceId,
}) => MessageBookmarkEntity(
  details: .new(
    messageId: 'message',
    conversationId: 'conversation',
    excerpt: 'excerpt',
    workspaceName: 'Workspace',
    createdAt: .new(2026),
  ),
  workspace: .new(
    workspaceId: workspaceId,
    cloudServerUrl: cloudServerUrl,
    cloudAccountId: cloudAccountId,
    cloudWorkspaceId: cloudWorkspaceId,
  ),
);

WorkspaceEntity _localWorkspace(String id) => WorkspaceEntity(
  id: id,
  name: 'Local',
  type: .local,
  createdAt: .new(2026),
  updatedAt: .new(2026),
);

WorkspaceEntity _cloudWorkspace(String id) => WorkspaceEntity(
  id: id,
  name: 'Cloud',
  type: .remote,
  createdAt: .new(2026),
  updatedAt: .new(2026),
  url: 'https://cloud.example',
  cloudWorkspaceId: '42',
  cloudAccountId: 'account',
);
