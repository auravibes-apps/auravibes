import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ux_validation_fixture.dart';

void main() {
  tearDownAll(UxValidationFixture.closeDatabase);

  testWidgets('production router opens Directory creation', (tester) async {
    final fixture = await UxValidationFixture.create();
    final items = WorkspaceItemsRoute(workspaceId: fixture.workspaceId)
        .location;
    final router = await fixture.pump(
      tester,
      items,
      size: const Size(800, 600),
      useProductionRouter: true,
    );
    await fixture.settle(tester);
    expect(router.state.uri.path, items);
    expect(find.text('Directory'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('directory_create')));
    await fixture.settle(tester);
    await tester.tap(find.text('Folder').last);
    await fixture.settle(tester);
    final input = find.byWidgetPredicate(
      (widget) =>
          widget is AuraInput && widget.identifier == 'workspace_folder_name',
    );
    expect(input, findsOneWidget);
    await fixture.close(tester);
  });

  testWidgets('Directory keeps drawer navigation usable', (tester) async {
    final fixture = await UxValidationFixture.create();
    final chat = NewChatRoute(workspaceId: fixture.workspaceId).location;
    final items = WorkspaceItemsRoute(workspaceId: fixture.workspaceId)
        .location;
    final router = await fixture.pump(tester, chat, size: const Size(800, 600));

    await tester.tap(find.byKey(const ValueKey('app_drawer_menu')));
    await fixture.settle(tester);
    await tester.tap(find.text('Directory'));
    await fixture.settle(tester);
    expect(router.state.uri.path, items);

    await tester.tap(find.byKey(const ValueKey('app_drawer_menu')));
    await fixture.settle(tester);
    expect(find.byKey(const ValueKey('workspace_choice')), findsOneWidget);
    await tester.tap(find.text('New Chat'));
    await fixture.settle(tester);
    expect(router.state.uri.path, chat);
    await fixture.close(tester);
  });
}
