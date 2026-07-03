import 'package:auravibes_app/features/skills/usecases/app_skill_http_client_adapter.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:auravibes_skills/auravibes_skills.dart' as package_skills;
import 'package:riverpod/riverpod.dart';

final runSkillUrlTemplateUsecaseProvider =
    Provider<package_skills.RunSkillUrlTemplate>(
      (ref) {
        final urlService = UrlService();

        return package_skills.RunSkillUrlTemplate(
          const package_skills.ResolveSkillUrlTemplate(),
          AppSkillHttpClientAdapter(urlService).execute,
        );
      },
    );
