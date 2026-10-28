import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('directory scope includes workspace references independently of '
      'chat selection', () {
    final scope = WorkspaceReferenceScope(
      WorkspaceContextSelection(
        workspaceId: 'workspace',
        conversationId: 'chat',
        itemId: '',
        kind: 'directory',
      ),
      const [],
    );
    final column = {
      'id': 'related',
      'type': 'reference',
      'targetTableId': 'target',
      'targetMatchColumnId': 'label',
    };

    expect(scope.tableAllowed('target'), isTrue);
    expect(scope.recordAllowed('target', 'row'), isTrue);
    expect(scope.columnAllowed(column, const {}), isTrue);
    expect(scope.valueAllowed('target', 'row', null), isTrue);
    expect(scope.readableColumn(column)['targetMatchColumnId'], 'label');
    expect(scope.projectValues([column], {'related': 'row'}).values, {
      'related': 'row',
    });
  });

  test('empty reference identifiers are not included by directory scope', () {
    final scope = WorkspaceReferenceScope(
      WorkspaceContextSelection(
        workspaceId: 'workspace',
        conversationId: 'chat',
        itemId: '',
        kind: 'directory',
      ),
      const [],
    );

    expect(scope.tableAllowed(''), isFalse);
    expect(scope.recordAllowed('', ''), isFalse);
  });
}
