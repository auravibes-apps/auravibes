// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_mcp_connection_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(testMcpConnectionUsecase)
final testMcpConnectionUsecaseProvider = TestMcpConnectionUsecaseFamily._();

final class TestMcpConnectionUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<TestMcpConnectionUsecase>,
          TestMcpConnectionUsecase,
          FutureOr<TestMcpConnectionUsecase>
        >
    with
        $FutureModifier<TestMcpConnectionUsecase>,
        $FutureProvider<TestMcpConnectionUsecase> {
  TestMcpConnectionUsecaseProvider._({
    required TestMcpConnectionUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'testMcpConnectionUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$testMcpConnectionUsecaseHash();

  @override
  String toString() {
    return r'testMcpConnectionUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TestMcpConnectionUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TestMcpConnectionUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return testMcpConnectionUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TestMcpConnectionUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$testMcpConnectionUsecaseHash() =>
    r'b0301f73b922babc22a4e767e9c780d5990a599b';

final class TestMcpConnectionUsecaseFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TestMcpConnectionUsecase>, String> {
  TestMcpConnectionUsecaseFamily._()
    : super(
        retry: null,
        name: r'testMcpConnectionUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TestMcpConnectionUsecaseProvider call(String workspaceId) =>
      TestMcpConnectionUsecaseProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'testMcpConnectionUsecaseProvider';
}
