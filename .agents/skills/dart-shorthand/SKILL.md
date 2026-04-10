---
name: dart-shorthand
description: Use when writing or reviewing Dart 3.11+ code and you want to apply dot shorthand syntax safely for enum values, constructors, and static members.
license: MIT
metadata:
  author: OpenCode
  version: "1.0.0"
  domain: dart
  triggers: Dart shorthand, dot shorthand, .new, enum shorthand, static member shorthand
  role: specialist
  scope: implementation
  output-format: code
  related-skills: dart-best-practices, flutter-expert
---

# Dart Shorthand

Use Dart dot shorthand syntax when the surrounding context type is clear and the shorter form improves readability.

Official reference: `https://dart.dev/language/dot-shorthands`

## When to Use This Skill

- Writing Dart 3.11+ code
- Refactoring repetitive enum prefixes such as `MyEnum.value`
- Initializing typed fields or locals with constructors like `.new()` or `.origin()`
- Using static members where the target type is obvious from context
- Reviewing code for shorthand opportunities without reducing clarity

## Preferred Uses

- Enum values in assignments, arguments, collection literals, and switch expressions
- Named and unnamed constructors when the variable, field, or return type is explicit
- Static methods and getters when the expected type is unambiguous

## Examples

```dart
enum Status { idle, loading, success, failure }

Status status = .idle;

switch (status) {
  case .idle:
  case .loading:
  case .success:
  case .failure:
}

final ScrollController controller = .new();
final GlobalKey<FormState> formKey = .new();

int port = .parse('8080');
```

## Rules

- Only use dot shorthand when the context type is immediately clear to the reader and compiler.
- Prefer shorthand for enums; this is the strongest and clearest use case.
- Use `.new()` for unnamed constructors only when the declared type is visible nearby.
- Use shorthand in `const` expressions when the target constructor or enum value is const.
- Fall back to the explicit type if shorthand makes the code harder to scan.

## Limitations

- Requires language version 3.10 or later.
- An expression statement cannot start with `.`.
- Equality checks are asymmetric: shorthand must be on the right side of `==` or `!=`.
- Shorthand depends on context type, so avoid it where inference is weak, indirect, or surprising.
- Be careful in chained expressions; the whole expression still has to satisfy the original context type.

## Review Checklist

- Is the expected type obvious at the usage site?
- Is the shorthand shorter without being less readable?
- Would an explicit type be clearer for someone unfamiliar with the code?
- Does the file already use shorthand consistently?
- Is the code running with Dart 3.10+ semantics?
