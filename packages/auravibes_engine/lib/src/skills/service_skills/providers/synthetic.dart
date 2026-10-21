import 'package:auravibes_engine/src/skills/service_skills/service_skill_preset.dart';
import 'package:auravibes_engine/src/connectors/connector_tool_definition.dart';
import 'package:auravibes_engine/src/connectors/models/connector_request_template.dart';
import 'package:auravibes_engine/src/skills/service_skills/providers/shared.dart';

final syntheticSkill = ServiceSkillPreset(
  identifier: 'synthetic',
  slug: 'synthetic',
  title: 'Synthetic',
  description: 'Search web results through Synthetic.',
  content: '''
Use Synthetic for simple web result lookup when the workspace has Synthetic
service or model-provider credentials.
''',
  compatibleModelProviderIds: ['synthetic'],
  tools: [
    ConnectorToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search web results for a query.',
      inputJsonSchema: searchInputSchema,
      requiresConnection: true,
      urlTemplate: .new(
        template: ConnectorRequestTemplate(
          url: 'https://api.synthetic.new/v2/search',
          method: .post,
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
