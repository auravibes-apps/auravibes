import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:flutter/material.dart';

abstract final class MarkdownEditorLauncher {
  static Future<String?> show(
    BuildContext context, {
    required String initialMarkdown,
    int? maxCharacters,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => MarkdownEditorScreen(
          initialMarkdown: initialMarkdown,
          maxCharacters: maxCharacters,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}
// Top-level API/provider declarations are required by their consumers.
