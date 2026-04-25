import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/widgets/sidebar_conversations_widget.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets(
    'loads sidebar conversations when workspace id becomes available',
    (tester) async {
      final repository = _RecordingConversationRepository();
      addTearDown(repository.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repository),
            routerPathSegmentsProvider.overrideWithValue(const []),
          ],
          child: const MaterialApp(
            home: _SidebarWorkspaceHost(),
          ),
        ),
      );

      expect(repository.workspaceWatchCalls, isEmpty);

      await tester.tap(find.byKey(_SidebarWorkspaceHost.loadWorkspaceKey));
      await tester.pump();

      expect(
        repository.workspaceWatchCalls,
        equals([
          const _WorkspaceWatchCall(workspaceId: 'workspace-1', limit: 10),
        ]),
      );
    },
  );

  testWidgets(
    're-subscribes when workspace id changes',
    (tester) async {
      final repository = _RecordingConversationRepository();
      addTearDown(repository.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conversationRepositoryProvider.overrideWithValue(repository),
            routerPathSegmentsProvider.overrideWithValue(const []),
          ],
          child: const MaterialApp(
            home: _SidebarWorkspaceHost(),
          ),
        ),
      );

      await tester.tap(find.byKey(_SidebarWorkspaceHost.loadWorkspaceKey));
      await tester.pump();

      expect(
        repository.workspaceWatchCalls,
        equals([
          const _WorkspaceWatchCall(workspaceId: 'workspace-1', limit: 10),
        ]),
      );
      expect(repository._controllers, hasLength(1));
      final firstController = repository._controllers.single;

      await tester.tap(find.byKey(_SidebarWorkspaceHost.switchWorkspaceKey));
      await tester.pump();
      await tester.pump();

      expect(
        repository.workspaceWatchCalls,
        equals([
          const _WorkspaceWatchCall(workspaceId: 'workspace-1', limit: 10),
          const _WorkspaceWatchCall(workspaceId: 'workspace-2', limit: 10),
        ]),
      );
      expect(repository._controllers, hasLength(1));
      expect(repository._controllers, isNot(contains(firstController)));
    },
  );
}

class _SidebarWorkspaceHost extends StatefulWidget {
  const _SidebarWorkspaceHost();

  static const loadWorkspaceKey = Key('load-workspace');
  static const switchWorkspaceKey = Key('switch-workspace');

  @override
  State<_SidebarWorkspaceHost> createState() => _SidebarWorkspaceHostState();
}

class _SidebarWorkspaceHostState extends State<_SidebarWorkspaceHost> {
  String? _workspaceId;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(extensions: [AuraTheme.light]),
      child: Material(
        child: Column(
          children: [
            TextButton(
              key: _SidebarWorkspaceHost.loadWorkspaceKey,
              onPressed: () => setState(() => _workspaceId = 'workspace-1'),
              child: const Text('Load workspace'),
            ),
            TextButton(
              key: _SidebarWorkspaceHost.switchWorkspaceKey,
              onPressed: () => setState(() => _workspaceId = 'workspace-2'),
              child: const Text('Switch workspace'),
            ),
            SidebarConversationsWidget(workspaceId: _workspaceId),
          ],
        ),
      ),
    );
  }
}

@immutable
class _WorkspaceWatchCall {
  const _WorkspaceWatchCall({required this.workspaceId, required this.limit});

  final String workspaceId;
  final int? limit;

  @override
  bool operator ==(Object other) {
    return other is _WorkspaceWatchCall &&
        other.workspaceId == workspaceId &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(workspaceId, limit);

  @override
  String toString() {
    return '_WorkspaceWatchCall(workspaceId: $workspaceId, limit: $limit)';
  }
}

class _RecordingConversationRepository implements ConversationRepository {
  final workspaceWatchCalls = <_WorkspaceWatchCall>[];
  final _controllers = <StreamController<List<ConversationEntity>>>[];

  @override
  Stream<List<ConversationEntity>> watchConversationsByWorkspace(
    String workspaceId, {
    int? limit,
  }) {
    workspaceWatchCalls.add(
      _WorkspaceWatchCall(workspaceId: workspaceId, limit: limit),
    );

    late final StreamController<List<ConversationEntity>> controller;
    controller = StreamController<List<ConversationEntity>>(
      onCancel: () => _controllers.remove(controller),
    );
    _controllers.add(controller);
    return controller.stream;
  }

  Future<void> close() async {
    await Future.wait(
      _controllers
          .where((controller) => !controller.isClosed)
          .map((controller) => controller.close()),
    );
  }

  @override
  Future<ConversationEntity> createConversation(
    ConversationToCreate conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteConversation(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity?> getConversationById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ConversationEntity> patchConversation(
    String id,
    ConversationPatch conversation,
  ) {
    throw UnimplementedError();
  }

  @override
  Stream<ConversationEntity?> watchConversationById(String id) {
    throw UnimplementedError();
  }
}
