import 'package:async/async.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:math_expressions/math_expressions.dart';

/// Represents an available tool in the app
final class CalculatorTool extends UserToolEntity<String, Object, String> {
  const CalculatorTool();

  @override
  ToolSpec getTool() {
    return const ToolSpec(
      name: 'calculator',
      description:
          'Useful for getting the result of a math expression '
          'that could be executed by a simple calculator.',
      inputJsonSchema: {
        'type': 'object',
        'properties': {
          'input': {
            'type': 'string',
            'description':
                'A valid mathematical expression to evaluate. '
                'For example: "(x^2 + cos(y)) / 3".',
          },
        },
        'required': ['input'],
      },
    );
  }

  @override
  CancelableOperation<String> runner(String toolInput) {
    final parser = GrammarParser();
    final evaluator = RealEvaluator();
    return CancelableOperation.fromFuture(
      Future(() {
        try {
          final exp = parser.parse(toolInput);
          return evaluator.evaluate(exp).toString();
        } on Exception catch (_) {
          return "I don't know how to do that.";
        }
      }),
    );
  }

  @override
  UserToolType get type => UserToolType.calculator;
}
