const Map<String, dynamic> defaultAppSkillToolInputJsonSchema = {
  'type': 'object',
  'properties': <String, Object?>{},
  'required': <String>[],
  'additionalProperties': false,
};

class const AppSkillToolDefinition({
  required final String slug,
  required final String title,
  required final String description,
  final Map<String, dynamic> inputJsonSchema =
      defaultAppSkillToolInputJsonSchema,
  final String? titleKey,
  final String? descriptionKey,
});
