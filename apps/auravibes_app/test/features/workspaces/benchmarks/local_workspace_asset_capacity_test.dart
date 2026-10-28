import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/local_workspace_asset_repository.dart';
import 'package:auravibes_app/features/chats/services/chat_attachment_modality.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _TemporaryStore extends AttachmentFileStore {
  new(this.directory);
  final Directory directory;

  @override
  Future<void> writeAsset(String id, Uint8List bytes) async {
    final _ = await File('${directory.path}/$id')
        .writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List> readAsset(String id) =>
      File('${directory.path}/$id').readAsBytes();
}

void main() {
  test(
    'measure local synthetic asset upload and read at size boundary',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'workspace-asset-capacity-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('capacity'),
              name: 'Synthetic',
              type: .local,
            ),
          );
      final repository = LocalWorkspaceAssetRepository(
        database,
        'capacity',
        _TemporaryStore(directory),
      );
      final bytes = Uint8List(ChatAttachmentModality.maxChatAttachmentBytes)
        ..fillRange(0, ChatAttachmentModality.maxChatAttachmentBytes, 65);
      final upload = Stopwatch()..start();
      final asset = await repository.upload('synthetic.txt', bytes);
      upload.stop();
      final read = Stopwatch()..start();
      final saved = await repository.bytes(asset.id);
      read.stop();
      expect(saved, orderedEquals(bytes));
      await expectLater(
        repository.upload('too-large.txt', .new(bytes.length + 1)),
        throwsA(isA<WorkspaceAssetException>()),
      );
      stdout.writeln(
        'synthetic local asset: storage=temp-disk metadata=sqlite-memory '
        'bytes=${bytes.length} uploadUs=${upload.elapsedMicroseconds} '
        'readUs=${read.elapsedMicroseconds}',
      );
    },
    skip: Platform.environment['AURAVIBES_WORKSPACE_CAPACITY'] == '1'
        ? false
        : 'Set AURAVIBES_WORKSPACE_CAPACITY=1',
  );
}
