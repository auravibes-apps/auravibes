import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/services/chatbot/cancellable_provider_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;

import 'support/provider_fault_client.dart';

void main() {
  test('cancels an idle body even if its transport ignores native abort',
      () async {
    final body = ProviderFaultBody();
    addTearDown(body.dispose);
    final cancellation = CancellationController();
    final source = _IgnoringAbortClient(body.stream);
    final client = CancellableProviderClient(
      client: source,
      cancellation: cancellation.token,
    );
    final response = await client.send(
      http.Request('POST', Uri.parse('https://provider.invalid')),
    );
    final pending = response.stream.toList();
    final assertion = expectLater(
      pending,
      throwsA(isA<http.RequestAbortedException>()),
    );
    await body.listened;
    cancellation.cancel();
    await assertion;
    await body.cancelled;

    expect(source.request, isA<http.Abortable>());
    expect(body.cancellationCount, 1);
    client.close();
    expect(source.closeCount, 0);
  });

  test('keeps request bytes and response metadata unchanged', () async {
    final source = _IgnoringAbortClient(const Stream.empty());
    final cancellation = CancellationController();
    final client = CancellableProviderClient(
      client: source,
      cancellation: cancellation.token,
      ownsClient: true,
    );
    final request = http.Request('POST', Uri.parse('https://provider.invalid'))
      ..headers['x-fixture'] = 'preserved'
      ..followRedirects = false
      ..maxRedirects = 2
      ..persistentConnection = false
      ..bodyBytes = [0, 128, 255];
    final response = await client.send(request);

    expect(await source.request!.finalize().toBytes(), [0, 128, 255]);
    expect(source.request!.headers, request.headers);
    expect(source.request!.followRedirects, isFalse);
    expect(source.request!.maxRedirects, 2);
    expect(source.request!.persistentConnection, isFalse);
    expect(response.statusCode, 201);
    expect(response.reasonPhrase, 'Fixture');
    expect(response.headers['x-fixture'], 'response');
    expect(await response.stream.toList(), isEmpty);
    client
      ..close()
      ..close();
    expect(source.closeCount, 1);
  });

  test('pre-cancelled requests never reach the transport', () async {
    final source = _IgnoringAbortClient(const Stream.empty());
    final cancellation = CancellationController()..cancel();
    final client = CancellableProviderClient(
      client: source,
      cancellation: cancellation.token,
    );

    await expectLater(
      client.send(http.Request('POST', Uri.parse('https://provider.invalid'))),
      throwsA(isA<CancelledException>()),
    );
    expect(source.request, isNull);
    client.close();
    expect(source.closeCount, 0);
  });

  test('retains multipart headers added when the original request finalizes',
      () async {
    final source = _IgnoringAbortClient(const Stream.empty());
    final client = CancellableProviderClient(
      client: source,
      cancellation: CancellationController().token,
    );
    addTearDown(client.close);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://provider.invalid/audio/transcriptions'),
    )
      ..headers['content-type'] = 'application/json'
      ..headers['x-fixture'] = 'preserved'
      ..fields['model'] = 'whisper-1'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          [0, 128, 255],
          filename: 'audio.wav',
        ),
      );
    final response = await client.send(request);
    final captured = source.request!;
    final bytes = await captured.finalize().toBytes();
    final contentType = captured.headers['content-type'];

    expect(contentType, startsWith('multipart/form-data; boundary='));
    expect(contentType, request.headers['content-type']);
    final boundary = contentType!.split('boundary=').last;
    final body = latin1.decode(bytes);
    expect(body, startsWith('--$boundary\r\n'));
    expect(body, endsWith('--$boundary--\r\n'));
    expect(body, contains('name="model"\r\n\r\nwhisper-1'));
    expect(body, contains('name="file"; filename="audio.wav"'));
    expect(body, contains('\u0000\u0080\u00ff'));
    expect(captured.headers['x-fixture'], 'preserved');
    expect(captured.contentLength, bytes.length);
    expect(captured, isA<http.Abortable>());
    expect(await response.stream.toList(), isEmpty);
    expect(source.closeCount, 0);
  });

  test('downstream cancellation releases the source without closing its owner',
      () async {
    final body = ProviderFaultBody();
    addTearDown(body.dispose);
    final cancellation = CancellationController();
    final source = _IgnoringAbortClient(body.stream);
    final client = CancellableProviderClient(
      client: source,
      cancellation: cancellation.token,
    );
    final response = await client.send(
      http.Request('POST', Uri.parse('https://provider.invalid')),
    );
    final subscription = response.stream.listen((_) {});
    await body.listened;
    await subscription.cancel();
    await body.cancelled;
    cancellation.cancel();

    expect(body.cancellationCount, 1);
    expect(source.closeCount, 0);
    client.close();
    expect(source.closeCount, 0);
  });

  test('downstream cancellation awaits cleanup already started by the token',
      () async {
    final cleanupStarted = Completer<void>();
    final releaseCleanup = Completer<void>();
    final body = StreamController<List<int>>(
      onCancel: () {
        cleanupStarted.complete();
        return releaseCleanup.future;
      },
    );
    addTearDown(() {
      if (!releaseCleanup.isCompleted) releaseCleanup.complete();
      if (!body.isClosed) unawaited(body.close());
    });
    final cancellation = CancellationController();
    final client = CancellableProviderClient(
      client: _IgnoringAbortClient(body.stream),
      cancellation: cancellation.token,
    );
    final response = await client.send(
      http.Request('POST', Uri.parse('https://provider.invalid')),
    );
    final subscription = response.stream.listen(
      (_) {},
      onError: (Object _) {},
    );
    cancellation.cancel();
    await cleanupStarted.future;
    var finished = false;
    final cleanup = subscription.cancel().then<void>((_) {
      finished = true;
    });
    await Future<void>.value();
    expect(finished, isFalse);
    releaseCleanup.complete();
    await cleanup;

    expect(finished, isTrue);
    client.close();
  });
}

final class _IgnoringAbortClient(this.body) extends http.BaseClient {
  final Stream<List<int>> body;
  http.BaseRequest? request;
  int closeCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(
      body,
      201,
      headers: const {'x-fixture': 'response'},
      reasonPhrase: 'Fixture',
    );
  }

  @override
  void close() => closeCount++;
}
