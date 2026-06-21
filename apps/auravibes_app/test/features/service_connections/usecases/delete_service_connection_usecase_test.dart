import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/usecases/delete_service_connection_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('DeleteServiceConnectionUsecase', () {
    test(
      'deletes model provider connections through model repository',
      () async {
        final modelRepository = _MockModelConnectionRepository();
        final credentialsRepository = _MockSkillCredentialsRepository();
        when(
          () => modelRepository.deleteModelConnection('model-connection-1'),
        ).thenAnswer((_) => Future<void>.value());
        final usecase = DeleteServiceConnectionUsecase(
          modelConnectionRepository: modelRepository,
          skillCredentialsRepository: credentialsRepository,
        );

        await expectLater(
          usecase(
            connectionId: 'model-connection-1',
            kind: ServiceConnectionListItemKind.modelProvider,
          ),
          completes,
        );

        verify(
          () => modelRepository.deleteModelConnection('model-connection-1'),
        ).called(1);
        final _ = verifyNever(
          () => credentialsRepository.deleteCredential(any()),
        );
      },
    );

    test('deletes skill credentials through credentials repository', () async {
      final modelRepository = _MockModelConnectionRepository();
      final credentialsRepository = _MockSkillCredentialsRepository();
      when(
        () => credentialsRepository.deleteCredential('credential-1'),
      ).thenAnswer((_) => Future<void>.value());
      final usecase = DeleteServiceConnectionUsecase(
        modelConnectionRepository: modelRepository,
        skillCredentialsRepository: credentialsRepository,
      );

      await expectLater(
        usecase(
          connectionId: 'credential-1',
          kind: ServiceConnectionListItemKind.skillCredential,
        ),
        completes,
      );

      final _ = verifyNever(() => modelRepository.deleteModelConnection(any()));
      verify(
        () => credentialsRepository.deleteCredential('credential-1'),
      ).called(1);
    });

    test('rejects MCP server delete requests', () {
      final modelRepository = _MockModelConnectionRepository();
      final credentialsRepository = _MockSkillCredentialsRepository();
      final usecase = DeleteServiceConnectionUsecase(
        modelConnectionRepository: modelRepository,
        skillCredentialsRepository: credentialsRepository,
      );

      expect(
        () => usecase(
          connectionId: 'mcp-credential-1',
          kind: ServiceConnectionListItemKind.mcpServer,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'MCP server service connections cannot be deleted by this action.',
          ),
        ),
      );
      final _ = verifyNever(() => modelRepository.deleteModelConnection(any()));
      final _ = verifyNever(
        () => credentialsRepository.deleteCredential(any()),
      );
    });
  });
}

class _MockModelConnectionRepository extends Mock
    implements ModelConnectionRepository {}

class _MockSkillCredentialsRepository extends Mock
    implements SkillCredentialsRepository {}
