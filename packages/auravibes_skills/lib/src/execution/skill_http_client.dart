import 'package:async/async.dart';
import 'package:auravibes_skills/src/models/url_request.dart';
import 'package:auravibes_skills/src/models/url_response.dart';

typedef SkillHttpClient =
    CancelableOperation<AppSkillUrlResponse> Function(
      AppSkillUrlRequest request,
    );
