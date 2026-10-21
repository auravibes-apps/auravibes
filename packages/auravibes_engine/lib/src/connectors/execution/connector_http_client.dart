import 'package:async/async.dart';
import 'package:auravibes_engine/src/connectors/models/url_request.dart';
import 'package:auravibes_engine/src/connectors/models/url_response.dart';

typedef ConnectorHttpClient = CancelableOperation<UrlResponse> Function(
  UrlRequest request,
);
