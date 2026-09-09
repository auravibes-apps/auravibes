import 'package:dio/dio.dart';

abstract final class PinnedHttpClientAdapterWeb {
  static HttpClientAdapter? create(HttpClientAdapter _, List<String> _) => null;
}

typedef PinnedHttpClientAdapterImplementation = PinnedHttpClientAdapterWeb;
