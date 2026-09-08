import 'package:async/async.dart';
import 'package:auravibes_engine/src/skills/models/url_request.dart';
import 'package:auravibes_engine/src/skills/models/url_response.dart';

typedef SkillHttpClient = CancelableOperation<UrlResponse> Function(
  UrlRequest request,
);
