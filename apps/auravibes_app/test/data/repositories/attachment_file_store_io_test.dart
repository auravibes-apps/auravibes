import 'dart:io';

import 'package:auravibes_app/data/repositories/attachment_file_store_io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  var tempDirectory = Directory.systemTemp;
  var supportDirectory = Directory.systemTemp;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('attachment_temp_');
    supportDirectory = await Directory.systemTemp.createTemp(
      'attachment_support_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (methodCall) async {
            return switch (methodCall.method) {
              'getTemporaryDirectory' => tempDirectory.path,
              'getApplicationSupportDirectory' => supportDirectory.path,
              _ => null,
            };
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (tempDirectory.existsSync()) {
      final _ = await tempDirectory.delete(recursive: true);
    }
    if (supportDirectory.existsSync()) {
      final _ = await supportDirectory.delete(recursive: true);
    }
  });

  test('persistDraftFile copies draft file into support storage', () async {
    const store = AttachmentFileStore();
    final draftDirectory = Directory(
      p.join(tempDirectory.path, 'chat_attachments_draft'),
    );
    final _ = await draftDirectory.create(recursive: true);
    final draftFile = File(p.join(draftDirectory.path, 'image.png'));
    final _ = await draftFile.writeAsBytes([1, 2, 3]);

    final persistedPath = await store.persistDraftFile(draftFile.path);

    expect(persistedPath, isNot(draftFile.path));
    expect(persistedPath, contains('chat_attachments'));
    expect(File(persistedPath).readAsBytesSync(), [1, 2, 3]);
    expect(draftFile.existsSync(), isTrue);
  });

  test('persists namespaced drafts into namespaced support storage', () async {
    const namespace = 'auravibes_app_0123456789abcdef';
    const store = AttachmentFileStore(storageNamespace: namespace);
    final draftDirectory = Directory(
      p.join(tempDirectory.path, namespace, 'chat_attachments_draft'),
    );
    final _ = await draftDirectory.create(recursive: true);
    final draftFile = File(p.join(draftDirectory.path, 'image.png'));
    final _ = await draftFile.writeAsBytes([1, 2, 3]);

    final persistedPath = await store.persistDraftFile(draftFile.path);

    expect(
      persistedPath,
      startsWith(p.join(supportDirectory.path, namespace, 'chat_attachments')),
    );
  });

  test('does not delete legacy files from namespaced storage', () async {
    const namespace = 'auravibes_app_0123456789abcdef';
    const store = AttachmentFileStore(storageNamespace: namespace);
    final legacyDraft = File(
      p.join(tempDirectory.path, 'chat_attachments_draft', 'legacy.png'),
    );
    final _ = await legacyDraft.parent.create(recursive: true);
    final _ = await legacyDraft.writeAsBytes([1]);

    await store.deleteFile(legacyDraft.path);

    expect(legacyDraft.existsSync(), isTrue);
  });

  test('persistDraftFile ignores files outside draft storage', () async {
    const store = AttachmentFileStore();
    final outsideFile = File(p.join(tempDirectory.path, 'outside.png'));
    final _ = await outsideFile.writeAsBytes([1, 2, 3]);

    final persistedPath = await store.persistDraftFile(outsideFile.path);

    expect(persistedPath, outsideFile.path);
    expect(
      Directory(p.join(supportDirectory.path, 'chat_attachments')).existsSync(),
      isFalse,
    );
  });

  test('deleteFile removes only draft and support attachments', () async {
    const store = AttachmentFileStore();
    final draftDirectory = Directory(
      p.join(tempDirectory.path, 'chat_attachments_draft'),
    );
    final supportAttachmentDirectory = Directory(
      p.join(supportDirectory.path, 'chat_attachments'),
    );
    final _ = await draftDirectory.create(recursive: true);
    final _ = await supportAttachmentDirectory.create(recursive: true);
    final draftFile = File(p.join(draftDirectory.path, 'draft.png'));
    final supportFile = File(
      p.join(supportAttachmentDirectory.path, 'sent.png'),
    );
    final outsideFile = File(p.join(tempDirectory.path, 'outside.png'));
    final _ = await draftFile.writeAsBytes([1]);
    final _ = await supportFile.writeAsBytes([2]);
    final _ = await outsideFile.writeAsBytes([3]);

    await store.deleteFile(draftFile.path);
    await store.deleteFile(supportFile.path);
    await store.deleteFile(outsideFile.path);

    expect(draftFile.existsSync(), isFalse);
    expect(supportFile.existsSync(), isFalse);
    expect(outsideFile.existsSync(), isTrue);
  });
}
