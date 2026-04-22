import 'package:async/async.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';

enum NativeToolType {
  url('url')
  ;

  const NativeToolType(this.value);

  static NativeToolType? fromValue(String value) {
    for (final enumVariant in NativeToolType.values) {
      if (enumVariant.value == value) return enumVariant;
    }
    return null;
  }

  final String value;
}

abstract class NativeToolEntity<Input, Output> {
  const NativeToolEntity();

  NativeToolType get type;

  ToolSpec getTool();

  CancelableOperation<Output> runner(Input toolInput);
}
