import 'dart:convert';
import 'package:auravibes_server/src/features/workspaces/repositories/cloud_workspace_repository.dart' as repository;
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';
import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Persistent views', (builder,endpoints) {
    test('views reauthorize source grants, validate layouts and serialize revisions', () async {
      final owner = const Uuid().v4().toString();
      final reader = const Uuid().v4().toString();
      final ownerBuilder = builder.copyWith(authentication:AuthenticationOverride.authenticationInfo(owner,const {}));
      final readerBuilder = builder.copyWith(authentication:AuthenticationOverride.authenticationInfo(reader,const {}));
      final session = ownerBuilder.build();
      for(final user in [owner,reader]) {
        await AuthUser.db.insertRow(session,AuthUser(id:UuidValue.fromString(user),scopeNames:const {}));
        await EmailAccount.db.insertRow(session,EmailAccount(authUserId:UuidValue.fromString(user),email:'$user@example.com',passwordHash:'unused'));
      }
      final workspace = await repository.CloudWorkspaceRepository().createWorkspace(session,name:'Views',ownerUserId:owner,now:DateTime.now().toUtc());
      final now = DateTime.now().toUtc();
      await WorkspaceMember.db.insertRow(session,WorkspaceMember(workspaceId:workspace.id!,userId:reader,role:'member',revision:1,createdAt:now,updatedAt:now));
      final schema = {'name':'Items','labelColumnId':'label','schemaRevision':1,'columns':[{'id':'label','name':'Title','type':'text'}],'memberAccess':{reader:'read'}};
      Future<void> tablePatch(int revision,Map<String,Object?> data) async {
        final _ = await endpoints.workspaceState.patch(ownerBuilder,PatchWorkspaceStateRequest(workspaceId:workspace.id!,requestId:const Uuid().v4().toString(),operations:[WorkspacePatchOperation(operation:revision==0?.create:.update,resourceKind:.table,resourceId:'table',expectedRevision:revision==0?null:revision,data:jsonEncode(data),fieldMask:const [])]));
      }
      await tablePatch(0,schema);
      final definition = {'id':'view','name':'Overview','tableId':'table','parentId':null,'bindings':{'title':'label'},'columnTypes':{'label':'text'},'revision':0,
        'definition':{'version':1,'components':[{'id':'root','component':'Text','text':{'path':'/title'}}]}};
      final first = await endpoints.workspaceView.save(ownerBuilder,workspace.id!,'view',0,jsonEncode(definition));
      expect(first.revision,1);
      expect((await endpoints.workspaceView.read(readerBuilder,workspace.id!,'view')).stableId,'view');
      await expectLater(endpoints.workspaceView.save(readerBuilder,workspace.id!,'view',1,jsonEncode(definition)),throwsA(isA<CloudWorkspaceException>()));
      await expectLater(endpoints.workspaceView.save(ownerBuilder,workspace.id!,'view',0,jsonEncode(definition)),throwsA(isA<CloudWorkspaceException>().having((error)=>error.code,'code',CloudWorkspaceErrorCode.conflict)));
      final restored = await endpoints.workspaceView.save(ownerBuilder,workspace.id!,'view',1,(await endpoints.workspaceView.history(ownerBuilder,workspace.id!,'view')).first);
      expect(restored.revision,2);
      final malicious = {...definition,'definition':{'version':1,'components':[{'id':'root','component':'Image','url':'https://example.com'}]}};
      await expectLater(endpoints.workspaceView.save(ownerBuilder,workspace.id!,'view',2,jsonEncode(malicious)),throwsA(isA<CloudWorkspaceException>()));
      await tablePatch(1,{...schema,'memberAccess':<String,String>{}});
      expect(await endpoints.workspaceView.list(readerBuilder,workspace.id!,null),isEmpty);
      expect(await endpoints.workspaceView.history(readerBuilder,workspace.id!,'view'),isEmpty);
      await expectLater(endpoints.workspaceView.read(readerBuilder,workspace.id!,'view'),throwsA(isA<CloudWorkspaceException>()));
    });
  });
}
