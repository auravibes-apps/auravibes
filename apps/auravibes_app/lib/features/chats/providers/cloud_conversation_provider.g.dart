// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudConversationUsecase)
final cloudConversationUsecaseProvider = CloudConversationUsecaseFamily._();

final class CloudConversationUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudConversationUsecase?>,
          CloudConversationUsecase?,
          FutureOr<CloudConversationUsecase?>
        >
    with
        $FutureModifier<CloudConversationUsecase?>,
        $FutureProvider<CloudConversationUsecase?> {
  CloudConversationUsecaseProvider._({
    required CloudConversationUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cloudConversationUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudConversationUsecaseHash();

  @override
  String toString() {
    return r'cloudConversationUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudConversationUsecase?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudConversationUsecase?> create(Ref ref) {
    final argument = this.argument as String;
    return cloudConversationUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudConversationUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudConversationUsecaseHash() =>
    r'368d26b8cb02896d07770d52e077de0321f4e7e9';

final class CloudConversationUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<CloudConversationUsecase?>, String> {
  CloudConversationUsecaseFamily._()
    : super(
        retry: null,
        name: r'cloudConversationUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudConversationUsecaseProvider call(String workspaceId) =>
      CloudConversationUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'cloudConversationUsecaseProvider';
}
