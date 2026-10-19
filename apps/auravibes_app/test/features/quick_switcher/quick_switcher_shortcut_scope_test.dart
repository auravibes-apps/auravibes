import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_editor_shortcut_scope.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_editor_toolbar.dart';
import 'package:auravibes_app/features/quick_switcher/models/quick_switcher_entry.dart';
import 'package:auravibes_app/features/quick_switcher/providers/quick_switcher_entries_provider.dart';
import 'package:auravibes_app/features/quick_switcher/widgets/quick_switcher_shortcut_scope.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<void> pumpScope(
    WidgetTester tester, {
    required TargetPlatform platform,
    required Widget child,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          overrides: [
            quickSwitcherEntriesProvider('active').overrideWith(
              (_) async => const QuickSwitcherEntries(
                entries: [],
                hasUnavailableResults: false,
              ),
            ),
          ],
          child: Theme(
            data: ThemeData(platform: platform),
            child: QuickSwitcherShortcutScope(
              workspaceId: 'active',
              child: child,
            ),
          ),
        ),
      );
    });
    await tester.pumpAndSettle();
  }

  Future<void> sendShortcut(
    WidgetTester tester, {
    required bool meta,
    required bool control,
  }) async {
    final modifier = meta
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(modifier);
    await tester.pumpAndSettle();
  }

  testWidgets('uses Command on macOS and restores focus after dismissal', (
    tester,
  ) async {
    final originFocus = FocusNode();
    addTearDown(originFocus.dispose);
    await pumpScope(
      tester,
      platform: TargetPlatform.macOS,
      child: TextButton(
        focusNode: originFocus,
        onPressed: () {},
        child: const Text('Origin'),
      ),
    );
    originFocus.requestFocus();
    await tester.pump();

    await sendShortcut(tester, meta: true, control: false);

    expect(find.text('Quick switcher'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(originFocus.hasFocus, isTrue);
  });

  testWidgets('uses Control on Windows', (tester) async {
    final originFocus = FocusNode();
    addTearDown(originFocus.dispose);
    await pumpScope(
      tester,
      platform: TargetPlatform.windows,
      child: TextButton(
        focusNode: originFocus,
        onPressed: () {},
        child: const Text('Origin'),
      ),
    );
    originFocus.requestFocus();
    await tester.pump();

    await sendShortcut(tester, meta: false, control: true);

    expect(find.text('Quick switcher'), findsOneWidget);
  });

  testWidgets('opens when no child currently has focus', (tester) async {
    await pumpScope(
      tester,
      platform: TargetPlatform.macOS,
      child: const SizedBox.shrink(),
    );

    await sendShortcut(tester, meta: true, control: false);

    expect(find.text('Quick switcher'), findsOneWidget);
  });

  testWidgets('selects results with arrows and Enter', (tester) async {
    final semantics = tester.ensureSemantics();
    const entries = [
      QuickSwitcherEntry(
        type: QuickSwitcherEntryType.agent,
        id: 'agent-1',
        workspaceId: 'active',
        workspaceName: 'Workspace',
        title: 'First result',
      ),
      QuickSwitcherEntry(
        type: QuickSwitcherEntryType.conversation,
        id: 'conversation-2',
        workspaceId: 'active',
        workspaceName: 'Workspace',
        title: 'Second result',
      ),
    ];
    QuickSwitcherEntry? selected;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          overrides: [
            quickSwitcherEntriesProvider('active').overrideWith(
              (_) async => const QuickSwitcherEntries(
                entries: entries,
                hasUnavailableResults: false,
              ),
            ),
          ],
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showDialog<QuickSwitcherEntry>(
                  context: context,
                  builder: (_) =>
                      const QuickSwitcherDialog(workspaceId: 'active'),
                );
              },
              child: const Text('Open launcher'),
            ),
          ),
        ),
      );
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open launcher'));
    await tester.pumpAndSettle();

    final selectionAnnouncement = tester.getSemantics(
      find.byKey(
        const ValueKey<String>('quick_switcher_selection_announcement'),
      ),
    );
    expect(
      selectionAnnouncement.getSemanticsData().flagsCollection.isLiveRegion,
      isTrue,
    );
    expect(
      selectionAnnouncement.label,
      'Selected: First result, Agent · Workspace',
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey<String>('quick_switcher_selection_announcement'),
            ),
          )
          .label,
      'Selected: Second result, Conversation · Workspace',
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected?.id, 'conversation-2');
    semantics.dispose();
  });

  testWidgets('selects first remaining result after results shrink', (
    tester,
  ) async {
    var entries = [
      for (var index = 0; index < 3; index++)
        QuickSwitcherEntry(
          type: QuickSwitcherEntryType.agent,
          id: 'agent-$index',
          workspaceId: 'active',
          workspaceName: 'Workspace',
          title: 'Result $index',
        ),
    ];
    QuickSwitcherEntry? selected;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          overrides: [
            quickSwitcherEntriesProvider('active').overrideWith(
              (_) async => QuickSwitcherEntries(
                entries: entries,
                hasUnavailableResults: false,
              ),
            ),
          ],
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showDialog<QuickSwitcherEntry>(
                  context: context,
                  builder: (_) =>
                      const QuickSwitcherDialog(workspaceId: 'active'),
                );
              },
              child: const Text('Open launcher'),
            ),
          ),
        ),
      );
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open launcher'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 2; index++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.pump();
    entries = [entries.first];
    ProviderScope.containerOf(tester.element(find.byType(QuickSwitcherDialog)))
        .invalidate(quickSwitcherEntriesProvider('active'));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected?.id, 'agent-0');
  });

  testWidgets('keeps keyboard selection visible while moving down', (
    tester,
  ) async {
    final entries = [
      for (var index = 0; index < 12; index++)
        QuickSwitcherEntry(
          type: QuickSwitcherEntryType.agent,
          id: 'agent-$index',
          workspaceId: 'active',
          workspaceName: 'Workspace',
          title: 'Result $index',
        ),
    ];
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          overrides: [
            quickSwitcherEntriesProvider('active').overrideWith(
              (_) async => QuickSwitcherEntries(
                entries: entries,
                hasUnavailableResults: false,
              ),
            ),
          ],
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<QuickSwitcherEntry>(
                context: context,
                builder: (_) =>
                    const QuickSwitcherDialog(workspaceId: 'active'),
              ),
              child: const Text('Open launcher'),
            ),
          ),
        ),
      );
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open launcher'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 9; index++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.pumpAndSettle();

    final listRect = tester.getRect(find.byType(ListView));
    final selectedRect = tester.getRect(
      find.ancestor(of: find.text('Result 9'), matching: find.byType(ListTile)),
    );
    expect(selectedRect.top, greaterThanOrEqualTo(listRect.top));
    expect(selectedRect.bottom, lessThanOrEqualTo(listRect.bottom));
  });

  testWidgets('retry refreshes failed workspace list source', (tester) async {
    var shouldFail = true;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          overrides: [
            allWorkspacesProvider.overrideWith((_) {
              if (shouldFail) {
                return Stream<List<WorkspaceEntity>>.error(StateError('fail'));
              }
              return Stream.value(<WorkspaceEntity>[]);
            }),
          ],
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<QuickSwitcherEntry>(
                context: context,
                builder: (_) =>
                    const QuickSwitcherDialog(workspaceId: 'active'),
              ),
              child: const Text('Open launcher'),
            ),
          ),
        ),
      );
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open launcher'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('shows empty state when query has no matches', (tester) async {
    final originFocus = FocusNode();
    addTearDown(originFocus.dispose);
    await pumpScope(
      tester,
      platform: TargetPlatform.macOS,
      child: TextButton(
        focusNode: originFocus,
        onPressed: () {},
        child: const Text('Origin'),
      ),
    );
    originFocus.requestFocus();
    await tester.pump();
    await sendShortcut(tester, meta: true, control: false);
    await tester.enterText(find.byType(TextField), 'not found');
    await tester.pump();

    expect(find.text('No results found.'), findsOneWidget);
  });

  testWidgets('does not open over editable text focus', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await pumpScope(
      tester,
      platform: TargetPlatform.macOS,
      child: TextField(focusNode: focusNode),
    );
    focusNode.requestFocus();
    await tester.pump();

    await sendShortcut(tester, meta: true, control: false);

    expect(find.text('Quick switcher'), findsNothing);
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('preserves the focused Markdown editor Command-K shortcut', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Documentation');
    final focusNode = FocusNode();
    final shortcutController = MarkdownEditorShortcutController();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 13);
    await pumpScope(
      tester,
      platform: TargetPlatform.macOS,
      child: MarkdownEditorShortcutScope(
        controller: shortcutController,
        focusNode: focusNode,
        enabled: true,
        child: Column(
          children: [
            TextField(controller: controller, focusNode: focusNode),
            MarkdownEditorToolbar(
              controller: controller,
              focusNode: focusNode,
              shortcutController: shortcutController,
            ),
          ],
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    await sendShortcut(tester, meta: true, control: false);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Quick switcher'), findsNothing);
  });
}
