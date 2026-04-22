# Quickstart: LangChain → dartantic_ai Migration

**Date**: 2026-04-21  
**Feature**: Migrate AI Orchestration Framework

---

## Prerequisites

- Flutter SDK 3.41.4+ (via FVM)
- Dart 3.11+
- Melos configured (`fvm dart run melos bootstrap`)
- All existing tests passing on current branch

---

## Migration Steps

### Step 1: Update Dependencies

In `apps/auravibes_app/pubspec.yaml`:

**Remove**:

```yaml
langchain: ^0.8.1
langchain_anthropic: ^0.3.0+1
langchain_openai: ^0.8.1
```

**Add**:

```yaml
dartantic_ai: ^3.4.0
```

Run:

```bash
fvm flutter pub get
```

### Step 2: Migrate ChatbotService

Replace `BaseChatModel` initialization with `Agent` creation:

**Before**:

```dart
final model = ChatOpenAI(
  apiKey: decryptedKey,
  defaultOptions: ChatOpenAIOptions(model: modelId, tools: toolSpecs),
);
```

**After**:

```dart
final agent = Agent(
  'openai:$modelId',
  tools: tools, // List<Tool>
);
```

For custom endpoints:

```dart
final provider = OpenAIProvider(
  apiKey: decryptedKey,
  baseUrl: Uri.parse(customUrl),
  headers: customHeaders,
);
final agent = Agent.forProvider(provider);
```

### Step 3: Migrate Message Conversion

**Before**:

```dart
ChatMessage.humanText(content);
ChatMessage.ai(content: content, toolCalls: calls);
ChatMessage.tool(content, toolCallId: id);
```

**After**:

```dart
ChatMessage.user(content);
ChatMessage.assistant(content, toolCalls: calls);
ChatMessage.tool(content, toolCallId: id);
```

### Step 4: Migrate Tool Definitions

**Before**:

```dart
final toolSpec = ToolSpec(
  name: 'get_weather',
  description: 'Get weather',
  inputJsonSchema: {'type': 'object', 'properties': {...}},
);
final tool = Tool.fromFunction<Input, Output>(
  name: 'get_weather',
  description: 'Get weather',
  inputJsonSchema: schema,
  func: (input) async => {...},
);
```

**After**:

```dart
final tool = Tool(
  name: 'get_weather',
  description: 'Get weather',
  inputSchema: Schema.fromMap({'type': 'object', 'properties': {...}}),
  onCall: (args) async => {'temp': 72},
);
```

### Step 5: Migrate Streaming

**Before**:

```dart
final stream = model.stream(PromptValue.chat(messages));
await for (final chunk in stream) {
  final text = chunk.outputAsString;
  final usage = chunk.usage;
}
```

**After**:

```dart
final stream = agent.sendStream(prompt, history: messages);
await for (final chunk in stream) {
  final text = chunk.output;
  final usage = chunk.usage;
}
```

### Step 6: Migrate Token Usage Extraction

No changes needed — `LanguageModelUsage` structure is the same:

```dart
final usage = result.usage;
print('Prompt: ${usage.promptTokens}');
print('Response: ${usage.responseTokens}');
print('Total: ${usage.totalTokens}');
```

### Step 7: Update Tests

1. Remove LangChain-specific mocks
2. Add dartantic_ai-specific test utilities
3. Verify all existing assertions still pass

Run tests:

```bash
fvm flutter test --no-pub
```

### Step 8: Validate

```bash
# Format
fvm dart format --set-exit-if-changed .

# Analyze
fvm dart analyze --fatal-infos

# Tests
fvm flutter test

# Full validation
fvm dart run melos run validate
```

---

## Verification Checklist

- [ ] All LangChain imports removed
- [ ] dartantic_ai imports added
- [ ] `Agent` created for all provider types
- [ ] Custom URLs configured via `OpenAIProvider`
- [ ] Messages converted to dartantic `ChatMessage`
- [ ] Tools converted to dartantic `Tool`
- [ ] Streaming uses `agent.sendStream()`
- [ ] Token usage extracted from `ChatResult.usage`
- [ ] 100% existing tests pass
- [ ] New targeted tests added
- [ ] Zero analysis warnings
- [ ] No performance regression (>10%)
