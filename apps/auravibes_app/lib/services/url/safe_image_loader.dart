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

    try {
      return await _fetch(
        client: client,
        url: url,
        cancellation: cancellation,
        onActiveBodyChanged: (value) => activeBody = value,
      ).timeout(timeout);
    } finally {
      cancellation.cancel();
      final _ = await activeBody?.cancel();
      if (_dio == null) client.close(force: true);
    }
  }

  Future<Uint8List> _fetch({
    required Dio client,
    required String url,
    required CancelToken cancellation,
    required void Function(StreamIterator<Uint8List>?) onActiveBodyChanged,
  }) async {
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
      final stream = _bodyStream(response);
      onActiveBodyChanged(stream);
      final status = response.statusCode;
      if (_isRedirect(status)) {
        destination = await _followRedirect(
          uri: uri,
          response: response,
          redirects: redirects,
          stream: stream,
          onActiveBodyChanged: onActiveBodyChanged,
        );
        continue;
      }
      if (status != 200) throw const FormatException('Image request failed');

      return await _readBody(response, stream);
    }
  }

  StreamIterator<Uint8List> _bodyStream(Response<ResponseBody> response) {
    final body = response.data;
    if (body == null) throw const FormatException('Missing image body');

    return StreamIterator(body.stream);
  }

  bool _isRedirect(int? status) =>
      const [301, 302, 303, 307, 308].contains(status);

  Future<String> _followRedirect({
    required Uri uri,
    required Response<ResponseBody> response,
    required int redirects,
    required StreamIterator<Uint8List> stream,
    required void Function(StreamIterator<Uint8List>?) onActiveBodyChanged,
  }) async {
    final location = response.headers.value('location');
    if (location == null || location.isEmpty || redirects >= maxRedirects) {
      throw const FormatException('Invalid image redirect');
    }
    // Same relative-resolution and public HTTPS guard as UrlService.
    final destination = uri.resolve(location).toString();
    final _ = await stream.cancel();
    onActiveBodyChanged(null);

    return destination;
  }

  Future<Uint8List> _readBody(
    Response<ResponseBody> response,
    StreamIterator<Uint8List> stream,
  ) async {
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
