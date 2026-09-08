import 'dart:async';
import 'dart:typed_data';

import 'package:auravibes_app/services/url/safe_image_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final target in [
    'https://127.0.0.1/private',
    'https://10.0.0.1/private',
    'https://[::1]/private',
    'https://localhost/private',
    'http://8.8.8.8/insecure',
    'https://user:password@8.8.8.8/private',
  ]) {
    test('rejects unsafe redirect $target before transport', () async {
      var calls = 0;
      final dio = Dio()
        ..httpClientAdapter = _Transport((options) async {
          calls++;
          expect(options.followRedirects, isFalse);

          return ResponseBody.fromString(
            '',
            302,
            headers: {
              'location': [target],
            },
          );
        });
      await expectLater(
        SafeImageLoader(dio: dio).load('https://8.8.8.8/image'),
        throwsFormatException,
      );
      expect(calls, 1);
    });
  }

  test('resolves relative redirects and returns complete bytes', () async {
    final paths = <String>[];
    final dio = Dio()
      ..httpClientAdapter = _Transport((options) async {
        paths.add(options.uri.path);
        expect(options.followRedirects, isFalse);

        return paths.length == 1
            ? ResponseBody.fromString(
                '',
                307,
                headers: {
                  'location': ['/final'],
                },
              )
            : ResponseBody.fromBytes([1, 2, 3], 200);
      });
    expect(await SafeImageLoader(dio: dio).load('https://8.8.8.8/image'), [
      1,
      2,
      3,
    ]);
    expect(paths, ['/image', '/final']);
  });

  test('stops redirect loops at fixed limit', () async {
    var calls = 0;
    final dio = Dio()
      ..httpClientAdapter = _Transport((_) async {
        calls++;

        return ResponseBody.fromString(
          '',
          302,
          headers: {
            'location': ['/loop'],
          },
        );
      });
    await expectLater(
      SafeImageLoader(dio: dio).load('https://8.8.8.8/image'),
      throwsFormatException,
    );
    expect(calls, SafeImageLoader.maxRedirects + 1);
  });

  for (final declared in [true, false]) {
    test(
      'rejects oversized ${declared ? 'declared' : 'streamed'} body',
      () async {
        var cancelled = false;
        final body = StreamController<Uint8List>(
          onCancel: () => cancelled = true,
        );
        final dio = Dio()
          ..httpClientAdapter = _Transport((_) async {
            body
              ..add(Uint8List(SafeImageLoader.maxBytes))
              ..add(Uint8List(1));

            return ResponseBody(
              body.stream,
              200,
              headers: {
                if (declared)
                  Headers.contentLengthHeader: [
                    '${SafeImageLoader.maxBytes + 1}',
                  ],
              },
            );
          });
        await expectLater(
          SafeImageLoader(dio: dio).load('https://8.8.8.8/image'),
          throwsFormatException,
        );
        expect(cancelled, isTrue);
        final _ = await body.close();
      },
    );
  }

  for (final stalledBody in [false, true]) {
    test(
      'deadline cancels stalled ${stalledBody ? 'body' : 'request'}',
      () async {
        CancelToken? token;
        var bodyCancelled = false;
        final body = StreamController<Uint8List>(
          onCancel: () => bodyCancelled = true,
        );
        final dio = Dio()
          ..httpClientAdapter = _Transport((options) async {
            token = options.cancelToken;

            return stalledBody
                ? ResponseBody(body.stream, 200)
                : await Completer<ResponseBody>().future;
          });
        await expectLater(
          SafeImageLoader(
            dio: dio,
            timeout: const Duration(milliseconds: 30),
          ).load('https://8.8.8.8/image'),
          throwsA(isA<TimeoutException>()),
        );
        expect(token?.isCancelled, isTrue);
        if (stalledBody) expect(bodyCancelled, isTrue);
        if (stalledBody) {
          final _ = await body.close();
        }
      },
    );
  }
}

class _Transport(final Future<ResponseBody> Function(RequestOptions) respond)
    implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);

  @override
  void close({bool force = false}) {
    final _ = force;
  }
}
