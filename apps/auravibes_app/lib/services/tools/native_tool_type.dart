// Required: Existing test and UI helpers keep compact return flow.
import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart' show ToolSpec;

enum NativeToolType(final String value) {
  url('url');

  static NativeToolType? fromValue(String value) {
    for (final enumVariant in NativeToolType.values) {
      if (enumVariant.value == value) return enumVariant;
    }

    return null;
  }
}

abstract class const NativeToolEntity<Input, Output>() {
  NativeToolType get type;

  ToolSpec getTool();

  CancelableOperation<Output> runner(Input toolInput);
}
