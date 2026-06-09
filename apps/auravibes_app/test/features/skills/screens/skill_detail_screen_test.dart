// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skills_repository_impl.dart';
import 'package:auravibes_app/data/repositories/workspace_repository_impl.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildScreen(ValueNotifier<_SkillDetailScreenFixture> fixture) {
    return EasyLocalization(
      key: UniqueKey(),
      child: Builder(
        builder: (context) {
          return ValueListenableBuilder<_SkillDetailScreenFixture>(
            valueListenable: fixture,
            builder: (context, value, _) {
              return UncontrolledProviderScope(
                container: value.container,
                child: MaterialApp(
                  home: SkillDetailScreen(
                    workspaceId: value.workspaceId,
                    skillId: value.skillId,
                    key: ValueKey('${value.workspaceId}:${value.skillId}'),
                  ),
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                ),
              );
            },
          );
        },
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder,
  ) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Expected finder to appear: $finder');
  }

  testWidgets('renders skill detail credential states', (tester) async {
    final appSkillDatabase = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(appSkillDatabase.close);
    final appSkillContainer = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(appSkillDatabase)],
    );
    addTearDown(appSkillContainer.dispose);
    final appSkillWorkspace =
        await WorkspaceRepositoryImpl(
          appSkillDatabase,
        ).createWorkspace(
          const WorkspaceToCreate(
            name: 'Test Workspace',
            type: WorkspaceType.local,
          ),
        );
    final selectedCredentialDatabase = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(selectedCredentialDatabase.close);
    final selectedEncryptionService = EncryptionService(
      _FakeSecretKeyManager(),
    );
    final selectedCredentialContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(selectedCredentialDatabase),
        encryptionServiceProvider.overrideWithValue(selectedEncryptionService),
      ],
    );
    addTearDown(selectedCredentialContainer.dispose);
    final selectedCredentialWorkspace =
        await WorkspaceRepositoryImpl(
          selectedCredentialDatabase,
        ).createWorkspace(
          const WorkspaceToCreate(
            name: 'Test Workspace',
            type: WorkspaceType.local,
          ),
        );
    final definition =
        await SkillCredentialDefinitionsRepositoryImpl(
          selectedCredentialDatabase,
        ).createDefinition(
          selectedCredentialWorkspace.id,
          const SkillCredentialDefinitionToCreate(
            title: 'TheCatAPI Key',
            attributesJson: '{"apiKey":{"description":"API key"}}',
          ),
        );
    final skillWithDefinition =
        await SkillsRepositoryImpl(
          selectedCredentialDatabase,
        ).createSkill(
          selectedCredentialWorkspace.id,
          SkillToCreate(
            kind: SkillKind.template,
            title: 'TheCatAPI',
            description: 'Fetch cat images.',
            content: 'Use TheCatAPI.',
            credentialDefinitionId: definition.id,
          ),
        );
    final _ =
        await SkillCredentialsRepositoryImpl(
          database: selectedCredentialDatabase,
          encryptionService: selectedEncryptionService,
        ).createCredential(
          selectedCredentialWorkspace.id,
          SkillCredentialToCreate(
            credentialDefinitionId: definition.id,
            name: 'TheCatAPI Key',
            attributes: const {'apiKey': 'secret-value'},
          ),
        );
    final optionalDefinition =
        await SkillCredentialDefinitionsRepositoryImpl(
          selectedCredentialDatabase,
        ).createDefinition(
          selectedCredentialWorkspace.id,
          const SkillCredentialDefinitionToCreate(
            title: 'Optional API Key',
            attributesJson: '{"apiKey":{"description":"API key"}}',
          ),
        );
    final optionalSkill =
        await SkillsRepositoryImpl(
          selectedCredentialDatabase,
        ).createSkill(
          selectedCredentialWorkspace.id,
          SkillToCreate(
            kind: SkillKind.template,
            title: 'Optional API Skill',
            description: 'Can run without credentials.',
            content: 'Use public endpoints when no credential exists.',
            credentialDefinitionId: optionalDefinition.id,
            isCredentialOptional: true,
          ),
        );
    final staleCredentialDatabase = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(staleCredentialDatabase.close);
    final staleCredentialContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(staleCredentialDatabase),
      ],
    );
    addTearDown(staleCredentialContainer.dispose);
    final staleCredentialWorkspace =
        await WorkspaceRepositoryImpl(
          staleCredentialDatabase,
        ).createWorkspace(
          const WorkspaceToCreate(
            name: 'Test Workspace',
            type: WorkspaceType.local,
          ),
        );
    final skillWithStaleDefinition =
        await SkillsRepositoryImpl(
          staleCredentialDatabase,
        ).createSkill(
          staleCredentialWorkspace.id,
          const SkillToCreate(
            kind: SkillKind.template,
            title: 'Broken Skill',
            description: 'Has a stale credential definition id.',
            content: 'Use credentials.',
            credentialDefinitionId: 'missing-definition-id',
          ),
        );

    final fixture = ValueNotifier(
      _SkillDetailScreenFixture(
        container: appSkillContainer,
        workspaceId: appSkillWorkspace.id,
        skillId: 'skills_manager',
      ),
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(buildScreen(fixture));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text(
        'App skills are built in and can only be enabled or disabled for '
        'this workspace.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Create user skill'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Create user skill'), findsOneWidget);
    expect(find.textContaining('create_user_skill'), findsOneWidget);
    expect(find.byIcon(Icons.save_outlined), findsNothing);

    fixture.value = _SkillDetailScreenFixture(
      container: selectedCredentialContainer,
      workspaceId: selectedCredentialWorkspace.id,
      skillId: skillWithDefinition.id,
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.byType(Scrollable));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('TheCatAPI Key'), findsOneWidget);
    expect(find.text('1 credential configured'), findsOneWidget);
    expect(find.text('Credential definition not found'), findsNothing);

    fixture.value = _SkillDetailScreenFixture(
      container: selectedCredentialContainer,
      workspaceId: selectedCredentialWorkspace.id,
      skillId: optionalSkill.id,
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.byType(Scrollable));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No credential is configured. This skill can still be loaded, but '
        'tools that require credentials will stay unavailable.',
      ),
      findsOneWidget,
    );

    fixture.value = _SkillDetailScreenFixture(
      container: staleCredentialContainer,
      workspaceId: staleCredentialWorkspace.id,
      skillId: skillWithStaleDefinition.id,
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.byType(Scrollable));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Credential definition not found'), findsOneWidget);
    expect(
      find.text('This skill needs a credential before it can be loaded.'),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}

class _FakeSecretKeyManager extends SecretKeyManager {
  final SecretKey _key = SecretKey(List<int>.filled(32, 7));

  @override
  Future<SecretKey> getOrCreateSecretKey() async => _key;
}

class _SkillDetailScreenFixture {
  const _SkillDetailScreenFixture({
    required this.container,
    required this.workspaceId,
    required this.skillId,
  });

  final ProviderContainer container;
  final String workspaceId;
  final String skillId;
}
