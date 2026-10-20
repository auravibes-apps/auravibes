import 'package:auravibes_app/features/chats/widgets/mcp_app_tool_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats app arguments and caps preview length', () {
    final formatted = formatMcpAppApprovalArguments({'target': 'file.txt'});
    final emoji = String.fromCharCodes([0x1f600]);
    final truncated = formatMcpAppApprovalArguments({'value': emoji * 3000});
    final ellipsis = String.fromCharCode(0x2026);

    expect(formatted, '{\n  "target": "file.txt"\n}');
    expect(truncated.runes.length, 2001);
    expect(truncated.endsWith(ellipsis), isTrue);
  });
}
