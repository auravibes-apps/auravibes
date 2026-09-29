import 'package:auravibes_app/widgets/sheets/adaptive_sheet_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('uses the glass sheet route on iOS without barrier blur', () {
    debugDefaultTargetPlatformOverride = .iOS;
    final route = const SizedBox().asAdaptiveSheetRoute<String>();

    expect(route, isA<StupidSimpleGlassSheetRoute<String>>());
    expect(
      (route as StupidSimpleGlassSheetRoute<String>).blurBehindBarrier,
      isFalse,
    );
  });

  test('uses the standard sheet route on non-iOS platforms', () {
    debugDefaultTargetPlatformOverride = .android;
    final route = const SizedBox().asAdaptiveSheetRoute<String>();

    expect(route, isA<StupidSimpleSheetRoute<String>>());
  });
}
