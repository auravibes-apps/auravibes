// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_switcher_entries_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(quickSwitcherEntries)
final quickSwitcherEntriesProvider = QuickSwitcherEntriesFamily._();

final class QuickSwitcherEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuickSwitcherEntries>,
          QuickSwitcherEntries,
          FutureOr<QuickSwitcherEntries>
        >
    with
        $FutureModifier<QuickSwitcherEntries>,
        $FutureProvider<QuickSwitcherEntries> {
  QuickSwitcherEntriesProvider._({
    required QuickSwitcherEntriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'quickSwitcherEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quickSwitcherEntriesHash();

  @override
  String toString() {
    return r'quickSwitcherEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<QuickSwitcherEntries> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<QuickSwitcherEntries> create(Ref ref) {
    final argument = this.argument as String;
    return quickSwitcherEntries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is QuickSwitcherEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quickSwitcherEntriesHash() =>
    r'e1ad7a46a6b8542370f6245319f5cc957acbcac2';

final class QuickSwitcherEntriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<QuickSwitcherEntries>, String> {
  QuickSwitcherEntriesFamily._()
    : super(
        retry: null,
        name: r'quickSwitcherEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  QuickSwitcherEntriesProvider call(String currentWorkspaceId) =>
      QuickSwitcherEntriesProvider._(argument: currentWorkspaceId, from: this);

  @override
  String toString() => r'quickSwitcherEntriesProvider';
}
