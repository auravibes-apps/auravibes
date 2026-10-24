abstract final class WorkspaceHistoryRetentionValidation {
  static void data(Map<String, Object?> data) {
    if (data.keys.any((key) => key != 'days')) throw const FormatException();
    final days = data['days'];
    if (days != null && (days is! int || days < 1 || days > 9007199254740991)) {
      throw const FormatException();
    }
  }
}
