import 'package:async/async.dart';
import 'package:auravibes_skills/src/execution/skill_http_client.dart';

export 'package:auravibes_skills/src/execution/skill_http_client.dart';

typedef AppSkillToolCallback =
    CancelableOperation<Object?> Function(
      Map<String, dynamic> input,
      SkillHttpClient request,
    );
