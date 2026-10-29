import 'dart:async';
import 'dart:io';

import 'package:auravibes_server/src/features/conversations/engine/workspace_conversation_file.dart';
import 'package:auravibes_server/src/features/objects/object_store.dart';
import 'package:test/test.dart';

void main() {
  test(
    'enforces an absolute deadline on a continuously streaming body',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      Timer? drip;
      server.listen((request) {
        request.response.headers.contentType = ContentType.text;
        drip = Timer.periodic(const Duration(milliseconds: 10), (_) {
          request.response.add([65]);
          unawaited(request.response.flush().catchError((Object _) {}));
        });
      });
      final signed = SignedObjectRequest(
        url: Uri.parse('http://127.0.0.1:${server.port}/private?secret=token'),
        headers: const {},
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
      );
      try {
        await expectLater(
          fetchWorkspaceFile(
            signed,
            65536,
            deadline: const Duration(milliseconds: 150),
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'File storage is unavailable.',
            ),
          ),
        );
      } finally {
        drip?.cancel();
        await server.close(force: true);
      }
    },
  );
}
