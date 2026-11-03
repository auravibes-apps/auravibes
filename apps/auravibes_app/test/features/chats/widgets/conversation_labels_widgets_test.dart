import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_labels_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/providers/conversation_labels_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_labels_repository_provider.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_label_badges.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_labels_toolbar.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  AppDatabase? _database;
  ConversationLabelsRepository? _repository;
  String? _workspaceId;

  AppDatabase database() => _database!;
  ConversationLabelsRepository repository() => _repository!;
  String workspaceId() => _workspaceId!;

  setUp(() async {
    _database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    _repository = ConversationLabelsRepository(database());
    _workspaceId = (await database().workspaceDao.insertWorkspace(
      .insert(name: 'Workspace', type: WorkspaceType.local),
    )).id;
  });

  tearDown(() async {
    await database().close();
    _database = null;
    _repository = null;
    _workspaceId = null;
  });

  Widget buildSubject({
    required Widget child,
    Locale startLocale = const Locale('en'),
    List<Object> overrides = const [],
  }) => TestableApp(
    child: Scaffold(body: child),
    overrides: [
      conversationLabelsRepositoryProvider.overrideWithValue(repository()),
      ...overrides,
    ],
    workspaceId: workspaceId(),
    startLocale: startLocale,
  );

  Future<void> pumpSubject(
    WidgetTester tester, {
    required Widget child,
    Locale startLocale = const Locale('en'),
    List<Object> overrides = const [],
  }) async {
    await tester.runAsync(
      () => tester.pumpWidget(
        buildSubject(
          child: child,
          startLocale: startLocale,
          overrides: overrides,
        ),
      ),
    );
    await _pumpAnimation(tester);
    await _waitForTranslation(
      tester,
      LocaleKeys.chats_screens_conversation_labels_filter,
    );
  }

  testWidgets('label badges expose one localized semantic label', (
    tester,
  ) async {
    final labels = [_label('urgent', 'Urgent'), _label('planning', 'Planning')];
    await pumpSubject(
      tester,
      child: ConversationLabelBadges(labels: labels),
      startLocale: const Locale('es'),
    );

    final urgentBadge = find.byKey(const ValueKey('conversation-label-urgent'));
    final planningBadge = find.byKey(
      const ValueKey('conversation-label-planning'),
    );
    expect(urgentBadge, findsOneWidget);
    expect(planningBadge, findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('conversation-labels-semantics')),
          )
          .label,
      'Etiquetas de conversaci\u00F3n: Urgent, Planning',
    );
    expect(
      tester.widget<AuraBadge>(urgentBadge).variant,
      .neutral,
    );
  });

  testWidgets('filter supports OR selection and applies selected labels', (
    tester,
  ) async {
    final urgent = await repository().createLabel(
      workspaceId: workspaceId(),
      name: 'Urgent',
    );
    final planning = await repository().createLabel(
      workspaceId: workspaceId(),
      name: 'Planning',
    );
    Set<String>? applied;

    await pumpSubject(
      tester,
      child: ConversationLabelsToolbar(
        workspaceId: workspaceId(),
        selectedLabelIds: const {},
        onSelectedLabelIdsChanged: (value) => applied = value,
      ),
      overrides: [
        conversationLabelsStreamProvider(workspaceId())
            .overrideWith((_) => Stream.value([urgent, planning])),
      ],
    );

    await _waitForCondition(
      tester,
      () => !tester.widget<AuraButton>(find.byType(AuraButton).first).disabled,
    );
    await tester.tap(
      find.text(LocaleKeys.chats_screens_conversation_labels_filter.tr()),
    );
    await _pumpAnimation(tester);
    await _waitForText(tester, 'Urgent');
    await tester.tap(find.text('Urgent'));
    await tester.pump();
    await tester.tap(find.text('Planning'));
    await tester.pump();
    await tester.tap(
      find.text(LocaleKeys.chats_screens_conversation_labels_apply.tr()),
    );
    await _pumpAnimation(tester);

    expect(applied, {urgent.id, planning.id});
  });

  testWidgets('management creates a shared workspace label', (tester) async {
    await pumpSubject(
      tester,
      child: ConversationLabelsToolbar(
        workspaceId: workspaceId(),
        selectedLabelIds: const {},
        onSelectedLabelIdsChanged: (_) => fail('No filter change expected'),
      ),
      overrides: [
        conversationLabelsStreamProvider(
          workspaceId(),
        ).overrideWith((_) => Stream.value(const <ConversationLabelEntity>[])),
      ],
    );

    await tester.tap(
      find.text(LocaleKeys.chats_screens_conversation_labels_manage.tr()),
    );
    await _pumpAnimation(tester);
    await tester.enterText(find.byType(TextField), 'Follow up');
    await tester.tap(
      find.byTooltip(LocaleKeys.chats_screens_conversation_labels_create.tr()),
    );
    await _pumpAnimation(tester);

    expect(
      (await (database().select(
            database().conversationLabels,
          )..where((label) => label.workspaceId.equals(workspaceId()))).get())
          .map((label) => label.name)
          .toList(),
      ['Follow up'],
    );
  });

  testWidgets('assignment saves label selection for its conversation', (
    tester,
  ) async {
    final label = await repository().createLabel(
      workspaceId: workspaceId(),
      name: 'Important',
    );
    final row = await database().conversationDao.insertConversation(
      .insert(workspaceId: workspaceId(), title: 'Chat'),
    );

    await pumpSubject(
      tester,
      child: _AssignmentLauncher(
        workspaceId: workspaceId(),
        conversation: ConversationEntity(
          id: row.id,
          title: row.title,
          workspaceId: workspaceId(),
          isPinned: false,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      ),
      overrides: [
        conversationLabelsStreamProvider(workspaceId())
            .overrideWith((_) => Stream.value([label])),
      ],
    );

    await tester.tap(find.text('Assign labels'));
    await _pumpAnimation(tester);
    await _waitForText(tester, 'Important');
    await tester.tap(find.text('Important'));
    await tester.pump();
    await tester.tap(
      find.text(
        LocaleKeys.chats_screens_conversation_labels_save_assignments.tr(),
      ),
    );
    await _pumpAnimation(tester);
    expect(find.byType(AlertDialog), findsNothing);

    final assignments = await (database().select(
      database().conversationLabelAssignments,
    )..where((assignment) => assignment.conversationId.equals(row.id))).get();
    expect(assignments.map((assignment) => assignment.labelId).toList(), [
      label.id,
    ]);
  });
}

ConversationLabelEntity _label(String id, String name) =>
    ConversationLabelEntity(
      id: id,
      workspaceId: 'ws',
      name: name,
      createdAt: .utc(2026),
      updatedAt: .utc(2026),
    );

Future<void> _pumpAnimation(WidgetTester tester) async {
  await tester.pump();
  // Drift's native database and EasyLocalization's asset loader complete on
  // the real async loop rather than the widget test's fake clock.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _waitForTranslation(
  WidgetTester tester,
  String localizationKey,
) async {
  final _ = await tester.runAsync(() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (localizationKey.trExists()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  expect(localizationKey.trExists(), isTrue);
}

Future<void> _waitForText(WidgetTester tester, String value) async {
  await _waitForCondition(tester, () => find.text(value).evaluate().isNotEmpty);

  expect(find.text(value), findsOneWidget);
}

Future<void> _waitForCondition(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }

  expect(condition(), isTrue);
}

class _AssignmentLauncher extends ConsumerWidget {
  const _AssignmentLauncher({
    required this.workspaceId,
    required this.conversation,
  });

  final String workspaceId;
  final ConversationEntity conversation;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    onPressed: () => showConversationLabelAssignmentDialog(
      context,
      workspaceId: workspaceId,
      conversation: conversation,
      actions: ref.read(conversationLabelActionsProvider),
    ),
    child: const Text('Assign labels'),
  );
}
