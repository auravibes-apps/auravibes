import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show BindingBase;
import 'package:flutter/services.dart' show ServicesBinding, rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/testing/ci_widget_test_timeout.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FlutterSecureStorage.setMockInitialValues({});
  WidgetController.hitTestWarningShouldBeFatal = true;
  configureCiWidgetTestTimeout();
  setUp(() {
    if (BindingBase.debugBindingType() == null) return;
    final binding = ServicesBinding.instance;
    if (binding is! TestDefaultBinaryMessengerBinding) return;

    binding.defaultBinaryMessenger.setMockStreamHandler(
      const .new('flutter_file_drop/events'),
      .inline(
        onListen: (_, events) {
          final _ = events;
        },
      ),
    );
  });
  setUpAll(() async {
    // Pure Dart tests need real HTTP, not the widget binding's HTTP 400.
    if (BindingBase.debugBindingType() == null) return;

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
