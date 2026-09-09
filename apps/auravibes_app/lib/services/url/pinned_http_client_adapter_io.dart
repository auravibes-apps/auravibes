// Preserve the callback for Dio 5.x compatibility until Dio 6 removes it.
// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

// ignore: unused-code, conditional export implementation used on IO platforms.
HttpClientAdapter? createPinnedHttpClientAdapter(
  HttpClientAdapter current,
  List<String> addresses,
) {
  if (current is! IOHttpClientAdapter) return null;

  final firstAddress = addresses.firstOrNull;
  if (firstAddress == null) return null;
  final resolvedAddress = InternetAddress(firstAddress);

  return IOHttpClientAdapter(
    createHttpClient: () {
      final configuredClient = current.createHttpClient?.call();
      if (configuredClient != null) {
        return configuredClient
          ..connectionFactory = (target, proxyHost, proxyPort) =>
              Socket.startConnect(resolvedAddress, target.port);
      }

      final defaultClient = HttpClient()
        ..idleTimeout = const Duration(seconds: 3);
      final client =
          current.onHttpClientCreate?.call(defaultClient) ?? defaultClient;

      return client
        ..connectionFactory = (target, proxyHost, proxyPort) =>
            Socket.startConnect(resolvedAddress, target.port);
    },
    validateCertificate: current.validateCertificate,
  );
}
