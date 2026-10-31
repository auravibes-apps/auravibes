import 'package:auravibes_app/features/settings/models/app_language_preference.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod/riverpod.dart';

final appLanguagePreferenceProvider =
    AsyncNotifierProvider<AppLanguagePreferenceNotifier, AppLanguagePreference>(
      AppLanguagePreferenceNotifier.new,
    );

class AppLanguagePreferenceNotifier
    extends AsyncNotifier<AppLanguagePreference> {
  @override
  Future<AppLanguagePreference> build() async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);

    return AppLanguagePreference.fromStoredValue(
      preferences.getString(AppLanguagePreference.preferenceKey),
    );
  }

  Future<void> save(AppLanguagePreference preference) async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await preferences.setString(
      AppLanguagePreference.preferenceKey,
      preference.name,
    );
    state = AsyncData(preference);
  }
}
