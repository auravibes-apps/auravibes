import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('accepts only bounded typed host action bindings', () {
    final update = A2uiSavedAction.fromJson({
      'version': 1,
      'type': 'updateSelectedRecord',
      'inputs': {'title': '/answers/title'},
    });
    expect(update.type, A2uiSavedActionType.updateSelectedRecord);
    expect(update.toJson()['inputs'], {'title': '/answers/title'});

    final connector = A2uiSavedAction.fromJson({
      'version': 1,
      'type': 'connectorWrite',
      'toolId': 'connector/example/update_record',
      'revision': 'v1',
      'connectionId': 'workspace-connection',
      'inputs': {'record_id': '/answers/id', 'title': '/answers/title'},
    });
    expect(connector.type, A2uiSavedActionType.connectorWrite);
    expect(connector.connectionId, 'workspace-connection');
  });

  test('rejects executable destinations and malformed input bindings', () {
    for (final action in <Map<String, Object?>>[
      {
        'version': 1,
        'type': 'updateSelectedRecord',
        'inputs': {'title': '/answers/title'},
        'sql': 'update records',
      },
      {
        'version': 1,
        'type': 'arbitraryCommand',
        'command': 'deleteEverything',
        'inputs': {},
      },
      {
        'version': 1,
        'type': 'updateSelectedRecord',
        'inputs': {'title': 'answers/title'},
      },
      {
        'version': 1,
        'type': 'connectorWrite',
        'toolId': 'connector/example/update_record',
        'revision': 'v1',
        'inputs': {'bad target': '/answers/title'},
      },
    ]) {
      expect(() => A2uiSavedAction.fromJson(action), throwsFormatException);
    }
  });

  test('action can read only paths owned by form input components', () {
    final action = A2uiSavedAction.fromJson({
      'version': 1,
      'type': 'updateSelectedRecord',
      'inputs': {'title': '/answers/title'},
    });
    expect(
      () => validateA2uiSavedActionInputs(action, [
        {
          'id': 'title',
          'component': 'TextField',
          'value': {'path': '/answers/title'},
        },
      ]),
      returnsNormally,
    );
    expect(
      () => validateA2uiSavedActionInputs(action, [
        {
          'id': 'title',
          'component': 'Text',
          'text': {'path': '/answers/title'},
        },
      ]),
      throwsFormatException,
    );
  });
}
