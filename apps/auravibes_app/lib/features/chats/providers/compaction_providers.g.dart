// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CompactionExecution)
final compactionExecutionProvider = CompactionExecutionProvider._();

final class CompactionExecutionProvider
    extends
        $NotifierProvider<
          CompactionExecution,
          Map<String, CompactionExecutionState>
        > {
  CompactionExecutionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'compactionExecutionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$compactionExecutionHash();

  @$internal
  @override
  CompactionExecution create() => CompactionExecution();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, CompactionExecutionState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<String, CompactionExecutionState>>(value),
    );
  }
}

String _$compactionExecutionHash() =>
    r'c813404a6f9f43987074f3d00e9032bf8517f8f9';

abstract class _$CompactionExecution
    extends $Notifier<Map<String, CompactionExecutionState>> {
  Map<String, CompactionExecutionState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, CompactionExecutionState>,
              Map<String, CompactionExecutionState>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, CompactionExecutionState>,
                Map<String, CompactionExecutionState>
              >,
              Map<String, CompactionExecutionState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(compactionExecutionState)
final compactionExecutionStateProvider = CompactionExecutionStateFamily._();

final class CompactionExecutionStateProvider
    extends
        $FunctionalProvider<
          CompactionExecutionState?,
          CompactionExecutionState?,
          CompactionExecutionState?
        >
    with $Provider<CompactionExecutionState?> {
  CompactionExecutionStateProvider._({
    required CompactionExecutionStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'compactionExecutionStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$compactionExecutionStateHash();

  @override
  String toString() {
    return r'compactionExecutionStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CompactionExecutionState?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CompactionExecutionState? create(Ref ref) {
    final argument = this.argument as String;
    return compactionExecutionState(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompactionExecutionState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompactionExecutionState?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CompactionExecutionStateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$compactionExecutionStateHash() =>
    r'0dd419e06bf22e738ac4cd62623a12416f34d493';

final class CompactionExecutionStateFamily extends $Family
    with $FunctionalFamilyOverride<CompactionExecutionState?, String> {
  CompactionExecutionStateFamily._()
    : super(
        retry: null,
        name: r'compactionExecutionStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompactionExecutionStateProvider call(String conversationId) =>
      CompactionExecutionStateProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'compactionExecutionStateProvider';
}
