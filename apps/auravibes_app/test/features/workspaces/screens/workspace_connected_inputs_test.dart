import 'dart:convert';

import 'package:auravibes_app/features/workspaces/widgets/workspace_connected_inputs.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final width in [400.0, 1200.0]) {
    testWidgets('trusted primitive inputs need no JSON at $width', (
      tester,
    ) async {
      tester.view.physicalSize = .new(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController(text: '{"obsolete":true}');
      addTearDown(controller.dispose);
      await _mount(
        tester,
        WorkspaceConnectedInputs(tool: _tool, controller: controller),
      );
      final query = find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput &&
            widget.identifier == 'workspace_connected_input_query',
      );
      expect(query, findsOneWidget);
      await tester.tap(find.text('Remove extra inputs'));
      final _ = await tester.pumpAndSettle();
      expect(jsonDecode(controller.text), isEmpty);
      expect(find.text('Inputs (JSON)'), findsNothing);
      await tester.enterText(query, 'records');
      await tester.tap(find.text('More options'));
      final _ = await tester.pumpAndSettle();
      final count = find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput &&
            widget.identifier == 'workspace_connected_input_count',
      );
      await tester.enterText(count, '7');
      final amount = find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput &&
            widget.identifier == 'workspace_connected_input_amount',
      );
      await tester.enterText(amount, '2.5');
      final boolean = find.byWidgetPredicate(
        (widget) =>
            widget is AuraDropdownSelector<String> &&
            widget.identifier == 'workspace_connected_input_archived',
      );
      await tester.tap(boolean);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Yes').last);
      final _ = await tester.pumpAndSettle();
      final order = find.byWidgetPredicate(
        (widget) =>
            widget is AuraDropdownSelector<String> &&
            widget.identifier == 'workspace_connected_input_order',
      );
      await tester.tap(order);
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('descending').last);
      final _ = await tester.pumpAndSettle();
      final values = jsonDecode(controller.text) as Map<String, dynamic>;
      expect(values, {
        'query': 'records',
        'count': 7,
        'archived': true,
        'amount': 2.5,
        'order': 'descending',
      });
      validateToolArguments(
        Map<String, Object?>.from(_tool.inputJsonSchema),
        values,
      );
      await tester.enterText(count, 'invalid number');
      expect(
        () => validateToolArguments(
          Map<String, Object?>.from(_tool.inputJsonSchema),
          jsonDecode(controller.text) as Map<String, dynamic>,
        ),
        throwsFormatException,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets('complex inputs stay in advanced JSON at $width', (
      tester,
    ) async {
      tester.view.physicalSize = .new(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController(text: '{}');
      addTearDown(controller.dispose);
      await _mount(
        tester,
        WorkspaceConnectedInputs(tool: _complex, controller: controller),
      );
      expect(find.text('Advanced inputs'), findsOneWidget);
      expect(find.byType(AuraInput), findsNothing);
      await tester.tap(find.text('Advanced inputs'));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(AuraInput), '{"filters":["active"]}');
      final values = jsonDecode(controller.text) as Map<String, dynamic>;
      validateToolArguments(
        Map<String, Object?>.from(_complex.inputJsonSchema),
        values,
      );
      expect(values, {
        'filters': ['active'],
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<void> _mount(WidgetTester tester, Widget child) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(child: SingleChildScrollView(child: child)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });
  final _ = await tester.pumpAndSettle();
}

const _tool = ConnectorToolDefinition(
  slug: 'read',
  title: 'Read',
  description: 'Read',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'query': {'type': 'string', 'title': 'Search'},
      'count': {'type': 'integer', 'title': 'Count'},
      'amount': {'type': 'number', 'title': 'Amount'},
      'archived': {'type': 'boolean', 'title': 'Include archived'},
      'order': {
        'type': 'string',
        'enum': ['ascending', 'descending'],
      },
    },
    'required': ['query'],
    'additionalProperties': false,
  },
);

const _complex = ConnectorToolDefinition(
  slug: 'complex',
  title: 'Read',
  description: 'Read',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'filters': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
    'required': ['filters'],
    'additionalProperties': false,
  },
);
