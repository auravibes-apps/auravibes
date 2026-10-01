// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model_connections_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatModelConnections)
final chatModelConnectionsProvider = ChatModelConnectionsFamily._();

final class ChatModelConnectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ModelConnectionEntity>>,
          List<ModelConnectionEntity>,
          Stream<List<ModelConnectionEntity>>
        >
    with
        $FutureModifier<List<ModelConnectionEntity>>,
        $StreamProvider<List<ModelConnectionEntity>> {
  ChatModelConnectionsProvider._({
    required ChatModelConnectionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatModelConnectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatModelConnectionsHash();

  @override
  String toString() {
    return r'chatModelConnectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ModelConnectionEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ModelConnectionEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return chatModelConnections(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatModelConnectionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatModelConnectionsHash() =>
    r'5a60881b71ea80453833acc19da8b10d4cfc4bb8';

final class ChatModelConnectionsFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<List<ModelConnectionEntity>>, String> {
  ChatModelConnectionsFamily._()
    : super(
        retry: null,
        name: r'chatModelConnectionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatModelConnectionsProvider call(String workspaceId) =>
      ChatModelConnectionsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'chatModelConnectionsProvider';
}
