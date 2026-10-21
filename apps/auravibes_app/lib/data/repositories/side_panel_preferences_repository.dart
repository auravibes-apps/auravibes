import 'package:shared_preferences/shared_preferences.dart';

class const SidePanelPreferencesRepository(
  final SharedPreferences _preferences,
) {
  static const widthPercentKey = 'app_chat_side_panel_width_percent';
  static const isOpenKey = 'app_chat_side_panel_is_open';
  static const defaultWidthPercent = 0.4;

  double get widthPercent {
    final stored = _preferences.getDouble(widthPercentKey);
    if (stored == null || !stored.isFinite || stored <= 0 || stored > 1) {
      return defaultWidthPercent;
    }

    return stored;
  }

  bool get isOpen => _preferences.getBool(isOpenKey) ?? false;

  Future<void> saveWidthPercent(double value) async {
    final saved = await _preferences.setDouble(widthPercentKey, value);
    if (!saved) throw StateError('Could not persist side panel width.');
  }

  Future<void> saveIsOpen({required bool isOpen}) async {
    final saved = await _preferences.setBool(isOpenKey, isOpen);
    if (!saved) throw StateError('Could not persist side panel state.');
  }
}
