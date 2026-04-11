import 'package:async/async.dart';
import 'package:langchain/langchain.dart';

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

abstract class NativeToolEntity<Input, Options, Output> {
  const NativeToolEntity();

  NativeToolType get type;

  ToolSpec getTool();

  CancelableOperation<Output> runner(Input toolInput);
}
