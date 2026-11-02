import 'package:auravibes_app/data/repositories/browser_session_repository.dart';
import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists browser tabs separately for each conversation', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = BrowserSessionRepository(
      await SharedPreferences.getInstance(),
    );
    const firstSession = BrowserSessionState(
      tabs: [BrowserTab(id: 'first', url: 'https://example.com')],
      activeTabId: 'first',
    );
    const secondSession = BrowserSessionState(
      tabs: [BrowserTab(id: 'second', url: 'https://example.org')],
      activeTabId: 'second',
    );

    await repository.save('conversation-a', firstSession);
    await repository.save('conversation-b', secondSession);

    expect(
      (await repository.load('conversation-a')).toJson(),
      firstSession.toJson(),
    );
    expect(
      (await repository.load('conversation-b')).toJson(),
      secondSession.toJson(),
    );
  });

  test('loads new and empty conversations without a browser tab', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = BrowserSessionRepository(
      await SharedPreferences.getInstance(),
    );

    final session = await repository.load('conversation');
    await repository.save('conversation', session);
    final restored = await repository.load('conversation');

    expect(session.tabs, isEmpty);
    expect(session.activeTabId, isEmpty);
    expect(restored.tabs, isEmpty);
    expect(restored.activeTab, isNull);
  });

  test('restores workspace tabs and selection with its conversation', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = BrowserSessionRepository(
      await SharedPreferences.getInstance(),
    );
    const session = BrowserSessionState(
      tabs: [],
      activeTabId: '',
      workspaceTabs: [
        WorkspaceContentTab(id: 'table-1', kind: 'table'),
        WorkspaceContentTab(id: 'workflow-1', kind: 'workflow'),
        WorkspaceContentTab(id: '', kind: 'directory'),
      ],
      selectedWorkspaceTabId: 'workflow:workflow-1',
    );

    await repository.save('conversation', session);

    final restored = await repository.load('conversation');
    expect(
      restored.workspaceTabs.map((tab) => tab.toJson()).toList(),
      session.workspaceTabs.map((tab) => tab.toJson()).toList(),
    );
    expect(restored.selectedWorkspaceTabId, 'workflow:workflow-1');
  });

  test('recovers from malformed persisted browser state', () async {
    SharedPreferences.setMockInitialValues({
      'browser_session_conversation': '{"tabs":[{"id":1}]}',
    });
    final repository = BrowserSessionRepository(
      await SharedPreferences.getInstance(),
    );

    final session = await repository.load('conversation');

    expect(session.tabs, isEmpty);
    expect(session.activeTab, isNull);
  });
}
