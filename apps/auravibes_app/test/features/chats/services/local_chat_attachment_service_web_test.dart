import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/chatbot/chat_attachment_bytes_web.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps Web cloud draft bytes until attachment is deleted', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final service = LocalChatAttachmentServiceWeb();
    final attachment = await service.copyBytesIntoAppStorage(
      bytes,
      fileName: 'report?.txt',
      displayName: 'report.txt',
    );

    expect(attachment.fileName, 'report_.txt');
    expect(await ChatAttachmentBytesWeb.read(attachment.localPath), bytes);

    await service.deleteAttachment(attachment.localPath);

    expect(await ChatAttachmentBytesWeb.read(attachment.localPath), isNull);
  });
}
