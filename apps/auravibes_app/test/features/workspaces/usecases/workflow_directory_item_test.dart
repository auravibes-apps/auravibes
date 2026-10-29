import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_directory_move_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_item_duplication_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/data/repositories/workflows_repository.dart';
import 'package:auravibes_app/features/workflows/models/workflow_definition.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_directory_move_item.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_item_duplication.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'workflow item moves, duplicates, and restores with stable references',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('local'),
              name: 'Local',
              type: .local,
            ),
          );
      final folders = LocalWorkspaceFolderRepository(database, 'local');
      final sourceFolder = await folders.create(name: 'Source');
      final targetFolder = await folders.create(name: 'Target');
      final workflows = WorkflowsRepository(database);
      final now = DateTime.utc(2026, 10, 29);
      final child = await workflows.saveWorkflow(
        WorkspaceWorkflow.create(
          id: 'workflow-child',
          workspaceId: 'local',
          parentId: sourceFolder.id,
          name: 'Child',
          description: '',
          createdAt: now,
          updatedAt: now,
        ),
      );
      final parent = await workflows.saveWorkflow(
        WorkspaceWorkflow.create(
          id: 'workflow-parent',
          workspaceId: 'local',
          parentId: sourceFolder.id,
          name: 'Parent',
          description: '',
          nodes: [
            WorkflowNode(
              id: 'nested',
              kind: .workflow,
              targetId: child.id,
              label: 'Nested workflow',
              x: 0,
              y: 0,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(
        (await workflows.watchDirectory('local', sourceFolder.id).first).map(
          (workflow) => workflow.id,
        ),
        containsAll([child.id, parent.id]),
      );
      await LocalWorkspaceDirectoryMoveRepository(
        database,
        'local',
      ).move([WorkspaceDirectoryMoveItem.workflow(parent)], targetFolder.id);
      final moved = await workflows.getWorkflow(parent.id);
      expect(moved?.parentId, targetFolder.id);
      expect(moved?.revision, parent.revision + 1);
      expect(
        (await workflows.watchDirectory('local', targetFolder.id).first)
            .single
            .id,
        parent.id,
      );
      await expectLater(
        workflows.saveWorkflow(parent),
        throwsA(
          isA<WorkspaceTableException>().having(
            (error) => error.conflict,
            'conflict',
            true,
          ),
        ),
      );

      await LocalWorkspaceItemDuplicationRepository(database, 'local').copy(
        WorkspaceItemDuplication(
          kind: .workflow,
          sourceId: parent.id,
          expectedRevision: moved!.revision,
          targetId: 'workflow-copy',
          requestId: 'copy-request',
          name: 'Parent copy',
          parentId: targetFolder.id,
        ),
      );
      final copy = await workflows.getWorkflow('workflow-copy');
      expect(copy?.id, isNot(parent.id));
      expect(copy?.parentId, targetFolder.id);
      expect(copy?.nodes.single.targetId, child.id);

      final trash = ManageWorkspaceTrashUsecase(
        LocalWorkspaceTrashRepository(database, 'local'),
      );
      final batch = await trash.apply(
        WorkspaceTrashTarget(
          kind: .workflow,
          id: child.id,
          revision: child.revision,
        ),
        approve: (_) async => true,
      );
      expect(batch?.target.kind, WorkspaceTrashKind.workflow);
      expect(await workflows.getWorkflow(child.id), isNull);
      expect(
        (await workflows.getWorkflow(parent.id))?.nodes.single.targetId,
        child.id,
      );
      expect(
        (await workflows.getWorkflow('workflow-copy'))?.nodes.single.targetId,
        child.id,
      );

      await trash.restore(batch!.id);
      expect((await workflows.getWorkflow(child.id))?.id, child.id);
    },
  );
}
