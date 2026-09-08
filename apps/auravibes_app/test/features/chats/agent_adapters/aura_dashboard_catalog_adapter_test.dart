import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('binding cannot resolve to another binding object', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: ChatA2uiSurfaceHost.historical(
            messageId: 'invalid-bound-value',
            payloads: _fixture(form: false, progress: {'path': '/missing'}),
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );
    await tester.pump();
    expect(find.text('This UI could not be loaded.'), findsOneWidget);
    expect(find.byType(AuraChart), findsOneWidget);
    expect(find.byType(AuraLinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('bound companion form submits edited answers', (tester) async {
    final runtime = ChatA2uiRuntime(conversationId: 'form-test', enabled: true)
      ..bindMessage('answer');
    addTearDown(runtime.dispose);
    for (final operation in [
      {
        'createSurface': {
          'surfaceId': 'form',
          'catalogId': a2uiChatFormCatalogId,
        },
      },
      {
        'updateDataModel': {
          'surfaceId': 'form',
          'path': '/',
          'value': {
            'team': 'a',
            'query': '',
            'milestone': false,
            'start': '2026-09-01',
            'end': '2026-09-30',
          },
        },
      },
      {
        'updateComponents': {
          'surfaceId': 'form',
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['team', 'search', 'start', 'end', 'milestone'],
            },
            {
              'id': 'team',
              'component': 'ChoicePicker',
              'label': 'Team',
              'presentation': 'chips',
              'value': {'path': '/team'},
              'options': [
                {'value': 'a', 'label': 'Alpha'},
                {'value': 'b', 'label': 'Beta'},
              ],
            },
            {
              'id': 'search',
              'component': 'TextField',
              'label': 'Search',
              'value': {'path': '/query'},
            },
            {
              'id': 'start',
              'component': 'DateTimeInput',
              'variant': 'date',
              'label': 'Start',
              'value': {'path': '/start'},
            },
            {
              'id': 'end',
              'component': 'DateTimeInput',
              'variant': 'date',
              'label': 'End',
              'value': {'path': '/end'},
            },
            {
              'id': 'milestone',
              'component': 'CheckBox',
              'label': 'Ready',
              'value': {'path': '/milestone'},
            },
          ],
        },
      },
    ]) {
      final message = {'version': a2uiChatWireVersion, ...operation};
      runtime.addMessageJson(
        A2uiChatContract.encodeEnvelope(
          message,
          interactionMode: 'requiresUserAction',
        ),
      );
    }
    runtime.commitCurrentMessage();
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SingleChildScrollView(
            child: ChatA2uiSurfaceHost.message(
              runtime: runtime,
              messageId: 'answer',
              payloads: runtime.messagesFor('answer'),
            ),
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );
    await tester.pump();
    expect(runtime.requiresUserAction, isTrue);
    await tester.tap(find.text('Beta'));
    await tester.enterText(find.byType(TextField).first, 'release');
    await tester.tap(find.byType(AuraCheckbox));
    await tester.pump();
    final action = runtime.actions.first;
    await tester.tap(find.byKey(const ValueKey('a2ui_submit_answer:form')));
    final submitted = await action;
    expect(submitted.answers, containsPair('team', 'b'));
    expect(submitted.answers, containsPair('query', 'release'));
    expect(submitted.answers, containsPair('milestone', true));
    expect(submitted.answers, containsPair('start', '2026-09-01'));
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 768.0, 1200.0]) {
    for (final dark in [false, true]) {
      for (final form in [false, true]) {
        testWidgets('dashboard width=$width dark=$dark form=$form', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(1.5),
                  disableAnimations: true,
                ),
                child: Material(
                  child: SingleChildScrollView(
                    child: ChatA2uiSurfaceHost.historical(
                      messageId: 'dashboard',
                      payloads: _fixture(form: form),
                    ),
                  ),
                ),
              ),
              theme: ThemeData(
                extensions: [if (dark) AuraTheme.dark else AuraTheme.light],
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.byType(AuraChart), findsOneWidget);
          expect(find.byType(AuraTable), findsOneWidget);
          expect(find.byType(AuraBadge), findsOneWidget);
          expect(find.byType(AuraLinearProgressIndicator), findsOneWidget);
          expect(find.text('Illustrative dashboard'), findsOneWidget);
          final divider = find.byWidgetPredicate(
            (widget) =>
                widget is AuraDivider && widget.orientation.name == 'vertical',
          );
          expect(tester.getSize(divider).height, greaterThan(0));
          await tester.tap(find.text('Empty'));
          await tester.pump();
          expect(find.byType(AuraEmptyState), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

List<String> _fixture({required bool form, Object progress = 0.87}) {
  final mode = form ? 'requiresUserAction' : 'passive';
  String envelope(Map<String, Object?> message) {
    final wireMessage = {'version': a2uiChatWireVersion, ...message};

    return A2uiChatContract.encodeEnvelope(wireMessage, interactionMode: mode);
  }

  return [
    envelope({
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': form ? a2uiChatFormCatalogId : a2uiChatCatalogId,
      },
    }),
    envelope({
      'updateDataModel': {
        'surfaceId': 'main',
        'path': '/',
        'value': {
          'tab': 0,
          'progress': progress,
          'rows': [
            ['Build', 'Done'],
            ['QA', 'Active'],
          ],
        },
      },
    }),
    envelope({
      'updateComponents': {
        'surfaceId': 'main',
        'components': [
          {
            'id': 'root',
            'component': 'Tabs',
            'activeTab': {'path': '/tab'},
            'tabs': [
              {'label': 'Overview', 'content': 'body'},
              {'label': 'Empty', 'content': 'empty'},
            ],
          },
          {
            'id': 'body',
            'component': 'Column',
            'children': [
              'title',
              'badge',
              'progress',
              'avatars',
              'chart',
              'table',
              'animated',
              'toolbar',
            ],
          },
          {
            'id': 'title',
            'component': 'Text',
            'variant': 'h2',
            'text': 'Illustrative dashboard',
          },
          {
            'id': 'badge',
            'component': 'Badge',
            'label': 'In progress',
            'tone': 'info',
          },
          {
            'id': 'progress',
            'component': 'Progress',
            'value': {'path': '/progress'},
            'label': 'Sprint completion',
            'tone': 'success',
          },
          {
            'id': 'avatars',
            'component': 'AvatarGroup',
            'maxVisible': 2,
            'avatars': [
              {'name': 'Alice Example'},
              {'name': 'Ben Example'},
              {
                'name': 'Cara Example',
                'url': 'https://unused.example.invalid/avatar',
              },
            ],
          },
          {
            'id': 'chart',
            'component': 'Chart',
            'label': 'Burndown',
            'labels': ['Mon', 'Tue', 'Wed'],
            'series': [
              {
                'label': 'Actual',
                'values': [10, 8, 5],
                'tone': 'primary',
              },
              {
                'label': 'Expected',
                'values': [10, 7, 4],
                'tone': 'secondary',
              },
            ],
          },
          {
            'id': 'table',
            'component': 'Table',
            'columns': ['Work', 'Status'],
            'rows': {'path': '/rows'},
            'caption': 'Release scope',
          },
          {
            'id': 'animated',
            'component': 'AnimatedContent',
            'transition': 'fade',
            'child': 'note',
          },
          {'id': 'note', 'component': 'Text', 'text': 'Sample data only'},
          {
            'id': 'toolbar',
            'component': 'Row',
            'children': ['primary', 'separator', 'outlined', 'textButton'],
          },
          {
            'id': 'primary',
            'component': 'Button',
            'variant': 'primary',
            'child': 'primaryLabel',
          },
          {
            'id': 'outlined',
            'component': 'Button',
            'variant': 'outlined',
            'child': 'outlinedLabel',
          },
          {
            'id': 'textButton',
            'component': 'Button',
            'variant': 'text',
            'child': 'textLabel',
          },
          {'id': 'primaryLabel', 'component': 'Text', 'text': 'Primary'},
          {'id': 'outlinedLabel', 'component': 'Text', 'text': 'Outline'},
          {'id': 'textLabel', 'component': 'Text', 'text': 'Text'},
          {'id': 'separator', 'component': 'Divider', 'axis': 'vertical'},
          {
            'id': 'empty',
            'component': 'EmptyState',
            'title': 'No risks',
            'description': 'Nothing to display',
            'icon': 'info',
          },
        ],
      },
    }),
  ];
}
