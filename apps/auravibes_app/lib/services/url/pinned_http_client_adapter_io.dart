// Required: Dio 5.x keeps legacy callback until Dio 6 removes it.
// ignore_for_file: deprecated_member_use

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
  final client = _createClient(current);

  return client..connectionFactory = connectionFactory;
}

HttpClient _createClient(HttpClientAdapter current) {
  final ioCurrent = current as IOHttpClientAdapter;
  final configuredClient = ioCurrent.createHttpClient?.call();
  if (configuredClient != null) return configuredClient;

  final defaultClient = _defaultHttpClient();

  return ioCurrent.onHttpClientCreate?.call(defaultClient) ?? defaultClient;
}

HttpClient _defaultHttpClient() =>
    HttpClient()..idleTimeout = const Duration(seconds: 3);

Future<ConnectionTask<Socket>> Function(Uri, String?, int?) _connectionFactory(
  InternetAddress resolvedAddress,
) =>
    (target, _, _) => _connect(resolvedAddress, target);

Future<ConnectionTask<Socket>> _connect(
  InternetAddress resolvedAddress,
  Uri target,
) async {
  final connection = await Socket.startConnect(resolvedAddress, target.port);
  if (target.scheme != 'https') return connection;

  return ConnectionTask.fromSocket(
    _secureSocket(connection.socket, target.host),
    connection.cancel,
  );
}

Future<Socket> _secureSocket(Future<Socket> socket, String host) async {
  final connected = await socket;

  return await SecureSocket.secure(connected, host: host);
}

typedef PinnedHttpClientAdapterImplementation = PinnedHttpClientAdapterIo;
