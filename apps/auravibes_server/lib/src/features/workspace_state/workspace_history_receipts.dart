import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

class const WorkspaceHistoryReceipts(final Session session, final int workspaceId, final Transaction transaction) {
  Future<void> redact(Set<String> scope) async {
    final ids = scope.map(_id).toSet();
    for (final receipt in await _receipts()) {
      final response = jsonDecode(receipt.responseJson);
      if (_contains(response, ids)) await _mark(receipt, 'permanentlyDeleted');
    }
  }

  Future<void> expire(int days) async {
    final now = DateTime.now().toUtc();
    for (final receipt in await _receipts()) {
      if (now.difference(receipt.createdAt).inDays >= days && _historical(receipt)) await _mark(receipt, 'historyExpired');
    }
  }

  Future<List<WorkspaceMutationReceipt>> _receipts() => WorkspaceMutationReceipt.db.find(session, where: (row) => row.workspaceId.equals(workspaceId), transaction: transaction);

  Future<void> _mark(WorkspaceMutationReceipt receipt, String reason) async {
    final updated = receipt.copyWith(responseJson: jsonEncode({reason: true}));
    final _ = await WorkspaceMutationReceipt.db.updateRow(session, updated, transaction: transaction);
  }

  static WorkspaceMutationReceipt? available(WorkspaceMutationReceipt? receipt) {
    if (receipt == null) return null;
    final data = jsonDecode(receipt.responseJson) as Map<String, dynamic>;
    if (data['permanentlyDeleted'] == true || data['historyExpired'] == true) throw CloudWorkspaceException(code: .conflict);

    return receipt;
  }
}

String _id(String key) => key.substring(key.indexOf(':') + 1);
bool _historical(WorkspaceMutationReceipt receipt) {
  final data = jsonDecode(receipt.responseJson) as Map<String, dynamic>;
  final resources = data['resources'];
  if (resources is! List) return false;

  return resources.cast<Map<String, dynamic>>().any((row) => row['resourceKind'] == 'table' || row['resourceKind'] == 'tableRecord');
}
bool _contains(Object? value, Set<String> ids) => switch (value) {
  final String text => ids.contains(text) || _encoded(text, ids),
  final List<dynamic> items => items.any((item) => _contains(item, ids)),
  final Map<dynamic, dynamic> items => items.values.any((item) => _contains(item, ids)),
  _ => false,
};
bool _encoded(String value, Set<String> ids) {
  if (!value.startsWith('{') && !value.startsWith('[')) return false;
  try {
    return _contains(jsonDecode(value), ids);
  } on FormatException {
    return false;
  }
}
