import 'dart:async';

import 'package:auravibes_app/services/mcp_service/mcp_manager_client.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

void main() {
  test(
    'local tools/list follows opaque cursors without invoking tools',
    () async {
      final transport = _FakeTransport({
        null: {
          'tools': [
            {'name': 'first'},
          ],
          'nextCursor': 'opaque-1',
        },
        'opaque-1': {'tools': <Object?>[], 'nextCursor': 'opaque-2'},
        'opaque-2': {
          'tools': [
            {'name': 'last'},
          ],
        },
      });
      addTearDown(transport.close);
      var requestId = 0;

      final tools = await collectMcpToolsCatalog(
        (cursor) => McpManagerClient.requestToolsPage(
          transport: transport,
          requestId: ++requestId,
          cursor: cursor,
        ),
      );

      expect(transport.cursors, [null, 'opaque-1', 'opaque-2']);
      expect(transport.methods, everyElement('tools/list'));
      expect(
        transport.requestIds,
        everyElement(allOf(isA<int>(), greaterThanOrEqualTo(1 << 52))),
      );
      expect(tools.map((tool) => tool['name']), ['first', 'last']);
    },
  );

  test('later-page protocol failure exposes no partial catalog', () async {
    final transport = _FakeTransport({
      null: {
        'tools': [
          {'name': 'first'},
        ],
        'nextCursor': 'bad',
      },
    });
    addTearDown(transport.close);
    var requestId = 0;

    await expectLater(
      collectMcpToolsCatalog(
        (cursor) => McpManagerClient.requestToolsPage(
          transport: transport,
          requestId: ++requestId,
          cursor: cursor,
        ),
      ),
      throwsFormatException,
    );
    expect(transport.cursors, [null, 'bad']);
  });

  test('disconnect ends an outstanding tools/list request', () async {
    final transport = _FakeTransport(const {});
    final pending = McpManagerClient.requestToolsPage(
      transport: transport,
      requestId: 1,
    );
    transport.close();
    await expectLater(pending, throwsFormatException);
  });
}

final class _FakeTransport(final Map<String?, Map<String, Object?>> pages)
    implements mcp.ClientTransport {
  final cursors = <String?>[];
  final methods = <String>[];
  final requestIds = <int>[];
  final _messages = StreamController<Object?>.broadcast(sync: true);
  final _closed = Completer<void>();

  @override
  Stream<Object?> get onMessage => _messages.stream;

  @override
  Future<void> get onClose => _closed.future;

  @override
  void send(Object? message) {
    if (message is! Map) throw ArgumentError.value(message, 'message');
    final request = Map<String, dynamic>.from(message);
    requestIds.add(request['id'] as int);
    final params = request['params'] as Map<String, dynamic>;
    final cursor = params['cursor'] as String?;
    cursors.add(cursor);
    methods.add(request['method'] as String);
    final page = pages[cursor];
    if (page == null) {
      _messages.add({
        'jsonrpc': '2.0',
        'id': request['id'],
        'error': {'code': -32603, 'message': 'Later page failed.'},
      });
    } else {
      _messages.add({'jsonrpc': '2.0', 'id': request['id'], 'result': page});
    }
  }

  @override
  void close() {
    if (!_closed.isCompleted) _closed.complete();
    unawaited(_messages.close());
  }
}
