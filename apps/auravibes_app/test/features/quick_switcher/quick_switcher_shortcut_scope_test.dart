import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_editor_shortcut_scope.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_editor_toolbar.dart';
import 'package:auravibes_app/features/quick_switcher/models/quick_switcher_entry.dart';
import 'package:auravibes_app/features/quick_switcher/providers/quick_switcher_entries_provider.dart';
import 'package:auravibes_app/features/quick_switcher/widgets/quick_switcher_dialog.dart';
import 'package:auravibes_app/features/quick_switcher/widgets/quick_switcher_shortcut_scope.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<void> _sendKeyDown(WidgetTester tester, LogicalKeyboardKey key) async {
    final _ = await tester.sendKeyDownEvent(key);
  }

  Future<void> _sendKeyUp(WidgetTester tester, LogicalKeyboardKey key) async {
    final _ = await tester.sendKeyUpEvent(key);
  }

  Future<void> _pumpAndSettle(WidgetTester tester) async {
    final _ = await tester.pumpAndSettle();
  }

  Future<void> _openSwitcher(
    BuildContext context,
    ValueChanged<QuickSwitcherEntry?> onSelected,
  ) async {
    onSelected(
      await showDialog<QuickSwitcherEntry>(
        context: context,
        builder: (_) => const QuickSwitcherDialog(workspaceId: 'active'),
      ),
    );
  }

  Future<void> pumpScope(
    WidgetTester tester, {
    required TargetPlatform platform,
    required Widget child,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Theme(
            data: .new(platform: platform),
            child: QuickSwitcherShortcutScope(
              workspaceId: 'active',
              child: child,
            ),
          ),
          overrides: [
            quickSwitcherEntriesProvider('active').overrideWith(
              (_) async => const QuickSwitcherEntries(
                entries: [],
                hasUnavailableResults: false,
              ),
            ),
          ],
        ),
      );
    });
    await _pumpAndSettle(tester);
  }

  Future<void> sendShortcut(WidgetTester tester, {required bool meta}) async {
    final modifier = meta
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await _sendKeyDown(tester, modifier);
    await _sendKeyDown(tester, .keyK);
    await _sendKeyUp(tester, .keyK);
    await _sendKeyUp(tester, modifier);
    await _pumpAndSettle(tester);
  }

  testWidgets('uses Command on macOS and restores focus after dismissal', (
    tester,
  ) async {
    final originFocus = FocusNode();
    addTearDown(originFocus.dispose);
    await pumpScope(
      tester,
      platform: .macOS,
      child: TextButton(
        onPressed: originFocus.requestFocus,
        focusNode: originFocus,
        child: const Text('Origin'),
      ),
    );
    originFocus.requestFocus();
    await tester.pump();

    await sendShortcut(tester, meta: true);

    expect(find.text('Quick switcher'), findsOneWidget);
    await _sendKeyDown(tester, .escape);
    await _sendKeyUp(tester, .escape);
    await _pumpAndSettle(tester);
    expect(originFocus.hasFocus, isTrue);
  });

  testWidgets('uses Control on Windows', (tester) async {
    final originFocus = FocusNode();
    addTearDown(originFocus.dispose);
    await pumpScope(
      tester,
      platform: .windows,
      child: TextButton(
        onPressed: originFocus.requestFocus,
        focusNode: originFocus,
        child: const Text('Origin'),
      ),
    );
    originFocus.requestFocus();
    await tester.pump();

    await sendShortcut(tester, meta: false);

    expect(find.text('Quick switcher'), findsOneWidget);
  });

  testWidgets('opens when no child currently has focus', (tester) async {
    await pumpScope(tester, platform: .macOS, child: const SizedBox.shrink());

    await sendShortcut(tester, meta: true);

    expect(find.text('Quick switcher'), findsOneWidget);
  });

  testWidgets('selects results with arrows and Enter', (tester) async {
    final semantics = tester.ensureSemantics();
    const entries = [
      QuickSwitcherEntry(
        type: .agent,
        workspaceId: 'active',
        workspaceName: 'Workspace',
        title: 'First result',
        id: 'agent-1',
      ),
      QuickSwitcherEntry(
        type: .conversation,
        workspaceId: 'active',
        workspaceName: 'Workspace',
        title: 'Second result',
        id: 'conversation-2',
      ),
    ];
    QuickSwitcherEntry? selected;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => unawaited(
                _openSwitcher(context, (entry) {
                  selected = entry;
                }),
              ),
              child: const Text('Open launcher'),
            ),
          ),
          overrides: [
            quickSwitcherEntriesProvider('active').overrideWith(
              (_) async => const QuickSwitcherEntries(
                entries: entries,
                hasUnavailableResults: false,
              ),
            ),
          ],
        ),
      );
    });
    await _pumpAndSettle(tester);
    await tester.tap(find.text('Open launcher'));
    await _pumpAndSettle(tester);

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
      'Selected: First result, Agent - Workspace',
    );

    await _sendKeyDown(tester, .arrowDown);
    await _sendKeyUp(tester, .arrowDown);
    await tester.pump();
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey<String>('quick_switcher_selection_announcement'),
            ),
          )
          .label,
      'Selected: Second result, Conversation - Workspace',
    );
    await _sendKeyDown(tester, .enter);
    await _sendKeyUp(tester, .enter);
    await _pumpAndSettle(tester);

    expect(selected?.id, 'conversation-2');
    semantics.dispose();
  });

  testWidgets('selects first remaining result after results shrink', (
    tester,
  ) async {
    var entries = [
      for (var index = 0; index < 3; index++)
        QuickSwitcherEntry(
          type: .agent,
          workspaceId: 'active',
          workspaceName: 'Workspace',
          title: 'Result $index',
          id: 'agent-$index',
        ),
    ];
    QuickSwitcherEntry? selected;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => unawaited(
                _openSwitcher(context, (entry) {
                  selected = entry;
                }),
              ),
              child: const Text('Open launcher'),
            ),
          ),
          overrides: [
            quickSwitcherEntriesProvider('active').overrideWith(
              (_) async => QuickSwitcherEntries(
                entries: entries,
                hasUnavailableResults: false,
              ),
            ),
          ],
        ),
      );
    });
    await _pumpAndSettle(tester);
    await tester.tap(find.text('Open launcher'));
    await _pumpAndSettle(tester);

    for (var index = 0; index < 2; index++) {
      await _sendKeyDown(tester, .arrowDown);
      await _sendKeyUp(tester, .arrowDown);
    }
    await tester.pump();
    entries = entries.take(1).toList();
    ProviderScope.containerOf(tester.element(find.byType(QuickSwitcherDialog)))
        .invalidate(quickSwitcherEntriesProvider('active'));
    await _pumpAndSettle(tester);
    await _sendKeyDown(tester, .enter);
    await _sendKeyUp(tester, .enter);
    await _pumpAndSettle(tester);

    expect(selected?.id, 'agent-0');
  });

  testWidgets('keeps keyboard selection visible while moving down', (
    tester,
  ) async {
    final entries = [
      for (var index = 0; index < 12; index++)
        QuickSwitcherEntry(
          type: .agent,
          workspaceId: 'active',
          workspaceName: 'Workspace',
          title: 'Result $index',
          id: 'agent-$index',
        ),
    ];
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
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
          overrides: [
            quickSwitcherEntriesProvider('active').overrideWith(
              (_) async => QuickSwitcherEntries(
                entries: entries,
                hasUnavailableResults: false,
              ),
            ),
          ],
        ),
      );
    });
    await _pumpAndSettle(tester);
    await tester.tap(find.text('Open launcher'));
    await _pumpAndSettle(tester);

    for (var index = 0; index < 9; index++) {
      await _sendKeyDown(tester, .arrowDown);
      await _sendKeyUp(tester, .arrowDown);
    }
    await _pumpAndSettle(tester);

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
          overrides: [
            allWorkspacesProvider.overrideWith((_) {
              if (shouldFail) {
                return Stream<List<WorkspaceEntity>>.error(StateError('fail'));
              }

              return Stream.value(<WorkspaceEntity>[]);
            }),
          ],
        ),
      );
    });
    await _pumpAndSettle(tester);
    await tester.tap(find.text('Open launcher'));
    await _pumpAndSettle(tester);
    expect(find.text('Retry'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Retry'));
    await _pumpAndSettle(tester);

    expect(find.text('Retry'), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('shows empty state when query has no matches', (tester) async {
    final originFocus = FocusNode();
    addTearDown(originFocus.dispose);
    await pumpScope(
      tester,
      platform: .macOS,
      child: TextButton(
        onPressed: originFocus.requestFocus,
        focusNode: originFocus,
        child: const Text('Origin'),
      ),
    );
    originFocus.requestFocus();
    await tester.pump();
    await sendShortcut(tester, meta: true);
    await tester.enterText(find.byType(TextField), 'not found');
    await tester.pump();

    expect(find.text('No results found.'), findsOneWidget);
  });

  testWidgets('does not open over editable text focus', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await pumpScope(
      tester,
      platform: .macOS,
      child: TextField(focusNode: focusNode),
    );
    focusNode.requestFocus();
    await tester.pump();

    await sendShortcut(tester, meta: true);

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
      platform: .macOS,
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

    await sendShortcut(tester, meta: true);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Quick switcher'), findsNothing);
  });
}
