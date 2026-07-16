// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudConversationUsecase)
final cloudConversationUsecaseProvider = CloudConversationUsecaseProvider._();

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
  CloudConversationUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudConversationUsecaseProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          workspaceSessionProvider,
          cloudWorkspaceStateGatewayProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          CloudConversationUsecaseProvider.$allTransitiveDependencies0,
          CloudConversationUsecaseProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = workspaceSessionProvider;
  static final $allTransitiveDependencies1 = cloudWorkspaceStateGatewayProvider;

  @override
  String debugGetCreateSourceHash() => _$cloudConversationUsecaseHash();

  @$internal
  @override
  $FutureProviderElement<CloudConversationUsecase?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudConversationUsecase?> create(Ref ref) {
    return cloudConversationUsecase(ref);
  }
}

String _$cloudConversationUsecaseHash() =>
    r'd753da46d509282aff028a2910c5e0ba0973e3a1';
