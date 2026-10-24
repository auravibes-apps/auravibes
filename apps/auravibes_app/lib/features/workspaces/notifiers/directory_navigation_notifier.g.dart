// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_navigation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps in-memory navigation when the responsive shell remounts its content.

@ProviderFor(DirectoryNavigationNotifier)
final directoryNavigationProvider = DirectoryNavigationNotifierFamily._();

/// Keeps in-memory navigation when the responsive shell remounts its content.
final class DirectoryNavigationNotifierProvider
    extends
        $NotifierProvider<DirectoryNavigationNotifier, DirectoryNavigation> {
  /// Keeps in-memory navigation when the responsive shell remounts its content.
  DirectoryNavigationNotifierProvider._({
    required DirectoryNavigationNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'directoryNavigationProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$directoryNavigationNotifierHash();

  @override
  String toString() {
    return r'directoryNavigationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DirectoryNavigationNotifier create() => DirectoryNavigationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DirectoryNavigation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DirectoryNavigation>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DirectoryNavigationNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$directoryNavigationNotifierHash() =>
    r'a86c7850825c05f78fcfa45a9e8fb08788a4aa4c';

/// Keeps in-memory navigation when the responsive shell remounts its content.

final class DirectoryNavigationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DirectoryNavigationNotifier,
          DirectoryNavigation,
          DirectoryNavigation,
          DirectoryNavigation,
          String
        > {
  DirectoryNavigationNotifierFamily._()
    : super(
        retry: null,
        name: r'directoryNavigationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Keeps in-memory navigation when the responsive shell remounts its content.

  DirectoryNavigationNotifierProvider call(String workspaceId) =>
      DirectoryNavigationNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'directoryNavigationProvider';
}

/// Keeps in-memory navigation when the responsive shell remounts its content.

abstract class _$DirectoryNavigationNotifier
    extends $Notifier<DirectoryNavigation> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  DirectoryNavigation build(String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DirectoryNavigation, DirectoryNavigation>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DirectoryNavigation, DirectoryNavigation>,
              DirectoryNavigation,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
