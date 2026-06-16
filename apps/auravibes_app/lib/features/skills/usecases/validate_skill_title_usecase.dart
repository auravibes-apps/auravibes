void validateSkillTitle(String title) {
  final trimmedTitle = title.trim();
  if (trimmedTitle.isEmpty) {
    throw const SkillTitleValidationException('Skill title is required');
  }
  if (!RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(trimmedTitle)) {
    throw const SkillTitleValidationException(
      'Skill title can only contain letters, numbers, and spaces',
    );
  }
}

class SkillTitleValidationException implements Exception {
  const SkillTitleValidationException(this.message);

  final String message;

  @override
  String toString() => 'SkillTitleValidationException: $message';
}
