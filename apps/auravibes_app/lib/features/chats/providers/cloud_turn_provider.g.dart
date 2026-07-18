// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_turn_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudTurnUsecase)
final cloudTurnUsecaseProvider = CloudTurnUsecaseFamily._();

final class CloudTurnUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudTurnUsecase?>,
          CloudTurnUsecase?,
          FutureOr<CloudTurnUsecase?>
        >
    with
        $FutureModifier<CloudTurnUsecase?>,
        $FutureProvider<CloudTurnUsecase?> {
  CloudTurnUsecaseProvider._({
    required CloudTurnUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cloudTurnUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudTurnUsecaseHash();

  @override
  String toString() {
    return r'cloudTurnUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudTurnUsecase?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudTurnUsecase?> create(Ref ref) {
    final argument = this.argument as String;
    return cloudTurnUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudTurnUsecaseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudTurnUsecaseHash() => r'e596d18cb757666008133488774a7f1f4d57fcb3';

final class CloudTurnUsecaseFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CloudTurnUsecase?>, String> {
  CloudTurnUsecaseFamily._()
    : super(
        retry: null,
        name: r'cloudTurnUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudTurnUsecaseProvider call(String workspaceId) =>
      CloudTurnUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'cloudTurnUsecaseProvider';
}
