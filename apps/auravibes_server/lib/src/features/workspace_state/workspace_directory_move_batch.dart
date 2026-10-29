import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../workspace_views/workspace_view_store.dart';

/// Hashed View metadata participates in the ordinary patch lock and receipt.
class const WorkspaceDirectoryMoveBatch(
  final PatchWorkspaceStateRequest request,
) {
  List<WorkspaceViewMove> get _moves => request.viewMoves ?? const [];
  Map<String, dynamic> canonicalRequest() {
    final data = request.toJson();
    if (_moves.isEmpty) {
      final _ = data.remove('viewMoves');
    }

    return data;
  }

  void validate() {
    final count = request.operations.length + _moves.length;
    if (request.requestId.isEmpty ||
        count < 1 ||
        count > 50 ||
        !_distinct(_moves) ||
        _moves.any(_invalidMove)) {
      throw CloudWorkspaceException(code: .validationFailed);
    }
  }

  Future<void> authorize(
    Session session,
    WorkspaceMember member,
    Transaction transaction,
  ) async {
    final store = WorkspaceViewStore(session, member, transaction);
    for (final move in _moves) {
      await store.authorizeMove(move);
    }
  }

  Future<void> apply(
    Session session,
    WorkspaceMember member,
    Transaction transaction,
  ) async {
    final store = WorkspaceViewStore(session, member, transaction);
    for (final move in _moves) {
      final _ = await store.move(move);
    }
  }
}

bool _invalidMove(WorkspaceViewMove move) =>
    move.id.isEmpty ||
    move.id.length > _maxNameLength ||
    move.expectedRevision < 1 ||
    _invalidText(move.parentId) ||
    _invalidText(move.name);
bool _invalidText(String? value) =>
    value != null && (value.trim().isEmpty || value.length > _maxNameLength);

const _maxNameLength = 200;
bool _distinct(List<WorkspaceViewMove> moves) =>
    moves.map((move) => move.id).toSet().length == moves.length;
