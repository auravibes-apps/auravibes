// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/models/widgets/select_workspace_model_selection_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WorkspaceModelSelectionWithConnectionEntity _makeSelection(String id) {
  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: WorkspaceModelSelectionEntity(
      id: id,
      modelId: 'model-$id',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      modelConnectionId: 'conn-$id',
    ),
    modelConnection: ModelConnectionEntity(
      id: 'conn-$id',
      name: 'Test',
      key: 'key',
      modelId: 'openai',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      workspaceId: 'ws-1',
    ),
    modelsProvider: const ApiModelProviderEntity(
      id: 'openai',
      name: 'OpenAI',
      type: null,
    ),
  );
}

void main() {
  group('findProviderForModelId', () {
    test('returns null when workspaceModelSelectionId is null', () {
      final result = findProviderForModelId({}, null);
      expect(result, isNull);
    });

    test('returns null when groupedModels is empty', () {
      final result = findProviderForModelId({}, 'sel-1');
      expect(result, isNull);
    });

    test('returns provider name when model found', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'OpenAI': [_makeSelection('sel-1')],
          };
      final result = findProviderForModelId(grouped, 'sel-1');
      expect(result, 'OpenAI');
    });

    test('returns null when model not found in any provider', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'OpenAI': [_makeSelection('sel-1')],
            'Anthropic': [_makeSelection('sel-2')],
          };
      final result = findProviderForModelId(grouped, 'sel-999');
      expect(result, isNull);
    });

    test('returns correct provider when model in second provider', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'OpenAI': [_makeSelection('sel-1')],
            'Anthropic': [_makeSelection('sel-2')],
          };
      final result = findProviderForModelId(grouped, 'sel-2');
      expect(result, 'Anthropic');
    });

    test('searches all providers and returns first match', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'ProviderA': [_makeSelection('sel-a')],
            'ProviderB': [_makeSelection('sel-b')],
            'ProviderC': [_makeSelection('sel-c')],
          };
      final result = findProviderForModelId(grouped, 'sel-b');
      expect(result, 'ProviderB');
    });

    test('handles provider with empty model list', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'OpenAI': <WorkspaceModelSelectionWithConnectionEntity>[],
            'Anthropic': [_makeSelection('sel-2')],
          };
      final result = findProviderForModelId(grouped, 'sel-2');
      expect(result, 'Anthropic');
    });

    test('returns null when all providers have empty lists', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'OpenAI': <WorkspaceModelSelectionWithConnectionEntity>[],
            'Anthropic': <WorkspaceModelSelectionWithConnectionEntity>[],
          };
      final result = findProviderForModelId(grouped, 'sel-1');
      expect(result, isNull);
    });

    test(
      'returns provider for first match when multiple providers have same id',
      () {
        final grouped =
            <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
              'First': [_makeSelection('sel-dup')],
              'Second': [_makeSelection('sel-dup')],
            };
        final result = findProviderForModelId(grouped, 'sel-dup');
        expect(result, 'First');
      },
    );

    test('handles large number of providers', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{};
      for (var i = 0; i < 100; i++) {
        grouped['Provider$i'] = [_makeSelection('sel-$i')];
      }
      final result = findProviderForModelId(grouped, 'sel-50');
      expect(result, 'Provider50');
    });
  });

  group('SelectWorkspaceModelSelectionWidget', () {
    const widget = SelectWorkspaceModelSelectionWidget(
      workspaceId: 'ws-1',
      selectWorkspaceModelSelectionId: _noop,
      onProviderChanged: _noop,
    );

    test('preferredSize has height 120', () {
      expect(widget.preferredSize.height, 120);
    });

    test('preferredSize width is fromHeight derived', () {
      expect(widget.preferredSize.width, double.infinity);
    });

    test('is a PreferredSizeWidget', () {
      expect(widget, isA<PreferredSizeWidget>());
    });

    test('stores workspaceId', () {
      expect(widget.workspaceId, 'ws-1');
    });

    test('workspaceModelSelectionId defaults to null', () {
      expect(widget.workspaceModelSelectionId, isNull);
    });

    test('selectedProviderId defaults to null', () {
      expect(widget.selectedProviderId, isNull);
    });

    test('accepts optional workspaceModelSelectionId', () {
      const w = SelectWorkspaceModelSelectionWidget(
        workspaceId: 'ws-1',
        selectWorkspaceModelSelectionId: _noop,
        onProviderChanged: _noop,
        workspaceModelSelectionId: 'sel-1',
      );
      expect(w.workspaceModelSelectionId, 'sel-1');
    });

    test('accepts optional selectedProviderId', () {
      const w = SelectWorkspaceModelSelectionWidget(
        workspaceId: 'ws-1',
        selectWorkspaceModelSelectionId: _noop,
        onProviderChanged: _noop,
        selectedProviderId: 'OpenAI',
      );
      expect(w.selectedProviderId, 'OpenAI');
    });

    test('accepts optional key', () {
      const w = SelectWorkspaceModelSelectionWidget(
        workspaceId: 'ws-1',
        selectWorkspaceModelSelectionId: _noop,
        onProviderChanged: _noop,
        key: Key('test-key'),
      );
      expect(w.key, const Key('test-key'));
    });
  });

  group('findProviderForModelId additional', () {
    test('handles provider with single model', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'Provider': [_makeSelection('sel-1')],
          };
      expect(findProviderForModelId(grouped, 'sel-1'), 'Provider');
      expect(findProviderForModelId(grouped, 'sel-999'), isNull);
    });

    test('handles provider with multiple models', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{
            'OpenAI': [
              _makeSelection('sel-1'),
              _makeSelection('sel-2'),
              _makeSelection('sel-3'),
            ],
          };
      expect(findProviderForModelId(grouped, 'sel-2'), 'OpenAI');
      expect(findProviderForModelId(grouped, 'sel-3'), 'OpenAI');
    });

    test('returns null for null groupedModels map values', () {
      final grouped =
          <String, List<WorkspaceModelSelectionWithConnectionEntity>>{};
      expect(findProviderForModelId(grouped, 'any'), isNull);
    });
  });
}

void _noop(String? _) {}
