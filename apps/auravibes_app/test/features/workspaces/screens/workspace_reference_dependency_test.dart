import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_dependency.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_reference_field.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('configuration offers only compatible single-reference fields', (
    tester,
  ) async {
    String? parent;
    String? match;
    await tester.pumpWidget(
      TestableApp(
        child: HookBuilder(
          builder: (context) {
            final parentValue = useState<String?>(null);
            final matchValue = useState<String?>(null);
            parent = parentValue.value;
            match = matchValue.value;

            return WorkspaceReferenceDependency(
              workspaceId: 'one',
              table: _source,
              columnId: 'dependent',
              targetTableId: 'target',
              parent: parentValue,
              match: matchValue,
              disabled: false,
            );
          },
        ),
        overrides: [
          workspaceTableProvider(
            'one',
            'target',
          ).overrideWith((ref) async => _target),
        ],
        workspaceId: 'one',
      ),
    );
    await _flush(tester);
    await tester.tap(find.text('No dependent filter'));
    await _flush(tester);
    expect(find.text('Source group'), findsOneWidget);
    expect(find.text('Many groups'), findsNothing);
    expect(find.text('Already dependent'), findsNothing);
    await tester.tap(find.text('Source group'));
    await _flush(tester);
    expect(parent, 'parent');
    await tester.tap(find.text('No dependent filter'));
    await _flush(tester);
    expect(find.text('Matching group'), findsOneWidget);
    expect(find.text('Other group type'), findsNothing);
    expect(find.text('Multiple groups'), findsNothing);
    await tester.tap(find.text('Matching group'));
    await _flush(tester);
    expect(match, 'matching');
    await tester.tap(find.text('Source group'));
    await _flush(tester);
    await tester.tap(find.text('No dependent filter'));
    await _flush(tester);
    expect(parent, isNull);
    expect(match, isNull);
    expect(find.text('Matching field in target table'), findsNothing);
  });
  testWidgets(
    'missing parent explains recovery and disables related selection',
    (tester) async {
      await tester.pumpWidget(
        TestableApp(
          child: WorkspaceReferenceField(
            workspaceId: 'one',
            table: _source,
            column: _source.columns.last,
            value: null,
            disabled: false,
            restricted: false,
            onChanged: (_) => fail('Disabled field must not change'),
            onUnset: () => fail('Empty field must not unset'),
          ),
          workspaceId: 'one',
        ),
      );
      await _flush(tester);
      expect(
        find.text('Select a parent before choosing related records.'),
        findsOneWidget,
      );
      final button = tester.widget<AuraButton>(
        find.ancestor(
          of: find.text('Choose records'),
          matching: find.byType(AuraButton),
        ),
      );
      expect(button.disabled, isTrue);
    },
  );
}

const _source = WorkspaceTable(
  id: 'source',
  name: 'Source',
  labelColumnId: 'label',
  columns: [
    WorkspaceColumn(id: 'label', name: 'Name'),
    WorkspaceColumn(
      id: 'parent',
      name: 'Source group',
      type: .reference,
      targetTableId: 'groups',
    ),
    WorkspaceColumn(
      id: 'many',
      name: 'Many groups',
      type: .reference,
      targetTableId: 'groups',
      referenceMultiple: true,
    ),
    WorkspaceColumn(
      id: 'chained',
      name: 'Already dependent',
      type: .reference,
      targetTableId: 'groups',
      dependsOnColumnId: 'parent',
      targetMatchColumnId: 'matching',
    ),
    WorkspaceColumn(
      id: 'dependent',
      name: 'Selected',
      type: .reference,
      targetTableId: 'target',
      dependsOnColumnId: 'parent',
      targetMatchColumnId: 'matching',
    ),
  ],
  revision: 1,
  schemaRevision: 1,
);
const _target = WorkspaceTable(
  id: 'target',
  name: 'Target',
  labelColumnId: 'label',
  columns: [
    WorkspaceColumn(id: 'label', name: 'Name'),
    WorkspaceColumn(
      id: 'matching',
      name: 'Matching group',
      type: .reference,
      targetTableId: 'groups',
    ),
    WorkspaceColumn(
      id: 'other',
      name: 'Other group type',
      type: .reference,
      targetTableId: 'other',
    ),
    WorkspaceColumn(
      id: 'many',
      name: 'Multiple groups',
      type: .reference,
      targetTableId: 'groups',
      referenceMultiple: true,
    ),
  ],
  revision: 1,
  schemaRevision: 1,
);

Future<void> _flush(WidgetTester tester) async {
  for (var index = 0; index < 5; index++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  final _ = await tester.pumpAndSettle();
}
