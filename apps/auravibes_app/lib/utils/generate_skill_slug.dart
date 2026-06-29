String generateSkillSlug(String title) {
  return title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9 ]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
}
