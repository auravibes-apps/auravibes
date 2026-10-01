import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:auravibes_app/widgets/sheets/adaptive_sheet_route.dart';
import 'package:material_ui/material_ui.dart';

typedef MarkdownEditorOptions = ({
  String initialMarkdown,
  int? maxCharacters,
  String titleKey,
  String draftHintKey,
});

abstract final class MarkdownEditorLauncher {
  static Future<String?> show(
    BuildContext context, {
    required MarkdownEditorOptions options,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();

    return _pushEditor(context, _buildEditor(options));
  }

  static MarkdownEditorScreen _buildEditor(MarkdownEditorOptions options) =>
      MarkdownEditorScreen(
        initialMarkdown: options.initialMarkdown,
        maxCharacters: options.maxCharacters,
        titleKey: options.titleKey,
        draftHintKey: options.draftHintKey,
      );

  static Future<String?> _pushEditor(
    BuildContext context,
    MarkdownEditorScreen editor,
  ) =>
      Navigator.of(context).push<String>(editor.asAdaptiveSheetRoute<String>());
}
// Top-level API/provider declarations are required by their consumers.
