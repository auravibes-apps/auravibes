import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:dartantic_ai/dartantic_ai.dart';

typedef ToolCallHandler =
    Future<Map<String, dynamic>> Function(
      String toolName,
      Map<String, dynamic> args,
    );

class ToolAdapter {
  const ToolAdapter();

  List<Tool> call(
    List<ToolSpec> specs, {
    required ToolCallHandler onCall,
  }) {
    return specs
        .map(
          (spec) => _convertTool(spec, onCall: onCall),
        )
        .toList();
  }

  Tool _convertTool(
    ToolSpec spec, {
    required ToolCallHandler onCall,
  }) {
    return Tool(
      name: spec.name,
      description: spec.description,
      inputSchema: Schema.fromMap(
        spec.inputJsonSchema.cast<String, Object?>(),
      ),
      onCall: (args) {
        if (args is! Map<String, dynamic>) {
          throw ArgumentError(
            'Tool "${spec.name}" received non-map args: ${args.runtimeType}',
          );
        }
        return onCall(spec.name, Map<String, dynamic>.from(args));
      },
    );
  }
}
