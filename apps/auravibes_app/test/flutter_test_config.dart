import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  if (Platform.environment['CI'] == 'true') {
    EasyLocalization.logger.enableLevels = EasyLocalization.logger.enableLevels
        .where((level) => level.name == 'warning' || level.name == 'error')
        .toList();
  }

  final _ = await Future.wait([
    rootBundle.loadString('assets/i18n/en.json'),
    rootBundle.loadString('assets/i18n/es.json'),
  ]);

  await testMain();
}
