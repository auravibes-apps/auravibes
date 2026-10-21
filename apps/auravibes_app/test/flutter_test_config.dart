import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show BindingBase;
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:irondash_message_channel/irondash_message_channel.dart';
import 'package:super_native_extensions/src/native/context.dart'
    show superNativeExtensionsContext;

import '../../../tool/testing/ci_widget_test_timeout.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  configureCiWidgetTestTimeout();
  setUpAll(() async {
    // Pure Dart tests need real HTTP, not the widget binding's HTTP 400.
    if (BindingBase.debugBindingType() == null) return;

    final nativeContext = superNativeExtensionsContext;
    if (nativeContext is MockMessageChannelContext) {
      nativeContext
        ..registerMockMethodCallHandler('DropManager', (_) async => null)
        ..registerMockMethodCallHandler('DragManager', (call) async {
          return switch (call.method) {
            'needsCombinedDragImage' => false,
            'startDrag' => 0,
            _ => null,
          };
        });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.irondash.engine_context'),
            (_) async => 1,
          );
    }

    final _ = await TestWidgetsFlutterBinding.instance.runAsync(() async {
      expect(await rootBundle.loadString('assets/i18n/en.json'), isNotEmpty);
      expect(await rootBundle.loadString('assets/i18n/es.json'), isNotEmpty);
    });
  });
  if (Platform.environment['CI'] == 'true') {
    EasyLocalization.logger.enableLevels = EasyLocalization.logger.enableLevels
        .where((level) => level.name == 'warning' || level.name == 'error')
        .toList();
  }

  await testMain();
}
