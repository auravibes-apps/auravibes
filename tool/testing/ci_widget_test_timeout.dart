import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void configureCiWidgetTestTimeout() {
  if (Platform.environment['CI'] != 'true') return;

  AutomatedTestWidgetsFlutterBinding.ensureInitialized().defaultTestTimeout =
      const Timeout(.new(seconds: 30));
}
