import 'package:auravibes_app/app_storage_namespace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses legacy namespace for absent hash source', () {
    expect(AppStorageNamespace.forHashSource(null), 'auravibes_app');
    expect(AppStorageNamespace.forHashSource(''), 'auravibes_app');
  });

  test('returns stable, distinct safe namespaces for worktree paths', () {
    final first = AppStorageNamespace.forHashSource('/Users/me/worktrees/one');
    final second = AppStorageNamespace.forHashSource(
      '/private/tmp/worktrees/two',
    );

    expect(first, matches(RegExp(r'^auravibes_app_[0-9a-f]{16}$')));
    expect(AppStorageNamespace.forHashSource('/Users/me/worktrees/one'), first);
    expect(second, isNot(first));
  });
}
