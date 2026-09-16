import 'dart:async';

import 'package:auravibes_app/features/tools/widgets/mcp_error_details.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('copies redacted MCP errors and handles empty messages', (
    tester,
  ) async {
    final copiedTexts = <String?>[];
    final expectedRedacted = [
      'Connection failed',
      'Server: MCP Server',
      'Message: Authorization: Bearer [REDACTED]; api_key=[REDACTED]',
    ].join('\n');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedTexts.add((call.arguments as Map)['text'] as String?);
        }

        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      TestableApp(
        child: Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                key: const ValueKey('redacted-error'),
                onPressed: () => unawaited(
                  showMcpErrorDetails(
                    context,
                    groupName: 'MCP Server',
                    errorMessage:
                        'Authorization: Bearer replace-me; api_key=replace-me',
                  ),
                ),
                child: const Text('Redacted error'),
              ),
              TextButton(
                key: const ValueKey('empty-error'),
                onPressed: () => unawaited(
                  showMcpErrorDetails(
                    context,
                    groupName: 'MCP Server',
                    errorMessage: ' ',
                  ),
                ),
                child: const Text('Empty error'),
              ),
            ],
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    final _ = await tester.tap(find.byKey(const ValueKey('redacted-error')));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);

    final _ = await tester.tap(find.text('Copy'));
    final _ = await tester.pumpAndSettle();

    expect(copiedTexts, [expectedRedacted]);
    expect(copiedTexts.single, isNot(contains('replace-me')));
    expect(find.text('Error details copied'), findsOneWidget);

    final _ = await tester.pump(const Duration(seconds: 5));
    final _ = await tester.pumpAndSettle();
    final _ = await tester.tap(find.byKey(const ValueKey('empty-error')));
    final _ = await tester.pumpAndSettle();
    final _ = await tester.tap(find.text('Copy'));
    final _ = await tester.pumpAndSettle();

    expect(
      copiedTexts.last,
      'Connection failed\nServer: MCP Server\nMessage: Unknown error',
    );
  });
}
