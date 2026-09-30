import 'package:auravibes_server/src/features/mcp_servers/mcp_server_headers.dart';
import 'package:test/test.dart';

void main() {
  test(
    'accepts safe configured headers and rejects request control headers',
    () {
      expect(parseMcpHttpHeaders('{"X-API-Key":"secret"}'), {
        'X-API-Key': 'secret',
      });
      expect(
        () => parseMcpHttpHeaders('{"Host":"evil.example"}'),
        throwsFormatException,
      );
      expect(
        () => parseMcpHttpHeaders('{"X-Key":"secret\\r\\nHost: evil"}'),
        throwsFormatException,
      );
    },
  );
}
