import 'package:auravibes_engine/src/skills/models/app_skill_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_engine/src/skills/models/app_skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';
import 'package:auravibes_engine/src/skills/models/url_request_method.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

const syntheticSkill = AppSkillDefinition(
  identifier: 'synthetic',
  slug: 'synthetic',
  title: 'Synthetic',
  description: 'Search web results through Synthetic.',
  content: '''
Use Synthetic for simple web result lookup when the workspace has Synthetic
service or model-provider credentials.
''',
  requiresCredential: true,
  compatibleModelProviderIds: ['synthetic'],
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search web results for a query.',
      inputJsonSchema: searchInputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
          url: 'https://api.synthetic.new/v2/search',
          method: UrlRequestMethod.post,
          headers: {
            'authorization': 'Bearer {{ credential.apiKey }}',
            'content-type': 'application/json',
          },
          body: '{"query":{{ input.query | json }}}',
        ),
        inputs: queryInputs,
        credentialDefinitions: apiKeyCredentialDefinitions,
      ),
    ),
  ],
);
