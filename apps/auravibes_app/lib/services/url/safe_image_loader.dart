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
  Future<Uint8List> load(String url) => _loadImage(this, url);
}

Future<Uint8List> _loadImage(SafeImageLoader loader, String url) async {
  final client = loader._dio ?? _pinnedClient();
  final cancellation = CancelToken();
  StreamIterator<Uint8List>? activeBody;

  try {
    return await _fetchImage((
      client: client,
      url: url,
      cancellation: cancellation,
      timeout: loader.timeout,
      onActiveBodyChanged: (value) => activeBody = value,
    )).timeout(loader.timeout);
  } finally {
    await _cleanupImage((
      client: client,
      cancellation: cancellation,
      activeBody: activeBody,
      closeClient: loader._dio == null,
    ));
  }
}

typedef _ImageFetchRequest = ({
  Dio client,
  String url,
  CancelToken cancellation,
  Duration timeout,
  void Function(StreamIterator<Uint8List>?) onActiveBodyChanged,
});

typedef _ImageRequest = ({
  Dio client,
  String destination,
  CancelToken cancellation,
  Duration timeout,
});

typedef _ImageCleanupRequest = ({
  Dio client,
  CancelToken cancellation,
  StreamIterator<Uint8List>? activeBody,
  bool closeClient,
});

typedef _RedirectRequest = ({
  Uri uri,
  Response<ResponseBody> response,
  int redirects,
  StreamIterator<Uint8List> stream,
  void Function(StreamIterator<Uint8List>?) onActiveBodyChanged,
});

Future<Uint8List> _fetchImage(_ImageFetchRequest request) async {
  var destination = request.url;
  for (var redirects = 0; ; redirects++) {
    final fetched = await _fetchResponse((
      client: request.client,
      destination: destination,
      cancellation: request.cancellation,
      timeout: request.timeout,
    ));
    request.onActiveBodyChanged(fetched.stream);
    if (!_isRedirect(fetched.response.statusCode)) {
      _ensureSuccess(fetched.response.statusCode);

      return _readBody(fetched.response, fetched.stream);
    }
    destination = await _followRedirect((
      uri: fetched.uri,
      response: fetched.response,
      redirects: redirects,
      stream: fetched.stream,
      onActiveBodyChanged: request.onActiveBodyChanged,
    ));
  }
}

Future<
  ({Uri uri, Response<ResponseBody> response, StreamIterator<Uint8List> stream})
>
_fetchResponse(_ImageRequest request) async {
  final uri = await PublicUrlGuard.requireHttpsUri(request.destination);
  if (request.cancellation.cancelError case final error?) throw error;
  final response = await _requestImage(request, uri);

  return (uri: uri, response: response, stream: _bodyStream(response));
}

Future<Response<ResponseBody>> _requestImage(_ImageRequest request, Uri uri) =>
    request.client.get<ResponseBody>(
      uri.toString(),
      cancelToken: request.cancellation,
      options: .new(
        sendTimeout: request.timeout,
        receiveTimeout: request.timeout,
        responseType: ResponseType.stream,
        validateStatus: (_) => true,
        followRedirects: false,
      ),
    );

StreamIterator<Uint8List> _bodyStream(Response<ResponseBody> response) {
  final body = response.data;
  if (body == null) throw const FormatException('Missing image body');

  return StreamIterator(body.stream);
}

bool _isRedirect(int? status) =>
    const [301, 302, 303, 307, 308].contains(status);

void _ensureSuccess(int? status) {
  if (status != 200) throw const FormatException('Image request failed');
}

Future<String> _followRedirect(_RedirectRequest request) async {
  final location = request.response.headers.value('location');
  if (location == null ||
      location.isEmpty ||
      request.redirects >= SafeImageLoader.maxRedirects) {
    throw const FormatException('Invalid image redirect');
  }
  // Same relative-resolution and public HTTPS guard as UrlService.
  final destination = request.uri.resolve(location).toString();
  final _ = await request.stream.cancel();
  request.onActiveBodyChanged(null);

  return destination;
}

Future<Uint8List> _readBody(
  Response<ResponseBody> response,
  StreamIterator<Uint8List> stream,
) async {
  final length = int.tryParse(
    response.headers.value(Headers.contentLengthHeader) ?? '',
  );
  if (length != null && length > SafeImageLoader.maxBytes) {
    throw const FormatException('Image exceeds byte limit');
  }
  final bytes = await _readChunks(stream);
  if (bytes.isEmpty) throw const FormatException('Empty image body');

  return bytes.takeBytes();
}

Future<BytesBuilder> _readChunks(StreamIterator<Uint8List> stream) async {
  final bytes = BytesBuilder(copy: false);
  while (await stream.moveNext()) {
    final chunk = stream.current;
    if (chunk.length > SafeImageLoader.maxBytes - bytes.length) {
      throw const FormatException('Image exceeds byte limit');
    }
    bytes.add(chunk);
  }
  return bytes;
}

Future<void> _cleanupImage(_ImageCleanupRequest request) async {
  request.cancellation.cancel();
  final _ = await request.activeBody?.cancel();
  if (request.closeClient) request.client.close(force: true);
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
