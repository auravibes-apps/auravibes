// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_session_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BrowserSessionNotifier)
final browserSessionProvider = BrowserSessionNotifierFamily._();

final class BrowserSessionNotifierProvider
    extends
        $AsyncNotifierProvider<BrowserSessionNotifier, BrowserSessionState> {
  BrowserSessionNotifierProvider._({
    required BrowserSessionNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'browserSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$browserSessionNotifierHash();

  @override
  String toString() {
    return r'browserSessionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  BrowserSessionNotifier create() => BrowserSessionNotifier();

  @override
  bool operator ==(Object other) {
    return other is BrowserSessionNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$browserSessionNotifierHash() =>
    r'd8502e7e4095ae7fc00032cae11ac1737e4815dd';

final class BrowserSessionNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BrowserSessionNotifier,
          AsyncValue<BrowserSessionState>,
          BrowserSessionState,
          FutureOr<BrowserSessionState>,
          (String, String)
        > {
  BrowserSessionNotifierFamily._()
    : super(
        retry: null,
        name: r'browserSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BrowserSessionNotifierProvider call(
    String workspaceId,
    String conversationId,
  ) => BrowserSessionNotifierProvider._(
    argument: (workspaceId, conversationId),
    from: this,
  );

  @override
  String toString() => r'browserSessionProvider';
}

abstract class _$BrowserSessionNotifier
    extends $AsyncNotifier<BrowserSessionState> {
  late final _$args = ref.$arg as (String, String);
  String get workspaceId => _$args.$1;
  String get conversationId => _$args.$2;

  FutureOr<BrowserSessionState> build(
    String workspaceId,
    String conversationId,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<BrowserSessionState>, BrowserSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BrowserSessionState>, BrowserSessionState>,
              AsyncValue<BrowserSessionState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
