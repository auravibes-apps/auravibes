import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('object schema enforces ownership and one deletion job', () {
    final root = Directory.current.path.endsWith('auravibes_server')
        ? Directory.current
        : Directory('apps/auravibes_server');
    final models = Directory('${root.path}/lib/src/features/objects/models');
    final object = File(
      '${models.path}/workspace_object.spy.yaml',
    ).readAsStringSync();
    final upload = File(
      '${models.path}/object_upload.spy.yaml',
    ).readAsStringSync();
    final deletion = File(
      '${models.path}/object_deletion.spy.yaml',
    ).readAsStringSync();
    final reference = File(
      '${models.path}/object_reference.spy.yaml',
    ).readAsStringSync();

    for (final schema in [object, upload, deletion]) {
      expect(
        schema,
        contains('workspaceId: int, relation(parent=cloud_workspace)'),
      );
    }
    expect(upload, contains('object_upload_object_idx:'));
    expect(deletion, contains('object_deletion_object_idx:'));
    expect(deletion, contains('object_deletion_request_idx:'));
    expect(deletion, contains('availableAt: DateTime'));
    expect(deletion, contains('expectedRevision: int'));
    expect(
      reference,
      contains('messageId: int, relation(parent=conversation_message'),
    );
    expect(reference, contains('object_reference_message_idx:'));
    expect(object, contains('status: String'));
  });
}
