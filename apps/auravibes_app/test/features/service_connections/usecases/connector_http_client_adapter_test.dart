import 'package:async/async.dart';
import 'package:auravibes_app/features/service_connections/usecases/connector_http_client_adapter.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('passes validated addresses and credentials to UrlService', () async {
    final urlService = _RecordingUrlService();
    String? validatedUrl;
    final adapter = ConnectorHttpClientAdapter(
      urlService,
      requirePublicUri: (url) async {
        validatedUrl = url;

        return (uri: Uri.parse(url), addresses: ['93.184.216.34']);
      },
    );
    const request = UrlRequest(
      url: 'https://service.example/api',
      method: .post,
      headers: {
        'Authorization': 'Bearer connector-secret',
        'X-Api-Key': 'connector-api-key',
      },
      body: '{"query":"status"}',
    );

    final response = await adapter.execute(request).value;

    expect(response.statusCode, 200);
    expect(validatedUrl, request.url);
    expect(urlService.request?.url, request.url);
    expect(urlService.request?.headers, request.headers);
    expect(urlService.request?.body, request.body);
    expect(urlService.resolvedAddresses, ['93.184.216.34']);
  });
}

class _RecordingUrlService extends UrlService {
  UrlRequest? request;
  List<String>? resolvedAddresses;

  @override
  CancelableOperation<UrlResponse> execute(
    UrlRequest request, {
    List<String>? resolvedAddresses,
  }) {
    this
      ..request = request
      ..resolvedAddresses = resolvedAddresses;

    return CancelableOperation.fromFuture(
      .value(
        const UrlResponse(
          statusCode: 200,
          body: 'ok',
          headers: {},
          elapsed: .zero,
        ),
      ),
    );
  }
}
