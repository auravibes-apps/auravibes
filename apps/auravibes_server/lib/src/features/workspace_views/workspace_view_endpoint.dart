import 'dart:convert';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:serverpod/serverpod.dart';
import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import '../workspace_state/workspace_table_access.dart';

class WorkspaceViewEndpoint extends Endpoint {
  Future<List<WorkspaceView>> list(Session session, int workspaceId, String? parentId) async {
    final member = await _member(session, workspaceId);
    final rows = await WorkspaceView.db.find(session, where: (row) => row.workspaceId.equals(workspaceId));
    final visible = <WorkspaceView>[];
    for (final row in rows) {
      final data = _data(row.data);
      if (data['parentId'] == parentId && await _visible(session,member,data['tableId'] as String)) visible.add(row.copyWith(history: '[]'));
    }
    return visible;
  }

  Future<WorkspaceView> read(Session session, int workspaceId, String id) async {
    final member = await _member(session,workspaceId);
    final row = await _row(session,workspaceId,id);
    if (!await _visible(session,member,_data(row.data)['tableId'] as String)) _denied();
    return row.copyWith(history:'[]');
  }

  Future<List<String>> history(Session session, int workspaceId, String id) async {
    final member = await _member(session,workspaceId);
    final row = await _row(session,workspaceId,id);
    final visible = <String>[];
    for (final snapshot in jsonDecode(row.history) as List<dynamic>) {
      final data = Map<String,Object?>.from(snapshot as Map);
      if (await _visible(session,member,data['tableId'] as String)) visible.add(jsonEncode(data));
    }
    return visible;
  }

  Future<WorkspaceView> save(Session session, int workspaceId, String id, int expectedRevision, String definition) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return session.db.transaction((transaction) async {
      final workspace = await CloudWorkspace.db.findById(session,workspaceId,transaction:transaction,lockMode:LockMode.forUpdate);
      if (workspace == null) _denied();
      final member = await _memberForUser(session,workspaceId,account.userId,transaction);
      if (member.role != 'owner') _denied();
      final data = _validated(definition,id);
      await _validateBindings(session,member,data,transaction);
      final current = await WorkspaceView.db.findFirstRow(session,where:(row) => row.workspaceId.equals(workspaceId) & row.stableId.equals(id),transaction:transaction);
      if ((current?.revision ?? 0) != expectedRevision) {
        throw CloudWorkspaceException(code:CloudWorkspaceErrorCode.conflict);
      }
      final next = {...data,'revision':expectedRevision+1};
      final snapshots = current == null ? <dynamic>[] : jsonDecode(current.history) as List<dynamic>;
      final row = WorkspaceView(id:current?.id,workspaceId:workspaceId,stableId:id,data:jsonEncode(next),revision:expectedRevision+1,history:jsonEncode([...snapshots,next]));
      final saved = current == null ? await WorkspaceView.db.insertRow(session,row,transaction:transaction) : await WorkspaceView.db.updateRow(session,row,transaction:transaction);
      return saved.copyWith(history:'[]');
    });
  }
}

Future<WorkspaceMember> _member(Session session,int workspaceId) async {
  final account = await const AuthenticatedAccountResolver()(session);
  return _memberForUser(session,workspaceId,account.userId,null);
}
Future<WorkspaceMember> _memberForUser(Session session,int workspaceId,String userId,Transaction? transaction) async {
  final member = await WorkspaceMember.db.findFirstRow(session,where:(row) => row.workspaceId.equals(workspaceId) & row.userId.equals(userId) & row.removedAt.equals(null),transaction:transaction);
  if (member == null) _denied();
  return member;
}
Future<WorkspaceView> _row(Session session,int workspaceId,String id) async {
  final row = await WorkspaceView.db.findFirstRow(session,where:(row) => row.workspaceId.equals(workspaceId) & row.stableId.equals(id));
  if (row == null) _denied();
  return row;
}
Future<bool> _visible(Session session,WorkspaceMember member,String tableId) async {
  final table = await WorkspaceResource.db.findFirstRow(session,where:(row) => row.workspaceId.equals(member.workspaceId) & row.resourceKind.equals(.table) & row.resourceId.equals(tableId) & row.deletedAt.equals(null));
  return table != null && await const WorkspaceTableAccess().visible(session,member,table) != null;
}
Map<String,Object?> _data(String source) => Map<String,Object?>.from(jsonDecode(source) as Map);
Never _denied() => throw CloudWorkspaceException(code:CloudWorkspaceErrorCode.permissionDenied);

Map<String,Object?> _validated(String source,String id) {
  try {
    if (source.length > 131072 || id.isEmpty || id.length > 100) throw const FormatException();
    final data = _data(source);
    if (data.keys.any((key) => !{'id','name','tableId','parentId','bindings','columnTypes','definition','revision'}.contains(key)) || data['id'] != id || data['name'] is! String || (data['name'] as String).trim().isEmpty || (data['name'] as String).length > 200 || data['tableId'] is! String || data['bindings'] is! Map || data['definition'] is! Map) throw const FormatException();
    final _ = A2uiSavedDefinition.fromJson(Map<String,Object?>.from(data['definition'] as Map));
    if(data['columnTypes'] is! Map) throw const FormatException();
    final bindings = data['bindings'] as Map;
    if (bindings.isEmpty || bindings.length > 50 || bindings.entries.any((entry) => entry.key is! String || entry.value is! String)) throw const FormatException();
    return data;
  } on FormatException {
    throw CloudWorkspaceException(code:CloudWorkspaceErrorCode.validationFailed);
  } on TypeError {
    throw CloudWorkspaceException(code:CloudWorkspaceErrorCode.validationFailed);
  }
}
Future<void> _validateBindings(Session session,WorkspaceMember member,Map<String,Object?> data,Transaction transaction) async {
  final table = await WorkspaceResource.db.findFirstRow(session,where:(row) => row.workspaceId.equals(member.workspaceId) & row.resourceKind.equals(.table) & row.resourceId.equals(data['tableId'] as String) & row.deletedAt.equals(null),transaction:transaction);
  if (table == null || await WorkspaceTableAccess(transaction:transaction).visible(session,member,table) == null) _denied();
  final columnValues = _data(table.data)['columns'] as List<dynamic>;
  final columns = columnValues.map((column) => (column as Map)['id']).toSet();
  final types = data['columnTypes'] as Map;
  if(types.length != (data['bindings'] as Map).values.toSet().length || !(data['bindings'] as Map).values.every((id) => types[id] == (columnValues.where((column)=>(column as Map)['id']==id).firstOrNull as Map?)?['type'])) throw CloudWorkspaceException(code:CloudWorkspaceErrorCode.validationFailed);
  if (!(data['bindings'] as Map).values.every(columns.contains)) throw CloudWorkspaceException(code:CloudWorkspaceErrorCode.validationFailed);
  final parentId = data['parentId'];
  if (parentId != null) {
    if (parentId is! String) throw CloudWorkspaceException(code:CloudWorkspaceErrorCode.validationFailed);
    final parent = await WorkspaceResource.db.findFirstRow(session,where:(row) => row.workspaceId.equals(member.workspaceId) & row.resourceKind.equals(.folder) & row.resourceId.equals(parentId) & row.deletedAt.equals(null),transaction:transaction);
    if (parent == null) throw CloudWorkspaceException(code:CloudWorkspaceErrorCode.validationFailed);
  }
}
