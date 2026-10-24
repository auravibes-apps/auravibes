import 'package:auravibes_app/i18n/locale_keys.dart';

class const WorkspaceHistoryPolicy({final int? days, final int revision = 0, final bool canManage = true}) {
  static int? parse(String text) {
    if (text.trim().isEmpty) return null;
    final days = int.tryParse(text.trim());
    if (days == null) throw const WorkspaceHistoryPolicyException();
    validate(days);
    return days;
  }

  static void validate(int? days) {
    if (days != null && (days < 1 || days > 9007199254740991)) throw const WorkspaceHistoryPolicyException();
  }
}

abstract interface class WorkspaceHistoryPolicyRepository {
  Future<WorkspaceHistoryPolicy> policy();
  Future<void> configure(WorkspaceHistoryPolicy current, int? days);
}

class const WorkspaceHistoryPolicyException() implements Exception {
  String get localizationKey => LocaleKeys.workspace_items_history_policy_invalid;
}
