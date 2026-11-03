import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_labels_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/chats/providers/conversation_labels_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_labels_repository_provider.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_labels_widgets.dart';
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

  late AppDatabase database;
  late ConversationLabelsRepository repository;
  late String workspaceId;

  setUp(() async {
    database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    repository = ConversationLabelsRepository(database);
    workspaceId = (await database.workspaceDao.insertWorkspace(
      .insert(name: 'Workspace', type: WorkspaceType.local),
    )).id;
  });

  tearDown(() => database.close());

  Widget buildSubject({
    required Widget child,
    Locale startLocale = const Locale('en'),
  }) => TestableApp(
    child: Material(child: child),
    workspaceId: workspaceId,
    startLocale: startLocale,
    overrides: [
      conversationLabelsRepositoryProvider.overrideWithValue(repository),
    ],
  );

  Future<void> pumpSubject(
    WidgetTester tester, {
    required Widget child,
    Locale startLocale = const Locale('en'),
  }) async {
    await tester.runAsync(
      () => tester.pumpWidget(
        buildSubject(child: child, startLocale: startLocale),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('label badges expose one localized semantic label', (
    tester,
  ) async {
    final labels = [
      _label('urgent', 'Urgent'),
      _label('planning', 'Planning'),
    ];
    await pumpSubject(
      tester,
      child: conversationLabelBadges(labels),
      startLocale: const Locale('es'),
    );

    final urgentBadge = find.byKey(const ValueKey('conversation-label-urgent'));
    final planningBadge = find.byKey(
      const ValueKey('conversation-label-planning'),
    );
    expect(urgentBadge, findsOneWidget);
    expect(planningBadge, findsOneWidget);
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey('conversation-labels-semantics')),
      ).label,
      'Etiquetas de conversación: Urgent, Planning',
    );
    expect(
      tester.widget<AuraBadge>(urgentBadge).variant,
      AuraBadgeVariant.neutral,
    );
  });

  testWidgets('filter supports OR selection and applies selected labels', (
    tester,
  ) async {
    final urgent = await repository.createLabel(
      workspaceId: workspaceId,
      name: 'Urgent',
    );
    final planning = await repository.createLabel(
      workspaceId: workspaceId,
      name: 'Planning',
    );
    Set<String>? applied;

    await pumpSubject(
      tester,
      child: ConversationLabelsToolbar(
        workspaceId: workspaceId,
        selectedLabelIds: const {},
        onSelectedLabelIdsChanged: (value) => applied = value,
      ),
    );

    await tester.tap(find.text(LocaleKeys
        .chats_screens_conversation_labels_filter
        .tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urgent'));
    await tester.tap(find.text('Planning'));
    await tester.tap(
      find.text(LocaleKeys.chats_screens_conversation_labels_apply.tr()),
    );
    await tester.pumpAndSettle();

    expect(applied, {urgent.id, planning.id});
  });

  testWidgets('management creates a shared workspace label', (tester) async {
    await pumpSubject(
      tester,
      child: ConversationLabelsToolbar(
        workspaceId: workspaceId,
        selectedLabelIds: const {},
        onSelectedLabelIdsChanged: (_) {},
      ),
    );

    await tester.tap(
      find.text(LocaleKeys.chats_screens_conversation_labels_manage.tr()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Follow up');
    await tester.tap(find.byTooltip(
      LocaleKeys.chats_screens_conversation_labels_create.tr(),
    ));
    await tester.pumpAndSettle();

    expect(
      (await repository.watchLabelsByWorkspace(workspaceId).first)
          .map((label) => label.name),
      ['Follow up'],
    );
  });

  testWidgets('assignment saves label selection for its conversation', (
    tester,
  ) async {
    final label = await repository.createLabel(
      workspaceId: workspaceId,
      name: 'Important',
    );
    final row = await database.conversationDao.insertConversation(
      .insert(workspaceId: workspaceId, title: 'Chat'),
    );

    await pumpSubject(
      tester,
      child: _AssignmentLauncher(
        workspaceId: workspaceId,
        conversation: ConversationEntity(
          id: row.id,
          title: row.title,
          workspaceId: workspaceId,
          isPinned: false,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      ),
    );

    await tester.tap(find.text('Assign labels'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Important'));
    await tester.tap(
      find.text(LocaleKeys
          .chats_screens_conversation_labels_save_assignments
          .tr()),
    );
    await tester.pumpAndSettle();

    final conversation = await repository
        .watchConversationsByWorkspace(workspaceId)
        .first;
    expect(conversation.single.labels.map((value) => value.id), [label.id]);
  });
}

ConversationLabelEntity _label(String id, String name) =>
    ConversationLabelEntity(
      id: id,
      workspaceId: 'ws',
      name: name,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

class const _AssignmentLauncher({
  required final String workspaceId,
  required final ConversationEntity conversation,
}) extends ConsumerWidget {
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
