import 'dart:typed_data';

import 'package:auravibes_app/features/chats/services/cloud_chat_attachment_adapter.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  for (final size in [2, 3, 4]) {
    test(
      'private asset stream accepts only its exact declared size: $size',
      () async {
        final transport = _Transport();
        final dio = Dio()..httpClientAdapter = transport;
        addTearDown(dio.close);
        final adapter = CloudChatAttachmentAdapter(
          gateway: _Gateway(),
          dio: dio,
        );
        final result = adapter.downloadAssetBytes(
          .https('example.invalid', '/private'),
          size,
        );
        if (size == 3) {
          expect(await result, [1, 2, 3]);
        } else {
          await expectLater(result, throwsStateError);
        }
        expect(transport.options?.followRedirects, isFalse);
        expect(transport.requests, 1);
      },
    );
  }

  test(
    'private downloads reject HTTP and invalid sizes before network access',
    () async {
      final transport = _Transport();
      final dio = Dio()..httpClientAdapter = transport;
      addTearDown(dio.close);
      final adapter = CloudChatAttachmentAdapter(gateway: _Gateway(), dio: dio);
      for (final (:uri, :size) in [
        (uri: Uri.http('example.invalid', '/private'), size: 3),
        (uri: Uri.https('example.invalid', '/private'), size: 0),
      ]) {
        await expectLater(
          adapter.downloadAssetBytes(uri, size),
          throwsStateError,
        );
      }
      expect(transport.requests, 0);
    },
  );
}

class _Gateway extends Mock implements CloudChatGateway;

class _Transport implements HttpClientAdapter {
  RequestOptions? options;
  int requests = 0;
  bool closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    requests++;

    return .new(
      .fromIterable([
        .fromList([1, 2]),
        .fromList([3]),
      ]),
      200,
    );
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }
}
