// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_chat_attachment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudChatAttachmentUsecase)
final cloudChatAttachmentUsecaseProvider = CloudChatAttachmentUsecaseFamily._();

final class CloudChatAttachmentUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudChatAttachmentUsecase?>,
          CloudChatAttachmentUsecase?,
          FutureOr<CloudChatAttachmentUsecase?>
        >
    with
        $FutureModifier<CloudChatAttachmentUsecase?>,
        $FutureProvider<CloudChatAttachmentUsecase?> {
  CloudChatAttachmentUsecaseProvider._({
    required CloudChatAttachmentUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cloudChatAttachmentUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudChatAttachmentUsecaseHash();

  @override
  String toString() {
    return r'cloudChatAttachmentUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudChatAttachmentUsecase?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudChatAttachmentUsecase?> create(Ref ref) {
    final argument = this.argument as String;
    return cloudChatAttachmentUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudChatAttachmentUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudChatAttachmentUsecaseHash() =>
    r'26b1630ab9b9e3e4f45aec53ded754131249c2cf';

final class CloudChatAttachmentUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CloudChatAttachmentUsecase?>,
          String
        > {
  CloudChatAttachmentUsecaseFamily._()
    : super(
        retry: null,
        name: r'cloudChatAttachmentUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudChatAttachmentUsecaseProvider call(String workspaceId) =>
      CloudChatAttachmentUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'cloudChatAttachmentUsecaseProvider';
}
