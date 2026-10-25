// Required: Existing test and UI helpers keep compact return flow.

// Required: Test expectations use chaining on matchers which triggers.
// Cascade_invocations lint. Not applicable in test assertions.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_draft.dart';
import 'package:auravibes_app/features/chats/providers/background_work_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/local_chat_attachment_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/delete_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/duplicate_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/edit_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_use_case.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _FakeRepository implements WorkspaceRepository {
  Future<void> Function(String id)? beforeDeleteWorkspace;
  final List<WorkspaceEntity> _workspaces = [];
  var _nextId = 1;

  @override
  Future<List<WorkspaceEntity>> getAllWorkspaces() async =>
      List.unmodifiable(_workspaces);

  @override
  Stream<List<WorkspaceEntity>> watchAllWorkspaces() async* {
    yield List.unmodifiable(_workspaces);
  }

  @override
  Future<WorkspaceEntity?> getWorkspaceById(String id) async =>
      _workspaces.firstWhereOrNull((w) => w.id == id);

  @override
  Future<List<WorkspaceEntity>> getWorkspacesByType(WorkspaceType type) async =>
      _workspaces.where((w) => w.type == type).toList();

  @override
  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace) async {
    final entity = WorkspaceEntity(
      id: 'ws-${_nextId++}',
      name: workspace.name,
      type: workspace.type,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    _workspaces.add(entity);

    return entity;
  }

  @override
  Future<WorkspaceEntity> duplicateWorkspace(
    String id, {
    required String name,
  }) async {
    if (!await workspaceExists(id)) throw WorkspaceNotFoundException(id);

    return await createWorkspace(.new(name: name, type: .local));
  }

  @override
  Future<WorkspaceEntity> patchWorkspace(
    String id,
    WorkspacePatch workspace,
  ) async {
    final index = _workspaces.indexWhere((w) => w.id == id);
    if (index == -1) {
      throw WorkspaceNotFoundException(id);
    }

    final existing = _workspaces[index];
    final updated = existing.copyWith(
      name: workspace.name ?? existing.name,
      updatedAt: DateTime(2026),
    );
    _workspaces[index] = updated;

    return updated;
  }

  @override
  Future<bool> deleteWorkspace(String id) async {
    await beforeDeleteWorkspace?.call(id);
    final before = _workspaces.length;
    _workspaces.removeWhere((w) => w.id == id);

    return _workspaces.length < before;
  }

  @override
  Future<bool> workspaceExists(String id) async =>
      _workspaces.any((w) => w.id == id);

  @override
  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query) async =>
      _workspaces
          .where((w) => w.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

  @override
  Future<int> getWorkspaceCount() async => _workspaces.length;

  @override
  Future<int> getWorkspaceCountByType(WorkspaceType type) async =>
      _workspaces.where((w) => w.type == type).length;

  @override
  Future<bool> validateWorkspace(WorkspaceToCreate workspace) async => true;

  @override
  Future<bool> patchWorkspaceTimestamp(String id) async => true;

  @override
  Future<WorkspaceEntity?> getCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) async => null;

  @override
  Future<WorkspaceEntity?> getCloudWorkspaceMirrorByCloudId(
    String cloudWorkspaceId, {
    required String cloudAccountId,
    required String serverUrl,
  }) async => _workspaces.firstWhereOrNull(
    (w) =>
        w.cloudWorkspaceId == cloudWorkspaceId &&
        w.cloudAccountId == cloudAccountId &&
        w.url == serverUrl,
  );

  @override
  Future<WorkspaceEntity> upsertCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String name,
    required String serverUrl,
  }) {
    return createWorkspace(
      .new(
        name: name,
        type: WorkspaceType.remote,
        url: serverUrl,
        cloudWorkspaceId: cloudWorkspaceId,
        cloudAccountId: cloudAccountId,
      ),
    );
  }

  @override
  Future<bool> deleteCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) async => true;

  @override
  Future<int> deleteCloudWorkspaceMirrorsForAccount(
    String cloudAccountId, {
    String? serverUrl,
  }) async {
    final before = _workspaces.length;
    _workspaces.removeWhere(
      (w) =>
          w.cloudAccountId == cloudAccountId &&
          (serverUrl == null || w.url == serverUrl),
    );

    return before - _workspaces.length;
  }
}

void main() {
  group('ValidateWorkspaceNameUseCase', () {
    const usecase = ValidateWorkspaceNameUseCase();

    test('accepts name with exactly 3 characters', () {
      expect(() => usecase.call(name: 'abc'), returnsNormally);
    });

    test('accepts name with 20 characters', () {
      expect(() => usecase.call(name: 'a' * 20), returnsNormally);
    });

    test('accepts name within valid range', () {
      expect(() => usecase.call(name: 'My Workspace'), returnsNormally);
    });

    test('throws when name is empty', () {
      expect(
        () => usecase.call(name: ''),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws when name is 2 characters (below minimum)', () {
      expect(
        () => usecase.call(name: 'ab'),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws when name is 21 characters (above maximum)', () {
      expect(
        () => usecase.call(name: 'a' * 21),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('short name error has correct localization key', () {
      try {
        usecase.call(name: 'ab');
        fail('Expected exception');
      } on WorkspaceValidationException catch (e) {
        expect(e.localizationKey, isNotNull);
        expect(
          e.localizationKey,
          LocaleKeys.workspace_management_name_too_short_error,
        );
      }
    });

    test('long name error has correct localization key', () {
      try {
        usecase.call(name: 'a' * 21);
        fail('Expected exception');
      } on WorkspaceValidationException catch (e) {
        expect(e.localizationKey, isNotNull);
        expect(
          e.localizationKey,
          LocaleKeys.workspace_management_name_too_long_error,
        );
      }
    });
  });

  group('CreateWorkspaceUseCase', () {
    var fixture = _CreateWorkspaceUseCaseFixture();

    setUp(() {
      fixture = _CreateWorkspaceUseCaseFixture();
    });

    test('creates workspace with valid name', () async {
      final entity = await fixture.usecase.call(name: 'My Workspace');

      expect(entity.name, 'My Workspace');
      expect(entity.type, WorkspaceType.local);
    });

    test('trims whitespace from name', () async {
      final entity = await fixture.usecase.call(name: '  Workspace  ');

      expect(entity.name, 'Workspace');
    });

    test('throws for name shorter than 3 characters', () {
      expect(
        () => fixture.usecase.call(name: 'ab'),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws for name longer than 20 characters', () {
      expect(
        () => fixture.usecase.call(name: 'a' * 21),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });
  });

  group('EditWorkspaceUseCase', () {
    var fixture = _EditWorkspaceUseCaseFixture();

    setUp(() async {
      fixture = _EditWorkspaceUseCaseFixture();
      await fixture.setUp();
    });

    test('edits workspace name successfully', () async {
      final entity = await fixture.usecase.call(id: 'ws-1', name: 'New Name');

      expect(entity.name, 'New Name');
    });

    test('trims whitespace from edited name', () async {
      final entity = await fixture.usecase.call(
        id: 'ws-1',
        name: '  Updated  ',
      );

      expect(entity.name, 'Updated');
    });

    test('throws for invalid name', () {
      expect(
        () => fixture.usecase.call(id: 'ws-1', name: 'ab'),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });

    test('throws for name longer than 20 characters', () {
      expect(
        () => fixture.usecase.call(id: 'ws-1', name: 'a' * 21),
        throwsA(isA<WorkspaceValidationException>()),
      );
    });
  });

  group('DuplicateWorkspaceUseCase', () {
    test('copies workspace with the next available copy name', () async {
      final repository = _FakeRepository();
      final original = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Original', type: .local),
      );
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Original Copy', type: .local),
      );
      final usecase = DuplicateWorkspaceUseCase(
        repository: repository,
        validateName: const ValidateWorkspaceNameUseCase(),
      );

      final duplicate = await usecase.call(original.id);

      expect(duplicate.name, 'Original Copy 2');
      expect(await repository.getWorkspaceById(original.id), original);
    });

    test('truncates long source names before adding copy suffix', () async {
      final repository = _FakeRepository();
      final original = await repository.createWorkspace(
        const WorkspaceToCreate(name: '12345678901234567890', type: .local),
      );
      final usecase = DuplicateWorkspaceUseCase(
        repository: repository,
        validateName: const ValidateWorkspaceNameUseCase(),
      );

      final duplicate = await usecase.call(original.id);

      expect(duplicate.name, '123456789012345 Copy');
    });
  });

  group('DeleteWorkspaceUseCase', () {
    var fixture = _DeleteWorkspaceUseCaseFixture();

    setUp(() {
      fixture = _DeleteWorkspaceUseCaseFixture();
    });

    test('deletes workspace successfully', () async {
      final _ = await fixture.repository.createWorkspace(
        const WorkspaceToCreate(name: 'WS1', type: .local),
      );
      final _ = await fixture.repository.createWorkspace(
        const WorkspaceToCreate(name: 'WS2', type: .local),
      );
      fixture.repository.beforeDeleteWorkspace = (_) async =>
          fixture.calls.add('delete');

      await fixture.usecase.call(id: 'ws-1', activeWorkspaceId: 'ws-2');

      expect(fixture.calls, ['prepare', 'delete']);
      final remaining = await fixture.repository.getAllWorkspaces();
      expect(remaining, hasLength(1));
    });

    test('deletes last remaining workspace', () async {
      final _ = await fixture.repository.createWorkspace(
        const WorkspaceToCreate(name: 'Only', type: .local),
      );

      await fixture.usecase.call(id: 'ws-1', activeWorkspaceId: 'other');

      final remaining = await fixture.repository.getAllWorkspaces();
      expect(remaining, isEmpty);
    });

    test('deletes active workspace', () async {
      final _ = await fixture.repository.createWorkspace(
        const WorkspaceToCreate(name: 'WS1', type: .local),
      );
      final _ = await fixture.repository.createWorkspace(
        const WorkspaceToCreate(name: 'WS2', type: .local),
      );

      await fixture.usecase.call(id: 'ws-1', activeWorkspaceId: 'ws-1');

      expect(await fixture.repository.getWorkspaceCount(), 1);
    });

    test('allows deleting active workspace when it is the last one', () async {
      final _ = await fixture.repository.createWorkspace(
        const WorkspaceToCreate(name: 'Only', type: .local),
      );

      await fixture.usecase.call(id: 'ws-1', activeWorkspaceId: 'ws-1');

      final remaining = await fixture.repository.getAllWorkspaces();
      expect(remaining, isEmpty);
    });

    test('clears only drafts in a successfully deleted workspace', () async {
      final repository = _FakeRepository();
      final deletedWorkspace = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Delete', type: .local),
      );
      final otherWorkspace = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Keep', type: .local),
      );
      final attachmentUsecase = _RecordingLocalChatAttachmentUsecase();
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          attachmentFileStoreProvider.overrideWithValue(
            const AttachmentFileStore(
              storageNamespace: 'workspace-delete-test',
            ),
          ),

          workspaceRepositoryProvider.overrideWithValue(repository),
          backgroundWorkCoordinatorProvider.overrideWithValue(
            .new(_UnusedBackgroundWorkStore(), .new(), (_) async => null),
          ),
          localChatAttachmentUsecaseProvider.overrideWithValue(
            attachmentUsecase,
          ),
        ],
      );
      addTearDown(container.dispose);
      const attachment = MessageAttachmentToCreate(
        localPath: '/tmp/workspace-draft.txt',
        fileName: 'workspace-draft.txt',
        displayName: 'workspace-draft.txt',
        mimeType: 'text/plain',
        modality: .file,
        sizeBytes: 30,
      );
      const deletedDraft = ChatDraft(
        text: 'remove with workspace',
        attachments: [attachment],
      );
      const sameWorkspaceOtherDraft = ChatDraft(text: 'also remove');
      const otherWorkspaceDraft = ChatDraft(text: 'keep');
      final deletedDraftProvider = conversationDraftProvider(
        deletedWorkspace.id,
        'conversation-1',
      );
      final sameWorkspaceOtherDraftProvider = conversationDraftProvider(
        deletedWorkspace.id,
        'conversation-2',
      );
      final otherWorkspaceDraftProvider = conversationDraftProvider(
        otherWorkspace.id,
        'conversation-1',
      );
      container.read(deletedDraftProvider.notifier).save(deletedDraft);
      container
          .read(sameWorkspaceOtherDraftProvider.notifier)
          .save(sameWorkspaceOtherDraft);
      container
          .read(otherWorkspaceDraftProvider.notifier)
          .save(otherWorkspaceDraft);

      await container
          .read(deleteWorkspaceUseCaseProvider)
          .call(id: deletedWorkspace.id, activeWorkspaceId: otherWorkspace.id);

      expect(container.read(deletedDraftProvider), isNull);
      expect(container.read(sameWorkspaceOtherDraftProvider), isNull);
      expect(
        container.read(otherWorkspaceDraftProvider),
        same(otherWorkspaceDraft),
      );
      expect(attachmentUsecase.deletedPaths, [attachment.localPath]);
    });
  });
}

class _RecordingLocalChatAttachmentUsecase
    implements LocalChatAttachmentUsecase {
  final deletedPaths = <String>[];

  @override
  Future<void> deleteAttachment(String localPath) async {
    deletedPaths.add(localPath);
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedBackgroundWorkStore implements AgentBackgroundWorkStore {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class const _CreateWorkspaceUseCaseFixture._(
  final CreateWorkspaceUseCase usecase,
) {
  factory() {
    final repository = _FakeRepository();

    return _CreateWorkspaceUseCaseFixture._(
      .new(
        repository: repository,
        validateName: const ValidateWorkspaceNameUseCase(),
      ),
    );
  }
}

class const _EditWorkspaceUseCaseFixture._(
  final _FakeRepository repository,
  final EditWorkspaceUseCase usecase,
) {
  factory() {
    final repository = _FakeRepository();

    return _EditWorkspaceUseCaseFixture._(
      repository,
      .new(
        repository: repository,
        validateName: const ValidateWorkspaceNameUseCase(),
      ),
    );
  }

  Future<void> setUp() async {
    final _ = await repository.createWorkspace(
      const WorkspaceToCreate(name: 'Original', type: .local),
    );
  }
}

class const _DeleteWorkspaceUseCaseFixture._(
  final _FakeRepository repository,
  final DeleteWorkspaceUseCase usecase,
  final List<String> calls,
) {
  factory() {
    final repository = _FakeRepository();
    final calls = <String>[];

    return _DeleteWorkspaceUseCaseFixture._(
      repository,
      .new(
        repository: repository,
        prepareBackgroundWorkDeletion: (_) async => calls.add('prepare'),
        restoreBackgroundWorkAfterFailedDeletion: (_) => calls.add('restore'),
        clearWorkspaceDrafts: (_) => Future<void>.value(),
        cleanupDeletedAssets: Future<void>.value,
      ),
      calls,
    );
  }
}
