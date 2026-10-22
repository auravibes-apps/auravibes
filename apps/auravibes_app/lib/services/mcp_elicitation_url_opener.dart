import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_elicitation_url_opener.g.dart';

@riverpod
McpElicitationUrlOpener mcpElicitationUrlOpener(Ref _) =>
    const McpElicitationUrlOpener();

class const McpElicitationUrlOpener() {
  Future<void> open(Uri url) => OpenSystemBrowser.call(url);
}
