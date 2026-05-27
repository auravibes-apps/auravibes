// ignore_for_file: avoid-returning-widgets
// Required: Widget tests use helpers that build widgets under test.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: avoid-redundant-async
// Required: Test callbacks intentionally preserve async-compatible signatures.
// ignore_for_file: scoped_providers_should_specify_dependencies
// Required: widget tests override scoped providers directly.

import 'package:auravibes_app/features/tools/providers/mcp_form_state.dart';
import 'package:auravibes_app/features/tools/widgets/add_mcp_modal.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_provider_scope.dart';

class _FakeMcpConnectionNotifier extends McpConnectionNotifier {
  @override
  List<McpConnectionState> build() => [];
}

class _FakeMcpFormNotifier extends McpFormNotifier {
  @override
  McpFormState build(String workspaceId) => const McpFormState();
}

class _SubmittingMcpFormNotifier extends McpFormNotifier {
  @override
  McpFormState build(String workspaceId) =>
      const McpFormState(isSubmitting: true);
}

const _wsId = 'ws1';

Widget _buildSubject() {
  return EasyLocalization(
    child: TestProviderScope(
      overrides: [
        mcpConnectionProvider.overrideWith(_FakeMcpConnectionNotifier.new),
        // ignore: deprecated_member_use
        mcpFormProvider.overrideWith(_FakeMcpFormNotifier.new),
      ],
      child: Portal(
        child: Builder(
          builder: (context) {
            return MaterialApp(
              home: Theme(
                data: ThemeData(extensions: [AuraTheme.light]),
                child: const Scaffold(body: SizedBox.shrink()),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            );
          },
        ),
      ),
    ),
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );
}

Future<void> _pumpAndInit(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
  });
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _showDialog(WidgetTester tester) async {
  await tester.runAsync(() async {
    AddMcpModal.show(
      tester.element(find.byType(Scaffold)),
      workspaceId: _wsId,
    );
  });
  await tester.pump();
  await tester.pump();
}

void main() {
  test('constructor stores workspaceId', () {
    const modal = AddMcpModal(workspaceId: _wsId);
    expect(modal.workspaceId, _wsId);
  });

  group('AddMcpModal', () {
    testWidgets('show opens a dialog', (tester) async {
      await _pumpAndInit(tester, _buildSubject());
      await _showDialog(tester);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(AddMcpModal), findsOneWidget);
    });

    testWidgets('renders header with extension icon', (tester) async {
      await _pumpAndInit(tester, _buildSubject());
      await _showDialog(tester);

      expect(find.byIcon(Icons.extension), findsOneWidget);
    });

    testWidgets('renders close button in header', (tester) async {
      await _pumpAndInit(tester, _buildSubject());
      await _showDialog(tester);

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await _pumpAndInit(tester, _buildSubject());
      await _showDialog(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.byType(AddMcpModal), findsNothing);
    });

    testWidgets('renders cancel and save buttons', (tester) async {
      await _pumpAndInit(tester, _buildSubject());
      await _showDialog(tester);

      expect(find.byType(AuraButton), findsNWidgets(2));
    });

    testWidgets('cancel button dismisses dialog', (tester) async {
      await _pumpAndInit(tester, _buildSubject());
      await _showDialog(tester);

      await tester.tap(find.byType(AuraButton).first);
      await tester.pump();

      expect(find.byType(AddMcpModal), findsNothing);
    });

    testWidgets('renders form input fields', (tester) async {
      await _pumpAndInit(tester, _buildSubject());
      await _showDialog(tester);

      expect(find.byType(AuraInput), findsAtLeast(2));
    });

    testWidgets('dialog renders with correct structure', (tester) async {
      await _pumpAndInit(tester, _buildSubject());
      await _showDialog(tester);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows loading overlay when submitting', (tester) async {
      await _pumpAndInit(
        tester,
        EasyLocalization(
          child: TestProviderScope(
            overrides: [
              mcpConnectionProvider.overrideWith(
                _FakeMcpConnectionNotifier.new,
              ),
              // ignore: deprecated_member_use
              mcpFormProvider.overrideWith(_SubmittingMcpFormNotifier.new),
            ],
            child: Portal(
              child: Builder(
                builder: (context) {
                  return MaterialApp(
                    home: Theme(
                      data: ThemeData(extensions: [AuraTheme.light]),
                      child: const Scaffold(body: SizedBox.shrink()),
                    ),
                    locale: context.locale,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                  );
                },
              ),
            ),
          ),
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          useOnlyLangCode: true,
          useFallbackTranslations: true,
        ),
      );
      await _showDialog(tester);

      expect(find.byType(AuraLoadingOverlay), findsOneWidget);
    });
  });
}
