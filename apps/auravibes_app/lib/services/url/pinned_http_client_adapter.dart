import 'package:auravibes_app/services/url/pinned_http_client_adapter_web.dart'
    if (dart.library.io) 'package:auravibes_app/services/url/pinned_http_client_adapter_io.dart'
    as implementation;
import 'package:dio/dio.dart';

abstract final class PinnedHttpClientAdapter {
  static HttpClientAdapter? create(
    HttpClientAdapter current,
    List<String> addresses,
  ) => implementation.PinnedHttpClientAdapterImplementation.create(
    current,
    addresses,
  );
}
