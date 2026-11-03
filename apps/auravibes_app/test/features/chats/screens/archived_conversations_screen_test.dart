import 'dart:ui' show Locale, Size;

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/archived_conversations_screen.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('explains that cloud archiving is device-local', (tester) async {
    const cloudWorkspace = CloudWorkspaceRef(
      localWorkspaceId: 'cloud-workspace',
      serverUrl: 'https://example.com',
      accountId: 'account',
      cloudWorkspaceId: 7,
    );
    const session = WorkspaceSession(cloudWorkspace);

    await tester.pumpWidget(
      TestableApp(
        child: ArchivedConversationsScreen(
          workspaceId: cloudWorkspace.localWorkspaceId,
        ),
        overrides: [
          workspaceSessionForRouteProvider(
            cloudWorkspace.localWorkspaceId,
          ).overrideWithValue(const AsyncData(session)),
          conversationsStreamProvider((
            workspaceId: cloudWorkspace.localWorkspaceId,
            search: '',
            scope: .archived,
            pagination: (limit: 21, offset: 0),
          )).overrideWith((ref) => Stream.value(const <ConversationEntity>[])),
          listWorkspaceModelSelectionsProvider.overrideWith(
            (ref, workspaceId) => Stream.value([]),
          ),
        ],
        workspaceId: cloudWorkspace.localWorkspaceId,
        workspaceSession: session,
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Archived on this device'), findsOneWidget);
    expect(
      find.text(
        'In cloud workspaces, archiving is saved only in this app on this '
        'device. Other members and your other devices can still see this '
        'shared conversation.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps the cloud notice in Spanish at compact width', (
    tester,
  ) async {
    const cloudWorkspace = CloudWorkspaceRef(
      localWorkspaceId: 'cloud-workspace',
      serverUrl: 'https://example.com',
      accountId: 'account',
      cloudWorkspaceId: 7,
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      TestableApp(
        child: ArchivedConversationsScreen(
          workspaceId: cloudWorkspace.localWorkspaceId,
        ),
        overrides: [
          workspaceSessionForRouteProvider(
            cloudWorkspace.localWorkspaceId,
          ).overrideWithValue(
            const AsyncData(WorkspaceSession(cloudWorkspace)),
          ),
          conversationsStreamProvider((
            workspaceId: cloudWorkspace.localWorkspaceId,
            search: '',
            scope: .archived,
            pagination: (limit: 21, offset: 0),
          )).overrideWith((ref) => Stream.value(const <ConversationEntity>[])),
          listWorkspaceModelSelectionsProvider.overrideWith(
            (ref, workspaceId) => Stream.value([]),
          ),
        ],
        workspaceId: cloudWorkspace.localWorkspaceId,
        workspaceSession: const WorkspaceSession(cloudWorkspace),
        startLocale: const Locale('es'),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Archivadas en este dispositivo'), findsOneWidget);
    expect(
      find.text(
        'En los espacios en la nube, el archivo se guarda solo en esta app',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
