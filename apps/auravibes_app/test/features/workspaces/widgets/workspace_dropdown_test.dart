import 'package:auravibes_app/features/workspaces/widgets/workspace_dropdown.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceDropdown', () {
    const workspaces = [
      WorkspaceDropdownItem(id: 'ws-1', name: 'Workspace A'),
      WorkspaceDropdownItem(id: 'ws-2', name: 'Workspace B'),
      WorkspaceDropdownItem(id: 'ws-3', name: 'Workspace C'),
    ];

    Widget _buildTestableWidget(Widget child) {
      return EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useFallbackTranslations: true,
        useOnlyLangCode: true,
        child: Builder(
          builder: (context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(body: Portal(child: child)),
            );
          },
        ),
      );
    }

    Future<void> _pumpWidget(WidgetTester tester, Widget child) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildTestableWidget(child));
      });
      await tester.pump();
    }

    testWidgets('renders with active workspace selected', (tester) async {
      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: workspaces,
          activeWorkspaceId: 'ws-2',
          onSelected: (_) {},
        ),
      );

      expect(find.text('Workspace B'), findsOneWidget);
    });

    testWidgets('renders placeholder when no active workspace', (
      tester,
    ) async {
      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: workspaces,
          activeWorkspaceId: null,
          onSelected: (_) {},
        ),
      );

      expect(find.text('Select workspace'), findsOneWidget);
    });

    testWidgets('renders placeholder when active workspace not found', (
      tester,
    ) async {
      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: workspaces,
          activeWorkspaceId: 'ws-unknown',
          onSelected: (_) {},
        ),
      );

      expect(find.text('Select workspace'), findsOneWidget);
    });

    testWidgets('renders placeholder when workspaces empty', (tester) async {
      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: const [],
          activeWorkspaceId: null,
          onSelected: (_) {},
        ),
      );

      expect(find.text('Select workspace'), findsOneWidget);
    });

    testWidgets('calls onSelected when selection changes', (tester) async {
      WorkspaceDropdownItem? selected;

      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: workspaces,
          activeWorkspaceId: 'ws-1',
          onSelected: (item) => selected = item,
        ),
      );

      final dropdown = tester
          .widget<AuraDropdownSelector<WorkspaceDropdownItem>>(
            find.byType(AuraDropdownSelector<WorkspaceDropdownItem>),
          );
      dropdown.onChanged!(workspaces[1]);

      expect(selected, isNotNull);
      expect(selected!.id, 'ws-2');
    });

    testWidgets('is disabled when isLoading is true', (tester) async {
      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: workspaces,
          activeWorkspaceId: 'ws-1',
          onSelected: (_) {},
          isLoading: true,
        ),
      );

      final dropdown = tester
          .widget<AuraDropdownSelector<WorkspaceDropdownItem>>(
            find.byType(AuraDropdownSelector<WorkspaceDropdownItem>),
          );
      expect(dropdown.onChanged, isNull);
    });

    testWidgets('displays error message', (tester) async {
      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: workspaces,
          activeWorkspaceId: 'ws-1',
          onSelected: (_) {},
          errorLocalizationKey: 'Switch failed',
        ),
      );

      expect(find.text('Switch failed'), findsOneWidget);
    });

    test('WorkspaceDropdownItem equality uses id only', () {
      const item1 = WorkspaceDropdownItem(id: 'ws-1', name: 'Name A');
      const item2 = WorkspaceDropdownItem(id: 'ws-1', name: 'Name B');
      const item3 = WorkspaceDropdownItem(id: 'ws-2', name: 'Name A');

      expect(item1, item2);
      expect(item1.hashCode, item2.hashCode);
      expect(item1, isNot(equals(item3)));
    });
  });
}
