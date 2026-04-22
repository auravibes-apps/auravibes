import 'package:async/async.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';

enum UserToolType {
  calculator('calculator')
  ;

  const UserToolType(this.value);
  static UserToolType? fromValue(String value) {
    for (final enumVariant in UserToolType.values) {
      if (enumVariant.name == value) return enumVariant;
    }
    return null;
  }

  final String value;
}

/// Represents an available tool in the app
abstract class UserToolEntity<Input, Options, Output> {
  const UserToolEntity();

  /// Type identifier for the tool
  UserToolType get type;

  ToolSpec getTool();

  CancelableOperation<Output> runner(Input toolInput);
}
