import 'package:riverpod/riverpod.dart';

class GenerateSkillSlugUsecase {
  const GenerateSkillSlugUsecase();

  String call(String title) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}

final generateSkillSlugUsecaseProvider = Provider<GenerateSkillSlugUsecase>(
  (_) => const GenerateSkillSlugUsecase(),
);
