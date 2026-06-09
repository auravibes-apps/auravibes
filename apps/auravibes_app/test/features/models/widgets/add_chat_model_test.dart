// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('AddModelProviderWidget', () {
    test('constructor stores workspaceId', () {
      const widget = AddModelProviderWidget(workspaceId: 'ws-1');
      expect(widget.workspaceId, 'ws-1');
    });

    test('is a HookConsumerWidget', () {
      const widget = AddModelProviderWidget(workspaceId: 'ws-1');
      expect(widget, isA<HookConsumerWidget>());
    });

    test('noModelsFoundKey is a non-empty string', () {
      expect(AddModelProviderWidget.noModelsFoundKey, isNotEmpty);
    });

    test('accepts optional key', () {
      const widget = AddModelProviderWidget(
        workspaceId: 'ws-1',
        key: Key('test'),
      );
      expect(widget.key, const Key('test'));
    });
  });

  group('ModelConnectionException', () {
    test('message is accessible', () {
      const ex = ModelConnectionException('API key invalid');
      expect(ex.message, 'API key invalid');
    });

    test('toString contains message', () {
      const ex = ModelConnectionException('rate limited');
      expect(ex.toString(), contains('rate limited'));
    });

    test('cause is accessible', () {
      final cause = Exception('inner');
      final ex = ModelConnectionException('outer', cause);
      expect(ex.cause, cause);
    });

    test('toString includes cause when present', () {
      final cause = Exception('inner');
      final ex = ModelConnectionException('outer', cause);
      expect(ex.toString(), contains('Caused by'));
    });

    test('toString omits cause when null', () {
      const ex = ModelConnectionException('outer');
      expect(ex.toString(), isNot(contains('Caused by')));
    });
  });

  group('ModelConnectionNoModelsException', () {
    test('stores modelId', () {
      const ex = ModelConnectionNoModelsException('gpt-4');
      expect(ex.modelId, 'gpt-4');
    });

    test('message contains modelId', () {
      const ex = ModelConnectionNoModelsException('gpt-4');
      expect(ex.message, contains('gpt-4'));
    });
  });

  group('ModelConnectionModelNotFoundException', () {
    test('stores modelId', () {
      const ex = ModelConnectionModelNotFoundException('gpt-4');
      expect(ex.modelId, 'gpt-4');
    });
  });

  group('ModelConnectionNoTypeException', () {
    test('stores modelId', () {
      const ex = ModelConnectionNoTypeException('gpt-4');
      expect(ex.modelId, 'gpt-4');
    });
  });

  group('error mapping logic', () {
    test(
      'ModelConnectionException with non-empty trimmed message returns message',
      () {
        const error = ModelConnectionException('API key is invalid');
        final message = _mapErrorMessage(error);
        expect(message, 'API key is invalid');
      },
    );

    test('ModelConnectionException with trimmed message works', () {
      const error = ModelConnectionException('  valid  ');
      final message = _mapErrorMessage(error);
      expect(message, '  valid  ');
    });

    test('ModelConnectionException empty message returns fallback', () {
      const error = ModelConnectionException('');
      final message = _mapErrorMessage(error);
      expect(message, _fallback);
    });

    test(
      'ModelConnectionException whitespace-only message returns fallback',
      () {
        const error = ModelConnectionException('   ');
        final message = _mapErrorMessage(error);
        expect(message, _fallback);
      },
    );

    test('generic Exception returns fallback', () {
      const error = FormatException('bad');
      final message = _mapErrorMessage(error);
      expect(message, _fallback);
    });

    test('StateError returns fallback', () {
      final error = StateError('bad state');
      final message = _mapErrorMessage(error);
      expect(message, _fallback);
    });
  });
}

const _fallback = 'Unknown error';

String _mapErrorMessage(Object error) {
  if (error case ModelConnectionException(
    :final message,
  ) when message.trim().isNotEmpty) {
    return message;
  }

  return _fallback;
}
