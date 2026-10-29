import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('one-shot record query usecase survives delayed session', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final session = Completer<WorkspaceSession>();
    final container = ProviderContainer(
      overrides: [
        workspaceSessionForRouteProvider.overrideWith((_, _) => session.future),
        appDatabaseProvider.overrideWith((_) => database),
      ],
    );
    addTearDown(container.dispose);
    final pending = container.read(
      workspaceRecordQueryUsecaseProvider('one').future,
    );
    await container.pump();
    session.complete(
      const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'one')),
    );
    expect(await pending, isNotNull);
    await container.pump();
    expect(
      container.exists(workspaceRecordQueryUsecaseProvider('one')),
      isFalse,
    );
  });
}
