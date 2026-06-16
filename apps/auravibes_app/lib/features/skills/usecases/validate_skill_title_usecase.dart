import 'package:auravibes_app/i18n/locale_keys.dart';

void validateSkillTitle(String title) {
  final trimmedTitle = title.trim();
  if (trimmedTitle.isEmpty) {
    throw const SkillTitleValidationException(
      'Skill title is required',
      localizationKey: LocaleKeys.skills_screen_error_title_required,
    );
  }
  if (!RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(trimmedTitle)) {
    throw const SkillTitleValidationException(
      'Skill title can only contain letters, numbers, and spaces',
      localizationKey: LocaleKeys.skills_screen_error_title_invalid,
    );
  }
}

class SkillTitleValidationException implements Exception {
  const SkillTitleValidationException(this.message, {this.localizationKey});

  final String message;
  final String? localizationKey;

  @override
  String toString() => 'SkillTitleValidationException: $message';
}
