import 'dart:async';

import '../../../tool/testing/ci_widget_test_timeout.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  configureCiWidgetTestTimeout();
  await testMain();
}
