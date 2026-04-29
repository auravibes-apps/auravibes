// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NewChatNotifier)
final newChatProvider = NewChatNotifierFamily._();

final class NewChatNotifierProvider
    extends $NotifierProvider<NewChatNotifier, NewChatState> {
  NewChatNotifierProvider._({
    required NewChatNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'newChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$newChatNotifierHash();

  @override
  String toString() {
    return r'newChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NewChatNotifier create() => NewChatNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewChatState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NewChatNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$newChatNotifierHash() => r'836f9e238def05ffd2eaa88ed2b26a16199a5089';

final class NewChatNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          NewChatNotifier,
          NewChatState,
          NewChatState,
          NewChatState,
          String
        > {
  NewChatNotifierFamily._()
    : super(
        retry: null,
        name: r'newChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NewChatNotifierProvider call(String workspaceId) =>
      NewChatNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'newChatProvider';
}

abstract class _$NewChatNotifier extends $Notifier<NewChatState> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  NewChatState build(String workspaceId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NewChatState, NewChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NewChatState, NewChatState>,
              NewChatState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
