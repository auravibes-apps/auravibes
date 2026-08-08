import 'package:auravibes_app/app_storage_namespace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses legacy namespace for absent hash source', () {
    expect(appStorageNamespaceFor(null), 'auravibes_app');
    expect(appStorageNamespaceFor(''), 'auravibes_app');
  });

  test('returns stable, distinct safe namespaces for worktree paths', () {
    final first = appStorageNamespaceFor('/Users/me/worktrees/one');
    final second = appStorageNamespaceFor('/private/tmp/worktrees/two');

    expect(first, matches(RegExp(r'^auravibes_app_[0-9a-f]{16}$')));
    expect(appStorageNamespaceFor('/Users/me/worktrees/one'), first);
    expect(second, isNot(first));
  });
}
