import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show BindingBase;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
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
