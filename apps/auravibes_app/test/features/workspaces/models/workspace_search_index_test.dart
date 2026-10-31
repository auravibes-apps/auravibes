import 'package:auravibes_app/features/workspaces/models/workspace_search_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceSearchIndex', () {
    test('folds accents and compatibility characters for matching', () {
      final cafe = _SearchItem('cafe', 'Caf\u00e9 Local');
      final flower = _SearchItem('flower', '\uFB02ower Garden');
      final index = _index([cafe, flower]);

      expect(index.matching(normalizeWorkspaceSearch('cafe')).map(_name), [
        'Caf\u00e9 Local',
      ]);
      expect(index.matching(normalizeWorkspaceSearch('flower')).map(_name), [
        '\uFB02ower Garden',
      ]);
    });

    test('rebuilds after a workspace is renamed', () {
      final workspace = _SearchItem('workspace', 'Caf\u00e9 Local');
      var index = _index([workspace]);
      expect(index.matching(normalizeWorkspaceSearch('cafe')), hasLength(1));

      workspace.name = 'Bakery Local';
      expect(index.hasSameItems([workspace]), isFalse);
      index = _index([workspace]);

      expect(index.matching(normalizeWorkspaceSearch('cafe')), isEmpty);
      expect(index.matching(normalizeWorkspaceSearch('bakery')), hasLength(1));
    });

    test(
      'rebuilds after deletion, membership change, or newly loaded results',
      () {
        final first = _SearchItem('first', 'Alpha Local');
        final second = _SearchItem('second', 'Beta Cloud');
        final original = _index([first, second]);

        expect(original.hasSameItems([first]), isFalse);
        expect(
          original.hasSameItems([first, second, _SearchItem('third', 'Gamma')]),
          isFalse,
        );

        final loaded = _SearchItem('third', 'Gamma Local');
        final refreshed = _index([first, second, loaded]);
        expect(
          refreshed.matching(normalizeWorkspaceSearch('gamma')).single.item,
          loaded,
        );
      },
    );

    test('applies sort changes to the current filtered workspace set', () {
      final zeta = _SearchItem('zeta', 'Workspace');
      final alpha = _SearchItem('alpha', 'Workspace');
      final middle = _SearchItem('middle', 'Workspace');
      final index = _index([zeta, middle, alpha]);

      expect(index.search('workspace').map((entry) => entry.stableId), [
        'alpha',
        'middle',
        'zeta',
      ]);
      expect(
        index
            .search('workspace', descending: true)
            .map((entry) => entry.stableId),
        ['zeta', 'middle', 'alpha'],
      );
      expect(index.hasSameItems([zeta, middle, alpha]), isTrue);
    });
  });
}

WorkspaceSearchIndex<_SearchItem> _index(Iterable<_SearchItem> items) =>
    WorkspaceSearchIndex(
      items,
      nameOf: (item) => item.name,
      idOf: (item) => item.id,
    );

String _name(WorkspaceSearchEntry<_SearchItem> entry) => entry.item.name;

class _SearchItem(final String id, String name) {
  String name = name;
}
