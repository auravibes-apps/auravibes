import 'package:auravibes_skills/src/models/app_skill_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_tool_definition.dart';
import 'package:auravibes_skills/src/models/app_skill_url_template.dart';
import 'package:auravibes_skills/src/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_skills/src/models/skill_template_input_definition.dart';
import 'package:auravibes_skills/src/models/skill_url_template.dart';

const Map<String, Object> _inputSchema = {
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'categories': {'type': 'string'},
    'engines': {'type': 'string'},
    'language': {'type': 'string'},
    'pageno': {'type': 'integer', 'minimum': 1},
    'timeRange': {'type': 'string'},
    'safesearch': {'type': 'integer', 'minimum': 0, 'maximum': 2},
    'autocomplete': {'type': 'string'},
    'imageProxy': {'type': 'boolean'},
  },
  'required': ['query'],
  'additionalProperties': false,
};

const _credentialDefinitions = {
  'baseUrl': SkillCredentialAttributeDefinition(
    description: 'SearXNG instance base URL.',
  ),
};

const searXngSkill = AppSkillDefinition(
  identifier: 'searxng',
  slug: 'searxng',
  title: 'SearXNG',
  description: 'Search through a configured SearXNG metasearch instance.',
  content: '''
Use SearXNG when the user has a trusted metasearch instance and wants results
aggregated from that instance. The instance is selected from configured
workspace credentials.
''',
  requiresCredential: true,
  nativeTools: [
    AppSkillToolDefinition(
      slug: 'search',
      title: 'Search',
      description: 'Search a configured SearXNG instance.',
      inputJsonSchema: _inputSchema,
      requiresCredential: true,
      urlTemplate: AppSkillUrlTemplate(
        template: SkillUrlTemplate(
          url: '{{ credential.baseUrl }}/search',
          query: {
            'q': '{{ input.query }}',
            'format': 'json',
            'categories': '{{ input.categories }}',
            'engines': '{{ input.engines }}',
            'language': '{{ input.language }}',
            'pageno': '{{ input.pageno }}',
            'time_range': '{{ input.timeRange }}',
            'safesearch': '{{ input.safesearch }}',
            'autocomplete': '{{ input.autocomplete }}',
            'image_proxy': '{{ input.imageProxy }}',
          },
        ),
        inputs: {
          'query': SkillTemplateInputDefinition(description: 'Search query.'),
          'categories': SkillTemplateInputDefinition(
            description: 'Optional SearXNG categories.',
            optional: true,
          ),
          'engines': SkillTemplateInputDefinition(
            description: 'Optional SearXNG engines.',
            optional: true,
          ),
          'language': SkillTemplateInputDefinition(
            description: 'Optional result language.',
            optional: true,
          ),
          'pageno': SkillTemplateInputDefinition(
            description: 'Optional page number.',
            type: 'integer',
            optional: true,
          ),
          'timeRange': SkillTemplateInputDefinition(
            description: 'Optional time range.',
            optional: true,
          ),
          'safesearch': SkillTemplateInputDefinition(
            description: 'Optional safesearch level.',
            type: 'integer',
            optional: true,
          ),
          'autocomplete': SkillTemplateInputDefinition(
            description: 'Optional autocomplete backend.',
            optional: true,
          ),
          'imageProxy': SkillTemplateInputDefinition(
            description: 'Whether to proxy image URLs.',
            type: 'boolean',
            optional: true,
          ),
        },
        credentialDefinitions: _credentialDefinitions,
      ),
    ),
  ],
);
