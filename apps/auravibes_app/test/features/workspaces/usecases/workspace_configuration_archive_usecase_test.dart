import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:auravibes_app/features/workspaces/services/workspace_configuration_file_service.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_configuration_archive_usecase.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports local configuration through the file service', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspace = await WorkspaceRepository(
      database,
    ).createWorkspace(const WorkspaceToCreate(name: 'Workspace', type: .local));
    final fileService = _MemoryFileService();
    final usecase = WorkspaceConfigurationArchiveUsecase(
      localRepository: .new(database),
      localImporter: .new(database),
      cloudRepositoryFor: (_) async =>
          throw StateError('Local export must not request a cloud repository.'),
      fileService: fileService,
    );

    expect(await usecase.exportArchive(workspace), isTrue);
    final savedJson = fileService.savedJson;
    if (savedJson == null) fail('No archive was saved.');
    expect(
      WorkspaceConfigurationArchiveCodec.decode(savedJson).workspaceName,
      workspace.name,
    );
  });

  test('preview is read-only and applying it imports once', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final json = WorkspaceConfigurationArchiveCodec.encode(
      const WorkspaceConfigurationArchive(
        workspaceName: 'Imported',
        entries: [],
      ),
    );
    final usecase = WorkspaceConfigurationArchiveUsecase(
      localRepository: .new(database),
      localImporter: .new(database),
      cloudRepositoryFor: (_) async =>
          throw StateError('Local import must not request a cloud repository.'),
      fileService: _MemoryFileService(pickedJson: json),
    );

    final preview = await usecase.pickArchivePreview();
    if (preview == null) fail('No archive preview was returned.');

    expect(preview.workspaceName, 'Imported');
    expect(
      WorkspaceConfigurationKind.values.map(preview.countFor),
      everyElement(0),
    );
    expect(await database.workspaceDao.getWorkspaceCount(), 0);

    await usecase.applyArchivePreview(preview);
    expect(await database.workspaceDao.getWorkspaceCount(), 1);
  });

  test('invalid archive preview leaves stores unchanged', () async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final usecase = WorkspaceConfigurationArchiveUsecase(
      localRepository: .new(database),
      localImporter: .new(database),
      cloudRepositoryFor: (_) async =>
          throw StateError('Local import must not request a cloud repository.'),
      fileService: _MemoryFileService(pickedJson: 'not an archive'),
    );

    await expectLater(
      usecase.pickArchivePreview(),
      throwsA(isA<WorkspaceConfigurationArchiveException>()),
    );
    expect(await database.workspaceDao.getWorkspaceCount(), 0);
  });
}

class _MemoryFileService({final String? pickedJson})
    extends WorkspaceConfigurationFileService {
  String? savedJson;

  @override
  Future<String?> pickArchiveJson() async => pickedJson;

  @override
  Future<bool> saveArchiveJson(String json) async {
    savedJson = json;

    return true;
  }
}
