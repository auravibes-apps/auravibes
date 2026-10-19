// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_elicitation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(McpElicitationNotifier)
final mcpElicitationProvider = McpElicitationNotifierFamily._();

final class McpElicitationNotifierProvider
    extends
        $NotifierProvider<McpElicitationNotifier, List<McpElicitationPending>> {
  McpElicitationNotifierProvider._({
    required McpElicitationNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mcpElicitationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mcpElicitationNotifierHash();

  @override
  String toString() {
    return r'mcpElicitationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  McpElicitationNotifier create() => McpElicitationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<McpElicitationPending> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<McpElicitationPending>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is McpElicitationNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mcpElicitationNotifierHash() =>
    r'ac1153b7f3d51b3d6ab0bb58cabf7dbf38dcc413';

final class McpElicitationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          McpElicitationNotifier,
          List<McpElicitationPending>,
          List<McpElicitationPending>,
          List<McpElicitationPending>,
          String
        > {
  McpElicitationNotifierFamily._()
    : super(
        retry: null,
        name: r'mcpElicitationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  McpElicitationNotifierProvider call(String conversationId) =>
      McpElicitationNotifierProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'mcpElicitationProvider';
}

abstract class _$McpElicitationNotifier
    extends $Notifier<List<McpElicitationPending>> {
  late final _$args = ref.$arg as String;
  String get conversationId => _$args;

  List<McpElicitationPending> build(String conversationId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<List<McpElicitationPending>, List<McpElicitationPending>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<McpElicitationPending>,
                List<McpElicitationPending>
              >,
              List<McpElicitationPending>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
