class AppSkillToolDefinition {
  const AppSkillToolDefinition({
    required this.slug,
    required this.title,
    required this.description,
    this.titleKey,
    this.descriptionKey,
  });

  final String slug;
  final String title;
  final String description;
  final String? titleKey;
  final String? descriptionKey;
}
