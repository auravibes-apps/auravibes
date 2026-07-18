// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_workspace_compaction_settings_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(saveWorkspaceCompactionSettingsUsecase)
final saveWorkspaceCompactionSettingsUsecaseProvider =
    SaveWorkspaceCompactionSettingsUsecaseFamily._();

final class SaveWorkspaceCompactionSettingsUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<SaveWorkspaceCompactionSettingsUsecase>,
          SaveWorkspaceCompactionSettingsUsecase,
          FutureOr<SaveWorkspaceCompactionSettingsUsecase>
        >
    with
        $FutureModifier<SaveWorkspaceCompactionSettingsUsecase>,
        $FutureProvider<SaveWorkspaceCompactionSettingsUsecase> {
  SaveWorkspaceCompactionSettingsUsecaseProvider._({
    required SaveWorkspaceCompactionSettingsUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'saveWorkspaceCompactionSettingsUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$saveWorkspaceCompactionSettingsUsecaseHash();

  @override
  String toString() {
    return r'saveWorkspaceCompactionSettingsUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SaveWorkspaceCompactionSettingsUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SaveWorkspaceCompactionSettingsUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return saveWorkspaceCompactionSettingsUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SaveWorkspaceCompactionSettingsUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saveWorkspaceCompactionSettingsUsecaseHash() =>
    r'a2990577dc7338cef060b593192559ee95753f0e';

final class SaveWorkspaceCompactionSettingsUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SaveWorkspaceCompactionSettingsUsecase>,
          String
        > {
  SaveWorkspaceCompactionSettingsUsecaseFamily._()
    : super(
        retry: null,
        name: r'saveWorkspaceCompactionSettingsUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SaveWorkspaceCompactionSettingsUsecaseProvider call(String workspaceId) =>
      SaveWorkspaceCompactionSettingsUsecaseProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'saveWorkspaceCompactionSettingsUsecaseProvider';
}
