// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-top-level-members-in-tests
// Required: Test files keep shared fixtures and helpers top-level.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.

// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.

// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

QueryExecutor createTestConnection() {
  return DatabaseConnection.delayed(
    Future(() {
      return DatabaseConnection(
        LazyDatabase(() async {
          return NativeDatabase.memory();
        }),
      );
    }),
  );
}

void main() {
  group('ApiModelProvidersDao', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase(connection: createTestConnection());
    });

    tearDown(() async {
      await database.close();
    });

    test('getAllProviders returns empty list when no providers', () async {
      final providers = await database.apiModelProvidersDao.getAllProviders();
      expect(providers, isEmpty);
    });

    test('upsertProvider inserts and retrieves provider', () async {
      final inserted = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(
          id: 'openai',
          name: 'OpenAI',
        ),
      );
      expect(inserted.id, equals('openai'));
      expect(inserted.name, equals('OpenAI'));
    });

    test('upsertProvider updates existing provider on conflict', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final updated = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI Updated'),
      );
      expect(updated.name, equals('OpenAI Updated'));
    });

    test('getProviderById returns provider when exists', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final provider = await database.apiModelProvidersDao.getProviderById(
        'openai',
      );
      expect(provider, isNotNull);
      expect(
        (provider ?? fail('Expected provider to be non-null')).name,
        equals('OpenAI'),
      );
    });

    test('getProviderById returns null when not exists', () async {
      final provider = await database.apiModelProvidersDao.getProviderById(
        'nonexistent',
      );
      expect(provider, isNull);
    });

    test('getProvidersByType returns filtered providers', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'anthropic', name: 'Anthropic'),
      );
      final providers = await database.apiModelProvidersDao.getProvidersByType(
        'nonexistent',
      );
      expect(providers, isEmpty);
    });

    test('deleteProvider removes provider and returns true', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final deleted = await database.apiModelProvidersDao.deleteProvider(
        'openai',
      );
      expect(deleted, isTrue);
      final provider = await database.apiModelProvidersDao.getProviderById(
        'openai',
      );
      expect(provider, isNull);
    });

    test('deleteProvider returns false for nonexistent provider', () async {
      final deleted = await database.apiModelProvidersDao.deleteProvider(
        'nonexistent',
      );
      expect(deleted, isFalse);
    });

    test('providerExists returns true when provider exists', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final exists = await database.apiModelProvidersDao.providerExists(
        'openai',
      );
      expect(exists, isTrue);
    });

    test('providerExists returns false when provider does not exist', () async {
      final exists = await database.apiModelProvidersDao.providerExists(
        'nonexistent',
      );
      expect(exists, isFalse);
    });

    test('searchProvidersByName returns matching providers', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'anthropic', name: 'Anthropic'),
      );
      final results = await database.apiModelProvidersDao.searchProvidersByName(
        'Open',
      );
      expect(results.length, equals(1));
      expect(results.firstOrNull?.name, equals('OpenAI'));
    });

    test('getProviderCount returns correct count', () async {
      expect(await database.apiModelProvidersDao.getProviderCount(), equals(0));
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      expect(await database.apiModelProvidersDao.getProviderCount(), equals(1));
    });

    test('getAllProviders sorts popular providers first', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'deepseek', name: 'DeepSeek'),
      );
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'zzz', name: 'ZZZ Provider'),
      );
      final providers = await database.apiModelProvidersDao.getAllProviders();
      expect(providers.firstOrNull?.id, equals('openai'));
      expect(providers[1].id, equals('deepseek'));
      expect(providers[2].id, equals('zzz'));
    });

    test('batchUpsertProviders inserts multiple providers', () async {
      final results = await database.apiModelProvidersDao.batchUpsertProviders([
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
        ApiModelProvidersCompanion.insert(id: 'anthropic', name: 'Anthropic'),
      ]);
      expect(results.length, equals(2));
      expect(await database.apiModelProvidersDao.getProviderCount(), equals(2));
    });

    test('deleteAllProviders removes all providers', () async {
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'openai', name: 'OpenAI'),
      );
      final _ = await database.apiModelProvidersDao.upsertProvider(
        ApiModelProvidersCompanion.insert(id: 'anthropic', name: 'Anthropic'),
      );
      final deleted = await database.apiModelProvidersDao.deleteAllProviders();
      expect(deleted, equals(2));
      expect(await database.apiModelProvidersDao.getProviderCount(), equals(0));
    });
  });
}
