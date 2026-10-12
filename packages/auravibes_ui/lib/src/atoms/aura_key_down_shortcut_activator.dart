import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A shortcut activator that matches one logical-key-down event.
///
/// Modifiers are intentionally ignored so migrating a handler to Shortcuts
/// does not introduce or remove modifier combinations.
class AuraKeyDownShortcutActivator extends ShortcutActivator {
  /// Creates an activator for one logical key.
  const new(this.key);

  /// The logical key to match.
  final LogicalKeyboardKey key;

  @override
  Iterable<LogicalKeyboardKey> get triggers => [key];

  @override
  bool accepts(KeyEvent event, HardwareKeyboard _) =>
      event is KeyDownEvent && event.logicalKey == key;

  @override
  String debugDescribeKeys() => key.keyLabel;
}
