import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:auravibes_app/widgets/sheets/adaptive_sheet_route.dart';
import 'package:material_ui/material_ui.dart';

abstract final class MarkdownEditorLauncher {
  static Future<String?> show(
    BuildContext context, {
    required String initialMarkdown,
    int? maxCharacters,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();

    final editor = MarkdownEditorScreen(
      initialMarkdown: initialMarkdown,
      maxCharacters: maxCharacters,
    );

    return Navigator.of(context)
        .push<String>(editor.asAdaptiveSheetRoute<String>());
  }
}
// Top-level API/provider declarations are required by their consumers.
