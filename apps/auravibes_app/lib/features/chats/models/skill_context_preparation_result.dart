import 'package:auravibes_app/features/chats/models/skill_context_preparation_failure.dart';

class const SkillContextPreparationResult({
  required final Map<String, String> selectedRevisions,
  required final bool canActivate,
  required final SkillContextPreparationFailure? failure,
});
