import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/ux_validation_fixture.dart';

const _captureDirectory = String.fromEnvironment('UX_CAPTURE_DIR');
const _captureStage = String.fromEnvironment('UX_CAPTURE_STAGE');
const _sourceFingerprint = String.fromEnvironment('UX_SOURCE_FINGERPRINT');
const _flutterVersion = String.fromEnvironment('UX_FLUTTER_VERSION');
const _viewport = Size(1440, 1000);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  tearDownAll(UxValidationFixture.closeDatabase);

  testWidgets('workspace ChatsRoute label organization capture', (
    tester,
  ) async {
    expect(_captureStage, isNotEmpty);
    expect(_sourceFingerprint, isNotEmpty);
    expect(_flutterVersion, isNotEmpty);

    final fixture = await UxValidationFixture.create();
    final labelTable = await fixture.database.customSelect('''
    SELECT name FROM sqlite_master
    WHERE type = 'table' AND name = 'conversation_labels'
    ''').get();
    if (labelTable.isNotEmpty) {
      await fixture.database.customStatement(
        'INSERT INTO conversation_labels '
        '(id, workspace_id, name, normalized_name) '
        'VALUES (?, ?, ?, ?)',
        ['capture-label-review', fixture.workspaceId, 'Review', 'review'],
      );
      await fixture.database.customStatement(
        'INSERT INTO conversation_labels '
        '(id, workspace_id, name, normalized_name) '
        'VALUES (?, ?, ?, ?)',
        [
          'capture-label-follow-up',
          fixture.workspaceId,
          'Follow up',
          'follow up',
        ],
      );
      await fixture.database.customStatement(
        'INSERT INTO conversation_label_assignments '
        '(id, workspace_id, conversation_id, label_id) '
        'VALUES (?, ?, ?, ?)',
        [
          'capture-assignment-review',
          fixture.workspaceId,
          fixture.chatId,
          'capture-label-review',
        ],
      );
      await fixture.database.customStatement(
        'INSERT INTO conversation_label_assignments '
        '(id, workspace_id, conversation_id, label_id) '
        'VALUES (?, ?, ?, ?)',
        [
          'capture-assignment-follow-up',
          fixture.workspaceId,
          fixture.chatId,
          'capture-label-follow-up',
        ],
      );
    }

    final _ = await fixture.pump(
      tester,
      '/workspaces/${fixture.workspaceId}/chats',
      size: _viewport,
      useProductionRouter: true,
    );
    expect(find.byKey(const ValueKey('ux-capture')), findsOneWidget);

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('ux-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory(_captureDirectory);
        final _ = await directory.create(recursive: true);
        const stem = 'conversation-labels-';
        const filename = '$stem$_captureStage';
        final _ = await File('${directory.path}/$filename.png').writeAsBytes(
          (bytes ?? (throw StateError('PNG encoding failed'))).buffer
              .asUint8List(),
        );
        final _ = await File('${directory.path}/$filename.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'feature': 'workspace-scoped conversation labels',
            'stage': _captureStage,
            'sourceFingerprint': _sourceFingerprint,
            'route': '/workspaces/${fixture.workspaceId}/chats',
            'fixture':
                'Production ChatsRoute with two local conversations; '
                'the feature stage assigns Review and Follow up to the '
                'first chat.',
            'flutterVersion': _flutterVersion,
            'renderer': 'Flutter widget-test Skia, ${Platform.operatingSystem}',
            'viewport': [_viewport.width, _viewport.height],
            'devicePixelRatio': 1,
            'locale': 'en',
            'textScale': 1,
            'theme': 'light',
            'accentHue': 186.0,
            'flavor': 'production route under UxValidationFixture',
            'disableAnimations': true,
            'fontLimitations':
                'Widget-test fonts and rendering; native '
                'system typography and assistive technology are not '
                'represented.',
          }),
        );
      } finally {
        image.dispose();
      }
    });
    await fixture.close(tester);
  }, // Capture output is opt-in for UX review.
    skip: _captureDirectory.isEmpty,
  );
}
