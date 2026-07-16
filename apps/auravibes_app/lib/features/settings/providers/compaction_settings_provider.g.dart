// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compaction_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(compactionSettings)
final compactionSettingsProvider = CompactionSettingsFamily._();

final class CompactionSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CompactionSettings>,
          CompactionSettings,
          Stream<CompactionSettings>
        >
    with
        $FutureModifier<CompactionSettings>,
        $StreamProvider<CompactionSettings> {
  CompactionSettingsProvider._({
    required CompactionSettingsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'compactionSettingsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = cloudWorkspaceStateGatewayProvider;
  static final $allTransitiveDependencies1 =
      CloudWorkspaceStateGatewayProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$compactionSettingsHash();

  @override
  String toString() {
    return r'compactionSettingsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<CompactionSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CompactionSettings> create(Ref ref) {
    final argument = this.argument as String;
    return compactionSettings(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CompactionSettingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$compactionSettingsHash() =>
    r'd2bf0fb868b47481884cac22b4272eaee4c90054';

final class CompactionSettingsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<CompactionSettings>, String> {
  CompactionSettingsFamily._()
    : super(
        retry: null,
        name: r'compactionSettingsProvider',
        dependencies: <ProviderOrFamily>[cloudWorkspaceStateGatewayProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          CompactionSettingsProvider.$allTransitiveDependencies0,
          CompactionSettingsProvider.$allTransitiveDependencies1,
        ],
        isAutoDispose: true,
      );

  CompactionSettingsProvider call(String workspaceId) =>
      CompactionSettingsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'compactionSettingsProvider';
}
