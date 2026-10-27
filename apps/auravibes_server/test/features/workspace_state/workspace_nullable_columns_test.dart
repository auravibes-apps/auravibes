import 'dart:convert';

import 'package:auravibes_server/src/features/workspace_state/domain/workspace_resource_validation.dart';
import 'package:auravibes_server/src/features/workspace_state/domain/workspace_table_constraints.dart';
import 'package:auravibes_server/src/features/workspace_state/domain/workspace_table_schema_identity.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'legacy required schemas are nullable and new writes normalize flags',
    () {
      final schema = <String, Object?>{
        'id': 'table',
        'name': 'Table',
        'labelColumnId': 'label',
        'schemaRevision': 1,
        'columns': [
          {
            'id': 'label',
            'name': 'Name',
            'type': 'text',
            'required': true,
            'unique': true,
          },
        ],
      };
      expect(
        () => WorkspaceTableConstraints.records(schema, [
          <String, Object?>{},
          {'label': null},
          {'label': null},
        ]),
        returnsNormally,
      );
      final decoded = WorkspaceResourceValidation.decode(
        kind: WorkspaceResourceKind.table,
        resourceId: 'table',
        workspaceId: 1,
        data: jsonEncode(schema),
      );
      expect((decoded['columns'] as List).single['required'], isFalse);
      expect(WorkspaceTableSchemaIdentity.matches(schema, decoded), isTrue);
      expect(((schema['columns'] as List).single as Map)['required'], isTrue);
    },
  );
}
