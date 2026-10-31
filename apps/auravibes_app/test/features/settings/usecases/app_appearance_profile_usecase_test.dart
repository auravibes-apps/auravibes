import 'dart:convert';

import 'package:auravibes_app/features/settings/models/app_appearance_profile.dart';
import 'package:auravibes_app/features/settings/services/app_appearance_profile_file_service.dart';
import 'package:auravibes_app/features/settings/usecases/app_appearance_profile_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAppearanceProfileUsecase', () {
    test('exports a profile that can be picked and previewed', () async {
      final fileService = _MemoryProfileFileService();
      final usecase = AppAppearanceProfileUsecase(fileService: fileService);
      const profile = AppAppearanceProfile(themeMode: 'dark', accentHue: 186);

      final saved = await usecase.exportProfile(profile);
      final savedJson = fileService.savedJson;
      expect(savedJson, isNotNull);
      final encoded = jsonDecode(savedJson ?? '{}') as Map<String, dynamic>;
      fileService.pickedJson = fileService.savedJson;
      final preview = await usecase.pickProfilePreview();

      expect(saved, isTrue);
      expect(encoded.keys.toSet(), {
        'format',
        'version',
        'themeMode',
        'accentHue',
      });
      expect(preview?.themeMode, 'dark');
      expect(preview?.accentHue, 186.0);
    });

    test(
      'returns false when saving the exported profile is canceled',
      () async {
        final usecase = AppAppearanceProfileUsecase(
          fileService: _MemoryProfileFileService(saveResult: false),
        );

        final saved = await usecase.exportProfile(
          const AppAppearanceProfile(themeMode: 'system', accentHue: 300),
        );

        expect(saved, isFalse);
      },
    );

    test('returns null when profile selection is canceled', () async {
      final usecase = AppAppearanceProfileUsecase(
        fileService: _MemoryProfileFileService(),
      );

      final preview = await usecase.pickProfilePreview();

      expect(preview, isNull);
    });

    test('rejects a malformed selected profile', () async {
      final usecase = AppAppearanceProfileUsecase(
        fileService: _MemoryProfileFileService(initialPickedJson: '{bad'),
      );

      await expectLater(
        usecase.pickProfilePreview(),
        throwsA(
          isA<AppAppearanceProfileException>().having(
            (error) => error.localizationKey,
            'localizationKey',
            'settings_screen.appearance_profile.invalid_file',
          ),
        ),
      );
    });
  });
}

class _MemoryProfileFileService({
  final String? initialPickedJson,
  final bool saveResult = true,
}) extends AppAppearanceProfileFileService {
  String? pickedJson = initialPickedJson;
  String? savedJson;

  @override
  Future<String?> pickProfileJson() async => pickedJson;

  @override
  Future<bool> saveProfileJson(String json) async {
    savedJson = json;

    return saveResult;
  }
}
