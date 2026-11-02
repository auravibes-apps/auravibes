import 'package:auravibes_app/features/settings/models/app_appearance_profile.dart';
import 'package:auravibes_app/features/settings/services/app_appearance_profile_file_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_appearance_profile_usecase.g.dart';

class const AppAppearanceProfileUsecase({
  required final AppAppearanceProfileFileService _fileService,
}) {
  Future<bool> exportProfile(AppAppearanceProfile profile) =>
      _fileService.saveProfileJson(AppAppearanceProfileCodec.encode(profile));

  Future<AppAppearanceProfile?> pickProfilePreview() async {
    final json = await _fileService.pickProfileJson();
    if (json == null) return null;

    return AppAppearanceProfileCodec.decode(json);
  }
}

@riverpod
AppAppearanceProfileUsecase appAppearanceProfileUsecase(Ref _) =>
    const AppAppearanceProfileUsecase(fileService: .new());
