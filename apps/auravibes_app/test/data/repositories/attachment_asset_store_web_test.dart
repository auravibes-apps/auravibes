@TestOn('browser')
library;

import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chat_attachment_bytes.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset_location.dart';
import 'package:test/test.dart';
import 'package:uuid/v7.dart';

void main() {
  test(
    'local asset bytes survive adapter reopen and remain namespaced',
    () async {
      final namespace = 'assets-test-${const UuidV7().generate()}';
      final first = AttachmentFileStore(storageNamespace: namespace);
      const id = 'asset-one';
      await first.writeAsset(id, .fromList([1, 2, 3, 255]));
      final reopened = AttachmentFileStore(storageNamespace: namespace);
      expect(await reopened.readAsset(id), [1, 2, 3, 255]);
      final location = WorkspaceAssetLocation.create(
        namespace: namespace,
        workspaceId: 'local',
        assetId: id,
      );
      expect(await ChatAttachmentBytes.read(location.location), [1, 2, 3, 255]);
      final other = AttachmentFileStore(storageNamespace: '$namespace-other');
      final _ = await expectLater(other.readAsset(id), throwsA(anything));
      final _ = await expectLater(
        reopened.writeAsset('../escape', .new(1)),
        throwsArgumentError,
      );
      await reopened.deleteAsset(id);
      await reopened.deleteAsset(id);
      final _ = await expectLater(reopened.readAsset(id), throwsA(anything));
    },
  );
}
