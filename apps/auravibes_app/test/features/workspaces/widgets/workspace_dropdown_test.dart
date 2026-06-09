import 'package:auravibes_app/features/workspaces/widgets/workspace_dropdown_item.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
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
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: Scaffold(body: Portal(child: child)),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      );
    }

    Future<void> _pumpWidget(WidgetTester tester, Widget child) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(_buildTestableWidget(child));
        await tester.idle();
        final _ = await tester.pumpAndSettle();
      });
    }

    testWidgets('renders with active workspace selected', (tester) async {
      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: workspaces,
          activeWorkspaceId: 'ws-2',
          onSelected: (_) {
            final _ = Object();
          },
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
          activeWorkspaceId: '',
          onSelected: (_) {
            final _ = Object();
          },
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
          onSelected: (_) {
            final _ = Object();
          },
        ),
      );

      expect(find.text('Select workspace'), findsOneWidget);
    });

    testWidgets('renders placeholder when workspaces empty', (tester) async {
      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: const [],
          activeWorkspaceId: '',
          onSelected: (_) {
            final _ = Object();
          },
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
      final onChanged = dropdown.onChanged;
      if (onChanged == null) {
        fail('Expected workspace dropdown onChanged callback');
      }

      onChanged(workspaces[1]);

      expect(selected, isNotNull);
      expect((selected ?? fail('Expected selected to be non-null')).id, 'ws-2');
    });

    testWidgets('is disabled when isLoading is true', (tester) async {
      await _pumpWidget(
        tester,
        WorkspaceDropdown(
          workspaces: workspaces,
          activeWorkspaceId: 'ws-1',
          onSelected: (_) {
            final _ = Object();
          },
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
          onSelected: (_) {
            final _ = Object();
          },
          errorLocalizationKey: LocaleKeys.workspace_management_switch_error,
        ),
      );

      expect(
        find.text('Failed to switch workspace. Please try again.'),
        findsOneWidget,
      );
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
