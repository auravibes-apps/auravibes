import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_view_screen.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async { SharedPreferences.setMockInitialValues({}); await EasyLocalization.ensureInitialized(); });
  for (final width in [400.0,1200.0]) {
    testWidgets('saved view displays approved surface and returns at width $width', (tester) async {
      tester.view.physicalSize=Size(width,900); tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      var returned = false;
      final data = WorkspaceViewData(view:WorkspaceView(id:'view',name:'Overview',tableId:'table',bindings:{'title':'label'},columnTypes:{'label':'text'},
        definition:A2uiSavedDefinition.fromJson({'version':1,'components':[{'id':'root','component':'Text','text':{'path':'/title'}}]}),revision:1),
        table:const WorkspaceTable(id:'table',name:'Items',labelColumnId:'label',columns:[WorkspaceColumn(id:'label',name:'Title')],revision:1,schemaRevision:1,canManage:false),
        records:[const WorkspaceRecord(id:'record',tableId:'table',values:{'label':'Visible owned record'},revision:1)],needsRepair:false);
      await tester.runAsync(() async {
        await tester.pumpWidget(TestableApp(workspaceId:'one',child:WorkspaceViewScreen(workspaceId:'one',viewId:'view',onBack:()=>returned=true),overrides:[
          workspaceViewDataProvider('one','view').overrideWith((ref) async => data),
        ]));
        await Future<void>.delayed(const Duration(milliseconds:30));
      });
      final _ = await tester.pumpAndSettle();
      expect(find.text('Visible owned record'),findsOneWidget);
      expect(find.byType(PopupMenuButton<String>),findsNothing);
      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(returned,isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
