import 'package:auravibes_server/src/features/model_connections/domain/virtual_workspace_model_selection.dart';
import 'package:test/test.dart';

void main() {
  test('virtual selection IDs are deterministic and unambiguous', () {
    final id = VirtualWorkspaceModelSelectionId.encode(
      connectionId: 'connection:alpha',
      modelId: 'model/one',
    );

    expect(id, matches(RegExp(r'^wms1\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$')));
    expect(
      VirtualWorkspaceModelSelectionId.encode(
        connectionId: 'connection:alpha',
        modelId: 'model/one',
      ),
      id,
    );
    expect(
      VirtualWorkspaceModelSelectionId.encode(
        connectionId: 'a',
        modelId: 'bc',
      ),
      isNot(
        VirtualWorkspaceModelSelectionId.encode(
          connectionId: 'ab',
          modelId: 'c',
        ),
      ),
    );
    final decoded = VirtualWorkspaceModelSelectionId.tryDecode(id);
    expect(decoded?.connectionId, 'connection:alpha');
    expect(decoded?.modelId, 'model/one');
  });

  test('virtual selection IDs reject malformed and incomplete values', () {
    expect(VirtualWorkspaceModelSelectionId.tryDecode('selection'), isNull);
    expect(VirtualWorkspaceModelSelectionId.tryDecode('wms1.%%%'), isNull);
    expect(
      VirtualWorkspaceModelSelectionId.tryDecode('wms1.WyIiLCJtb2RlbCJd'),
      isNull,
    );
  });
}
