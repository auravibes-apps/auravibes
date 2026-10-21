import 'dart:io';

import 'package:auravibes_app/tool/empty_catalog_delegation_eval.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opt in with a comma-separated provider:model list and matching API keys.
/// Run this file with `fvm flutter test`.
void main() {
  const casesEnvironmentKey = 'AURAVIBES_EMPTY_CATALOG_EVAL_CASES';
  final rawCases = Platform.environment[casesEnvironmentKey];
  final cases = rawCases == null || rawCases.trim().isEmpty
      ? const <EmptyCatalogEvalCase>[]
      : parseEmptyCatalogEvalCases(
          rawCases.split(',').map((value) => value.trim()).toList(),
        );

  if (cases.isEmpty) {
    test(
      'is opt in and makes no provider calls by default',
      () => expect(cases, isEmpty),
      skip: 'Set $casesEnvironmentKey to provider:model cases to run.',
    );

    return;
  }

  for (final evalCase in cases) {
    test('${evalCase.provider}:${evalCase.model}', () async {
      final environmentKey = _apiKeyEnvironmentKey(evalCase.provider);
      final apiKey = Platform.environment[environmentKey];
      if (apiKey == null) {
        fail('Set $environmentKey to run this provider case.');
      }

      final result = await runProviderModelEmptyCatalogDelegationEval(
        provider: evalCase.provider,
        model: evalCase.model,
        apiKey: apiKey,
      );
      expect(result.passed, isTrue, reason: result.toJson().toString());
    });
  }
}

String _apiKeyEnvironmentKey(String provider) => switch (provider) {
  'openai' => 'OPENAI_API_KEY',
  'anthropic' => 'ANTHROPIC_API_KEY',
  'openrouter' => 'OPENROUTER_API_KEY',
  _ => throw FormatException('Unsupported provider: $provider.'),
};
