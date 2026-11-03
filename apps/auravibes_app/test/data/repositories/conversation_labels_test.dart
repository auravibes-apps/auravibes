import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_labels_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppDatabase? _database;
  ConversationRepository? _repository;
  ConversationLabelsRepository? _labelsRepository;
  String? _workspaceId;
  String? _otherWorkspaceId;

  AppDatabase database() => _database!;
  ConversationRepository repository() => _repository!;
  ConversationLabelsRepository labelsRepository() => _labelsRepository!;
  String workspaceId() => _workspaceId!;
  String otherWorkspaceId() => _otherWorkspaceId!;

  setUp(() async {
    _database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    _repository = ConversationRepository(database());
    _labelsRepository = ConversationLabelsRepository(database());
    _workspaceId = (await database().workspaceDao.insertWorkspace(
      .insert(name: 'Workspace A', type: WorkspaceType.local),
    )).id;
    _otherWorkspaceId = (await database().workspaceDao.insertWorkspace(
      .insert(name: 'Workspace B', type: WorkspaceType.local),
    )).id;
  });

  tearDown(() async {
    await database().close();
    _database = null;
    _repository = null;
    _labelsRepository = null;
    _workspaceId = null;
    _otherWorkspaceId = null;
  });

  test(
    'labels are unique within a workspace and support rename and delete',
    () async {
      final label = await labelsRepository().createLabel(
        workspaceId: workspaceId(),
        name: ' Follow up ',
      );
      final sameNameInOtherWorkspace = await labelsRepository().createLabel(
        workspaceId: otherWorkspaceId(),
        name: 'follow up',
      );

      expect(label.name, 'Follow up');
      expect(sameNameInOtherWorkspace.workspaceId, otherWorkspaceId());
      await expectLater(
        labelsRepository().createLabel(
          workspaceId: workspaceId(),
          name: 'follow up',
        ),
        throwsA(isA<ConversationLabelAlreadyExistsException>()),
      );

      final renamed = await labelsRepository().renameLabel(
        workspaceId: workspaceId(),
        labelId: label.id,
        name: 'In progress',
      );
      expect(renamed.name, 'In progress');
      expect(
        (await labelsRepository().watchLabelsByWorkspace(workspaceId()).first).map(
          (item) => item.name,
        ),
        ['In progress'],
      );

      await labelsRepository().deleteLabel(
        workspaceId: workspaceId(),
        labelId: label.id,
      );
      expect(
        await labelsRepository().watchLabelsByWorkspace(workspaceId()).first,
        isEmpty,
      );
      expect(
        (await labelsRepository().watchLabelsByWorkspace(otherWorkspaceId()).first)
            .single
            .name,
        'follow up',
      );
    },
  );

  test(
    'assignments are workspace-scoped and filter before offset paging',
    () async {
      final urgent = await labelsRepository().createLabel(
        workspaceId: workspaceId(),
        name: 'Urgent',
      );
      final ideas = await labelsRepository().createLabel(
        workspaceId: workspaceId(),
        name: 'Ideas',
      );
      final otherWorkspaceLabel = await labelsRepository().createLabel(
        workspaceId: otherWorkspaceId(),
        name: 'Urgent',
      );
      final older = await database().conversationDao.insertConversation(
        .insert(
          workspaceId: workspaceId(),
          title: 'Older match',
          updatedAt: Value(DateTime.utc(2026, 11)),
        ),
      );
      final unlabelled = await database().conversationDao.insertConversation(
        .insert(
          workspaceId: workspaceId(),
          title: 'Unlabelled',
          updatedAt: Value(DateTime.utc(2026, 11, 2)),
        ),
      );
      final newer = await database().conversationDao.insertConversation(
        .insert(
          workspaceId: workspaceId(),
          title: 'Newer match',
          updatedAt: Value(DateTime.utc(2026, 11, 3)),
        ),
      );
      final foreignConversation = await database().conversationDao
          .insertConversation(
            .insert(
              workspaceId: otherWorkspaceId(),
              title: 'Foreign conversation',
            ),
          );

      await labelsRepository().setConversationLabels(
        workspaceId: workspaceId(),
        conversationId: older.id,
        labelIds: {urgent.id},
      );
      await labelsRepository().setConversationLabels(
        workspaceId: workspaceId(),
        conversationId: newer.id,
        labelIds: {ideas.id},
      );
      await expectLater(
        labelsRepository().setConversationLabels(
          workspaceId: otherWorkspaceId(),
          conversationId: foreignConversation.id,
          labelIds: {urgent.id},
        ),
        throwsA(isA<ConversationWorkspaceMismatchException>()),
      );

      final page = await labelsRepository()
          .watchConversationsByWorkspace(
            workspaceId(),
            labelIds: {urgent.id, ideas.id},
            limit: 1,
            offset: 1,
          )
          .first;
      expect(page.map((conversation) => conversation.title), ['Older match']);
      expect(page.single.labels.map((label) => label.name), ['Urgent']);
      expect(
        await labelsRepository()
            .watchConversationsByWorkspace(
              otherWorkspaceId(),
              labelIds: {urgent.id},
            )
            .first,
        isEmpty,
      );
      expect(
        (await labelsRepository()
                .watchConversationsByWorkspace(otherWorkspaceId())
                .first)
            .single
            .title,
        'Foreign conversation',
      );
      expect(unlabelled.id, isNotEmpty);
      expect(otherWorkspaceLabel.id, isNotEmpty);
    },
  );

  test(
    'deleting labels and conversations clears assignments, not conversations',
    () async {
      final label = await labelsRepository().createLabel(
        workspaceId: workspaceId(),
        name: 'Keep the chat',
      );
      final conversation = await database().conversationDao.insertConversation(
        .insert(workspaceId: workspaceId(), title: 'Keep me'),
      );
      await labelsRepository().setConversationLabels(
        workspaceId: workspaceId(),
        conversationId: conversation.id,
        labelIds: {label.id},
      );

      await labelsRepository().deleteLabel(
        workspaceId: workspaceId(),
        labelId: label.id,
      );
      expect(await repository().getConversationById(conversation.id), isNotNull);
      expect(
        await labelsRepository()
            .watchConversationsByWorkspace(workspaceId(), labelIds: {label.id})
            .first,
        isEmpty,
      );

      final secondLabel = await labelsRepository().createLabel(
        workspaceId: workspaceId(),
        name: 'Remove when chat is deleted',
      );
      await labelsRepository().setConversationLabels(
        workspaceId: workspaceId(),
        conversationId: conversation.id,
        labelIds: {secondLabel.id},
      );
      final _ = await repository().deleteConversation(conversation.id);
      expect(await repository().getConversationById(conversation.id), isNull);
      expect(
        (await labelsRepository().watchLabelsByWorkspace(workspaceId()).first)
            .single
            .id,
        secondLabel.id,
      );
      expect(
        await labelsRepository()
            .watchConversationsByWorkspace(
              workspaceId(),
              labelIds: {secondLabel.id},
            )
            .first,
        isEmpty,
      );
    },
  );
}
