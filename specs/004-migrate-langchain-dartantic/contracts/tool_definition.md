# Contract: Tool Definition Interface

**Scope**: Tool system contract for AI-invoked capabilities  
**Consumer**: `ChatbotService`, `BuildCombinedToolSpecsUsecase`, MCP integration

---

## Interface

```dart
/// Abstract base for all tools exposed to the AI.
///
/// Tools are capabilities that the AI can invoke autonomously
/// during a conversation to perform actions or retrieve data.
abstract class ToolDefinition {
  /// Unique identifier for the tool (snake_case recommended)
  String get name;

  /// Human-readable description of what the tool does.
  /// This is shown to the AI to help it decide when to use the tool.
  String get description;

  /// JSON Schema describing the tool's input parameters.
  /// The AI uses this to generate valid tool call arguments.
  Map<String, dynamic> get inputSchema;

  /// Executes the tool with the given arguments.
  ///
  /// [args] - Map of argument names to values, validated against inputSchema
  /// Returns a map representing the tool result (serializable to JSON)
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args);
}
```

---

## Framework Mapping

### LangChain (Before)

```dart
// Schema definition
final toolSpec = ToolSpec(
  name: 'get_weather',
  description: 'Get weather for a location',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'location': {'type': 'string'},
    },
    'required': ['location'],
  },
);

// Executable tool
final tool = Tool.fromFunction<WeatherInput, WeatherOutput>(
  name: 'get_weather',
  description: 'Get weather for a location',
  inputJsonSchema: schema,
  func: (input) async => WeatherOutput(temp: 72),
);
```

### dartantic_ai (After)

```dart
// Unified tool definition
final tool = Tool(
  name: 'get_weather',
  description: 'Get weather for a location',
  inputSchema: Schema.fromMap({
    'type': 'object',
    'properties': {
      'location': {'type': 'string'},
    },
    'required': ['location'],
  }),
  onCall: (args) async => {'temp': 72, 'location': args['location']},
);
```

---

## Tool Categories

### 1. Built-in Tools

Tools shipped with the application (e.g., calculator, URL fetcher).

```dart
class CalculatorTool implements ToolDefinition {
  @override
  String get name => 'calculator';

  @override
  String get description => 'Perform mathematical calculations';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'expression': {'type': 'string'},
    },
    'required': ['expression'],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    // Implementation
  }
}
```

### 2. Native Tools

Platform-specific tools that require native capabilities.

**Contract**: Same interface as built-in tools, but may use platform channels or native APIs in `execute()`.

### 3. MCP Tools

Tools sourced from external Model Context Protocol servers.

**Contract**:

- MCP infrastructure remains unchanged (per FR-014)
- `ToolSpec` from MCP is converted to dartantic `Tool` at the boundary
- MCP connection manager handles server lifecycle independently

```dart
// Conversion at the boundary
List<Tool> convertMcpTools(List<ToolSpec> mcpSpecs) {
  return mcpSpecs.map((spec) => Tool(
    name: spec.name,
    description: spec.description,
    inputSchema: Schema.fromMap(spec.inputJsonSchema),
    onCall: (args) async => mcpClient.callTool(spec.name, args),
  )).toList();
}
```

---

## Invariants

1. **Tool names MUST be unique** within a conversation context
2. **Input schema MUST be valid JSON Schema** (draft-07 or later)
3. **Execute MUST be idempotent** where possible (safe to retry)
4. **Execute MUST NOT throw unhandled exceptions** — all errors returned as error maps
5. **Tool results MUST be JSON-serializable** (Map<String, dynamic> with primitive values)

---

## Error Contract

```dart
// Success result
{'result': '42', 'status': 'ok'}

// Error result (returned to AI, not thrown)
{'error': 'Division by zero', 'status': 'error'}
```

**Note**: Errors in tool execution are returned as results, not thrown. The AI receives the error context and decides how to respond.

---

## Schema Validation

The framework validates tool call arguments against `inputSchema` before calling `onCall`. If validation fails, the framework returns an error to the AI without invoking `onCall`.

---

## Performance Contract

- **Tool execution timeout**: 30 seconds default (configurable per tool)
- **Synchronous tools**: Should complete in <100ms
- **Async tools** (network): Should complete in <10s
- **Concurrent tool calls**: Supported by dartantic_ai framework
