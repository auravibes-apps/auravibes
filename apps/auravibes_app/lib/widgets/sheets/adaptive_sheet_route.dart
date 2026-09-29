import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// Creates a platform-adaptive modal sheet route for this widget.
extension AdaptiveSheetRoute on Widget {
  /// Builds an iOS glass sheet or a standard sheet on other platforms.
  Route<T> asAdaptiveSheetRoute<T>() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return StupidSimpleGlassSheetRoute<T>(
        child: this,
        blurBehindBarrier: false,
      );
    }

    return StupidSimpleSheetRoute<T>(child: this);
  }
}
