// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_assets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(selectWorkspaceAssetAttachment)
final selectWorkspaceAssetAttachmentProvider =
    SelectWorkspaceAssetAttachmentFamily._();

final class SelectWorkspaceAssetAttachmentProvider
    extends
        $FunctionalProvider<
          AsyncValue<SelectWorkspaceAssetAttachmentUsecase>,
          SelectWorkspaceAssetAttachmentUsecase,
          FutureOr<SelectWorkspaceAssetAttachmentUsecase>
        >
    with
        $FutureModifier<SelectWorkspaceAssetAttachmentUsecase>,
        $FutureProvider<SelectWorkspaceAssetAttachmentUsecase> {
  SelectWorkspaceAssetAttachmentProvider._({
    required SelectWorkspaceAssetAttachmentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'selectWorkspaceAssetAttachmentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectWorkspaceAssetAttachmentHash();

  @override
  String toString() {
    return r'selectWorkspaceAssetAttachmentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SelectWorkspaceAssetAttachmentUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SelectWorkspaceAssetAttachmentUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return selectWorkspaceAssetAttachment(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SelectWorkspaceAssetAttachmentProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectWorkspaceAssetAttachmentHash() =>
    r'ccbf897176d124df6abd3bc86d330d9752770ba2';

final class SelectWorkspaceAssetAttachmentFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<SelectWorkspaceAssetAttachmentUsecase>,
          String
        > {
  SelectWorkspaceAssetAttachmentFamily._()
    : super(
        retry: null,
        name: r'selectWorkspaceAssetAttachmentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SelectWorkspaceAssetAttachmentProvider call(String workspaceId) =>
      SelectWorkspaceAssetAttachmentProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'selectWorkspaceAssetAttachmentProvider';
}

@ProviderFor(workspaceAssetRepository)
final workspaceAssetRepositoryProvider = WorkspaceAssetRepositoryFamily._();

final class WorkspaceAssetRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceAssetRepository>,
          WorkspaceAssetRepository,
          FutureOr<WorkspaceAssetRepository>
        >
    with
        $FutureModifier<WorkspaceAssetRepository>,
        $FutureProvider<WorkspaceAssetRepository> {
  WorkspaceAssetRepositoryProvider._({
    required WorkspaceAssetRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceAssetRepositoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceAssetRepositoryHash();

  @override
  String toString() {
    return r'workspaceAssetRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceAssetRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceAssetRepository> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceAssetRepository(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceAssetRepositoryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceAssetRepositoryHash() =>
    r'df5b9bc980ee2edcba02b2039c6d7ef4cf63a257';

final class WorkspaceAssetRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceAssetRepository>, String> {
  WorkspaceAssetRepositoryFamily._()
    : super(
        retry: null,
        name: r'workspaceAssetRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceAssetRepositoryProvider call(String workspaceId) =>
      WorkspaceAssetRepositoryProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceAssetRepositoryProvider';
}

@ProviderFor(workspaceAssetsUsecase)
final workspaceAssetsUsecaseProvider = WorkspaceAssetsUsecaseFamily._();

final class WorkspaceAssetsUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ManageWorkspaceAssetsUsecase>,
          ManageWorkspaceAssetsUsecase,
          FutureOr<ManageWorkspaceAssetsUsecase>
        >
    with
        $FutureModifier<ManageWorkspaceAssetsUsecase>,
        $FutureProvider<ManageWorkspaceAssetsUsecase> {
  WorkspaceAssetsUsecaseProvider._({
    required WorkspaceAssetsUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceAssetsUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceAssetsUsecaseHash();

  @override
  String toString() {
    return r'workspaceAssetsUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ManageWorkspaceAssetsUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ManageWorkspaceAssetsUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceAssetsUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceAssetsUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceAssetsUsecaseHash() =>
    r'ec03a85961f8621943d31d84cf8151adf443deb0';

final class WorkspaceAssetsUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ManageWorkspaceAssetsUsecase>,
          String
        > {
  WorkspaceAssetsUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceAssetsUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceAssetsUsecaseProvider call(String workspaceId) =>
      WorkspaceAssetsUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceAssetsUsecaseProvider';
}

@ProviderFor(workspaceFilesUsecase)
final workspaceFilesUsecaseProvider = WorkspaceFilesUsecaseFamily._();

final class WorkspaceFilesUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrganizeWorkspaceFilesUsecase>,
          OrganizeWorkspaceFilesUsecase,
          FutureOr<OrganizeWorkspaceFilesUsecase>
        >
    with
        $FutureModifier<OrganizeWorkspaceFilesUsecase>,
        $FutureProvider<OrganizeWorkspaceFilesUsecase> {
  WorkspaceFilesUsecaseProvider._({
    required WorkspaceFilesUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceFilesUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceFilesUsecaseHash();

  @override
  String toString() {
    return r'workspaceFilesUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OrganizeWorkspaceFilesUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OrganizeWorkspaceFilesUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceFilesUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceFilesUsecaseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceFilesUsecaseHash() =>
    r'f3e89e5958b81922d4e4b29173969d04cb89dcd0';

final class WorkspaceFilesUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<OrganizeWorkspaceFilesUsecase>,
          String
        > {
  WorkspaceFilesUsecaseFamily._()
    : super(
        retry: null,
        name: r'workspaceFilesUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceFilesUsecaseProvider call(String workspaceId) =>
      WorkspaceFilesUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceFilesUsecaseProvider';
}

@ProviderFor(createWorkspaceFileUsecase)
final createWorkspaceFileUsecaseProvider = CreateWorkspaceFileUsecaseFamily._();

final class CreateWorkspaceFileUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<CreateWorkspaceFileUsecase>,
          CreateWorkspaceFileUsecase,
          FutureOr<CreateWorkspaceFileUsecase>
        >
    with
        $FutureModifier<CreateWorkspaceFileUsecase>,
        $FutureProvider<CreateWorkspaceFileUsecase> {
  CreateWorkspaceFileUsecaseProvider._({
    required CreateWorkspaceFileUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'createWorkspaceFileUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$createWorkspaceFileUsecaseHash();

  @override
  String toString() {
    return r'createWorkspaceFileUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CreateWorkspaceFileUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CreateWorkspaceFileUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return createWorkspaceFileUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateWorkspaceFileUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$createWorkspaceFileUsecaseHash() =>
    r'069cef5fbe3bf53c86fc7f53e6653c45c3331950';

final class CreateWorkspaceFileUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CreateWorkspaceFileUsecase>,
          String
        > {
  CreateWorkspaceFileUsecaseFamily._()
    : super(
        retry: null,
        name: r'createWorkspaceFileUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CreateWorkspaceFileUsecaseProvider call(String workspaceId) =>
      CreateWorkspaceFileUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'createWorkspaceFileUsecaseProvider';
}

@ProviderFor(workspaceFiles)
final workspaceFilesProvider = WorkspaceFilesFamily._();

final class WorkspaceFilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceFile>>,
          List<WorkspaceFile>,
          FutureOr<List<WorkspaceFile>>
        >
    with
        $FutureModifier<List<WorkspaceFile>>,
        $FutureProvider<List<WorkspaceFile>> {
  WorkspaceFilesProvider._({
    required WorkspaceFilesFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceFilesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceFilesHash();

  @override
  String toString() {
    return r'workspaceFilesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<WorkspaceFile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WorkspaceFile>> create(Ref ref) {
    final argument = this.argument as (String, String?);
    return workspaceFiles(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceFilesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceFilesHash() => r'e0500a9983b95f0cf63acf524287ff19db9f5453';

final class WorkspaceFilesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<WorkspaceFile>>,
          (String, String?)
        > {
  WorkspaceFilesFamily._()
    : super(
        retry: null,
        name: r'workspaceFilesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceFilesProvider call(String workspaceId, String? parentId) =>
      WorkspaceFilesProvider._(argument: (workspaceId, parentId), from: this);

  @override
  String toString() => r'workspaceFilesProvider';
}

@ProviderFor(workspaceFile)
final workspaceFileProvider = WorkspaceFileFamily._();

final class WorkspaceFileProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceFile>,
          WorkspaceFile,
          FutureOr<WorkspaceFile>
        >
    with $FutureModifier<WorkspaceFile>, $FutureProvider<WorkspaceFile> {
  WorkspaceFileProvider._({
    required WorkspaceFileFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceFileHash();

  @override
  String toString() {
    return r'workspaceFileProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceFile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceFile> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceFile(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceFileHash() => r'debfbbcb61d0d8ee5afcc90a16071465bf7b15f1';

final class WorkspaceFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceFile>, (String, String)> {
  WorkspaceFileFamily._()
    : super(
        retry: null,
        name: r'workspaceFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceFileProvider call(String workspaceId, String id) =>
      WorkspaceFileProvider._(argument: (workspaceId, id), from: this);

  @override
  String toString() => r'workspaceFileProvider';
}

@ProviderFor(workspaceAssetPreview)
final workspaceAssetPreviewProvider = WorkspaceAssetPreviewFamily._();

final class WorkspaceAssetPreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceAssetPreview>,
          WorkspaceAssetPreview,
          FutureOr<WorkspaceAssetPreview>
        >
    with
        $FutureModifier<WorkspaceAssetPreview>,
        $FutureProvider<WorkspaceAssetPreview> {
  WorkspaceAssetPreviewProvider._({
    required WorkspaceAssetPreviewFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceAssetPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceAssetPreviewHash();

  @override
  String toString() {
    return r'workspaceAssetPreviewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceAssetPreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceAssetPreview> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceAssetPreview(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceAssetPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceAssetPreviewHash() =>
    r'852cf357e562fdef8c209246045b2eee67dc0506';

final class WorkspaceAssetPreviewFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceAssetPreview>,
          (String, String)
        > {
  WorkspaceAssetPreviewFamily._()
    : super(
        retry: null,
        name: r'workspaceAssetPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceAssetPreviewProvider call(String workspaceId, String assetId) =>
      WorkspaceAssetPreviewProvider._(
        argument: (workspaceId, assetId),
        from: this,
      );

  @override
  String toString() => r'workspaceAssetPreviewProvider';
}

@ProviderFor(workspaceAssetFileService)
final workspaceAssetFileServiceProvider = WorkspaceAssetFileServiceProvider._();

final class WorkspaceAssetFileServiceProvider
    extends
        $FunctionalProvider<
          WorkspaceAssetFileService,
          WorkspaceAssetFileService,
          WorkspaceAssetFileService
        >
    with $Provider<WorkspaceAssetFileService> {
  WorkspaceAssetFileServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceAssetFileServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceAssetFileServiceHash();

  @$internal
  @override
  $ProviderElement<WorkspaceAssetFileService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceAssetFileService create(Ref ref) {
    return workspaceAssetFileService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceAssetFileService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceAssetFileService>(value),
    );
  }
}

String _$workspaceAssetFileServiceHash() =>
    r'a405e447b970c921fd8d109999f32e9dd880f57e';

@ProviderFor(chooseWorkspaceAssetUsecase)
final chooseWorkspaceAssetUsecaseProvider =
    ChooseWorkspaceAssetUsecaseProvider._();

final class ChooseWorkspaceAssetUsecaseProvider
    extends
        $FunctionalProvider<
          ChooseWorkspaceAssetUsecase,
          ChooseWorkspaceAssetUsecase,
          ChooseWorkspaceAssetUsecase
        >
    with $Provider<ChooseWorkspaceAssetUsecase> {
  ChooseWorkspaceAssetUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chooseWorkspaceAssetUsecaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chooseWorkspaceAssetUsecaseHash();

  @$internal
  @override
  $ProviderElement<ChooseWorkspaceAssetUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChooseWorkspaceAssetUsecase create(Ref ref) {
    return chooseWorkspaceAssetUsecase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChooseWorkspaceAssetUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChooseWorkspaceAssetUsecase>(value),
    );
  }
}

String _$chooseWorkspaceAssetUsecaseHash() =>
    r'2189af9684b756f90a19dc0503b614d14d376ad1';

@ProviderFor(saveWorkspaceAssetUsecase)
final saveWorkspaceAssetUsecaseProvider = SaveWorkspaceAssetUsecaseFamily._();

final class SaveWorkspaceAssetUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<SaveWorkspaceAssetUsecase>,
          SaveWorkspaceAssetUsecase,
          FutureOr<SaveWorkspaceAssetUsecase>
        >
    with
        $FutureModifier<SaveWorkspaceAssetUsecase>,
        $FutureProvider<SaveWorkspaceAssetUsecase> {
  SaveWorkspaceAssetUsecaseProvider._({
    required SaveWorkspaceAssetUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'saveWorkspaceAssetUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saveWorkspaceAssetUsecaseHash();

  @override
  String toString() {
    return r'saveWorkspaceAssetUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SaveWorkspaceAssetUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SaveWorkspaceAssetUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return saveWorkspaceAssetUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SaveWorkspaceAssetUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saveWorkspaceAssetUsecaseHash() =>
    r'f582d4e0847b6ce77c10a54a0b3fe3a99f538244';

final class SaveWorkspaceAssetUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<SaveWorkspaceAssetUsecase>, String> {
  SaveWorkspaceAssetUsecaseFamily._()
    : super(
        retry: null,
        name: r'saveWorkspaceAssetUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SaveWorkspaceAssetUsecaseProvider call(String workspaceId) =>
      SaveWorkspaceAssetUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'saveWorkspaceAssetUsecaseProvider';
}

@ProviderFor(workspaceAssetDescriptor)
final workspaceAssetDescriptorProvider = WorkspaceAssetDescriptorFamily._();

final class WorkspaceAssetDescriptorProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceAsset>,
          WorkspaceAsset,
          FutureOr<WorkspaceAsset>
        >
    with $FutureModifier<WorkspaceAsset>, $FutureProvider<WorkspaceAsset> {
  WorkspaceAssetDescriptorProvider._({
    required WorkspaceAssetDescriptorFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceAssetDescriptorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceAssetDescriptorHash();

  @override
  String toString() {
    return r'workspaceAssetDescriptorProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceAsset> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceAsset> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceAssetDescriptor(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceAssetDescriptorProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceAssetDescriptorHash() =>
    r'898f5116291ed911754c4f87a0ec11b36fdc1bd1';

final class WorkspaceAssetDescriptorFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceAsset>, (String, String)> {
  WorkspaceAssetDescriptorFamily._()
    : super(
        retry: null,
        name: r'workspaceAssetDescriptorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceAssetDescriptorProvider call(String workspaceId, String assetId) =>
      WorkspaceAssetDescriptorProvider._(
        argument: (workspaceId, assetId),
        from: this,
      );

  @override
  String toString() => r'workspaceAssetDescriptorProvider';
}
