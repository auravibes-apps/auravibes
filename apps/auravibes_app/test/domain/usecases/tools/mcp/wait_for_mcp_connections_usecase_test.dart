import 'package:auravibes_app/domain/usecases/tools/mcp/wait_for_mcp_connections_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns immediately when no mcp ids', () async {
    const usecase = WaitForMcpConnectionsUseCase();
    var checked = false;

    await usecase.call(
      mcpServerIds: const [],
      timeout: const Duration(seconds: 1),
      isStillConnecting: () {
        checked = true;
        return true;
      },
    );

    expect(checked, isFalse);
  });

  test('stops when predicate becomes false', () async {
    const usecase = WaitForMcpConnectionsUseCase();
    var count = 0;

    await usecase.call(
      mcpServerIds: const ['m1'],
      timeout: const Duration(seconds: 1),
      isStillConnecting: () {
        count++;
        return count < 3;
      },
    );

    expect(count, greaterThanOrEqualTo(3));
  });
}
