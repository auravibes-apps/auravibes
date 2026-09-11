import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

abstract final class PinnedHttpClientAdapterIo {
  static HttpClientAdapter? create(
    HttpClientAdapter current,
    List<String> addresses,
  ) {
    if (current is! IOHttpClientAdapter) return null;

    final firstAddress = addresses.firstOrNull;
    if (firstAddress == null) return null;
    final resolvedAddress = InternetAddress(firstAddress);

    return IOHttpClientAdapter(
      createHttpClient: () => _createHttpClient(current, resolvedAddress),
      validateCertificate: current.validateCertificate,
    );
  }
}

HttpClient _createHttpClient(
  HttpClientAdapter current,
  InternetAddress resolvedAddress,
) {
  final connectionFactory = _connectionFactory(resolvedAddress);
  final ioCurrent = current as IOHttpClientAdapter;
  final configuredClient = ioCurrent.createHttpClient?.call();
  final client = configuredClient ?? _defaultHttpClient();

  return client..connectionFactory = connectionFactory;
}

HttpClient _defaultHttpClient() =>
    HttpClient()..idleTimeout = const Duration(seconds: 3);

Future<ConnectionTask<Socket>> Function(Uri, String?, int?) _connectionFactory(
  InternetAddress resolvedAddress,
) =>
    (target, _, _) => Socket.startConnect(resolvedAddress, target.port);

typedef PinnedHttpClientAdapterImplementation = PinnedHttpClientAdapterIo;
