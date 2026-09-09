import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Loads bounded image bytes without allowing automatic or unsafe redirects.
class SafeImageLoader({
  final Dio? _dio,
  final Duration timeout = const Duration(seconds: 20),
}) {
  static const int maxBytes = 5 * 1024 * 1024;
  static const maxRedirects = 5;

  /// Validates every destination before fetching it and returns complete bytes.
  Future<Uint8List> load(String url) async {
    final client = _dio ?? _pinnedClient();
    final cancellation = CancelToken();
    StreamIterator<Uint8List>? activeBody;

    Future<Uint8List> fetch() async {
      var destination = url;
      for (var redirects = 0; ; redirects++) {
        final uri = await PublicUrlGuard.requireHttpsUri(destination);
        if (cancellation.cancelError case final error?) throw error;
        final response = await client.get<ResponseBody>(
          uri.toString(),
          cancelToken: cancellation,
          options: .new(
            sendTimeout: timeout,
            receiveTimeout: timeout,
            responseType: ResponseType.stream,
            validateStatus: (_) => true,
            followRedirects: false,
          ),
        );
        final body = response.data;
        if (body == null) throw const FormatException('Missing image body');
        final stream = StreamIterator(body.stream);
        activeBody = stream;
        final status = response.statusCode;
        if (const [301, 302, 303, 307, 308].contains(status)) {
          final location = response.headers.value('location');
          if (location == null ||
              location.isEmpty ||
              redirects >= maxRedirects) {
            throw const FormatException('Invalid image redirect');
          }
          // Same relative-resolution and public HTTPS guard as UrlService.
          destination = uri.resolve(location).toString();
          final _ = await stream.cancel();
          activeBody = null;
          continue;
        }
        if (status != 200) throw const FormatException('Image request failed');
        final length = int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        );
        if (length != null && length > maxBytes) {
          throw const FormatException('Image exceeds byte limit');
        }
        final bytes = BytesBuilder(copy: false);
        while (await stream.moveNext()) {
          final chunk = stream.current;
          if (chunk.length > maxBytes - bytes.length) {
            throw const FormatException('Image exceeds byte limit');
          }
          bytes.add(chunk);
        }
        if (bytes.isEmpty) throw const FormatException('Empty image body');

        return bytes.takeBytes();
      }
    }

    try {
      return await fetch().timeout(timeout);
    } finally {
      cancellation.cancel();
      final _ = await activeBody?.cancel();
      if (_dio == null) client.close(force: true);
    }
  }

  Dio _pinnedClient() => Dio()
    ..httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..findProxy = ((_) => 'DIRECT')
        ..connectionFactory = _connectPublicAddress,
    );

  Future<ConnectionTask<Socket>> _connectPublicAddress(
    Uri uri,
    String? _,
    int? _,
  ) async {
    final address = await PublicUrlGuard.requirePublicAddress(uri.host);

    return await Socket.startConnect(address, uri.port);
  }
}
