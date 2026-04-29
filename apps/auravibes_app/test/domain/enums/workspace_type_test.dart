import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceType', () {
    group('value', () {
      test('local value is local', () {
        expect(WorkspaceType.local.value, 'local');
      });
      test('remote value is remote', () {
        expect(WorkspaceType.remote.value, 'remote');
      });
    });

    test('toString returns value', () {
      expect(WorkspaceType.local.toString(), 'local');
      expect(WorkspaceType.remote.toString(), 'remote');
    });

    group('isLocal', () {
      test('local returns true', () {
        expect(WorkspaceType.local.isLocal, isTrue);
      });
      test('remote returns false', () {
        expect(WorkspaceType.remote.isLocal, isFalse);
      });
    });

    group('isRemote', () {
      test('remote returns true', () {
        expect(WorkspaceType.remote.isRemote, isTrue);
      });
      test('local returns false', () {
        expect(WorkspaceType.local.isRemote, isFalse);
      });
    });

    group('fromString', () {
      test('parses local', () {
        expect(WorkspaceType.fromString('local'), WorkspaceType.local);
      });
      test('parses remote', () {
        expect(WorkspaceType.fromString('remote'), WorkspaceType.remote);
      });
      test('is case-insensitive', () {
        expect(WorkspaceType.fromString('LOCAL'), WorkspaceType.local);
        expect(WorkspaceType.fromString('Remote'), WorkspaceType.remote);
      });
      test('throws for invalid value', () {
        expect(() => WorkspaceType.fromString('invalid'), throwsArgumentError);
      });
    });
  });
}
