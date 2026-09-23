import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.environment['CI'] == 'true') {
    EasyLocalization.logger.enableLevels = EasyLocalization.logger.enableLevels
        .where((level) => level.name == 'warning' || level.name == 'error')
        .toList();
  }

  await testMain();
}
