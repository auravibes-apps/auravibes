import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:http/http.dart' as http;

Future<ProviderTransportResponse> sendProviderRequest(
  http.BaseRequest request, {
  required Duration requestTimeout,
  http.Client? httpClient,
}) async {
  final client = httpClient ?? http.Client();
  try {
    final response = await client.send(request).timeout(requestTimeout);

    return ProviderTransportResponse(
      statusCode: response.statusCode,
      body: httpClient == null
          ? _closeAfter(response.stream, client)
          : response.stream,
    );
  } on Object {
    if (httpClient == null) client.close();
    rethrow;
  }
}

Stream<List<int>> _closeAfter(
  Stream<List<int>> stream,
  http.Client client,
) async* {
  try {
    yield* stream;
  } finally {
    client.close();
  }
}
