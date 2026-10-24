import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/notifiers/directory_navigation_notifier.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('late refresh failure preserves a newly selected folder', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = directoryNavigationProvider('workspace');
    final navigation = container.read(provider.notifier)
      ..enter(const WorkspaceFolder(id: 'old', name: 'Old', revision: 1));
    final pending = Completer<OrganizeWorkspaceFoldersUsecase>();
    final refresh = navigation.refreshPath(pending.future);
    navigation
      ..ancestor(0)
      ..enter(const WorkspaceFolder(id: 'new', name: 'New', revision: 1));
    pending.completeError(const WorkspaceFolderException());
    await refresh;
    expect(container.read(provider).path.single.id, 'new');
    expect(container.read(provider).failure, isNull);
  });
}
