import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

class const VirtualWorkspaceModelSelectionId._() {
  static const _prefix = 'wms1.';

  static String encode({
    required String connectionId,
    required String modelId,
  }) => '$_prefix${_encodePart(connectionId)}.${_encodePart(modelId)}';

  static VirtualWorkspaceModelSelectionIdentity? tryDecode(String value) {
    if (!value.startsWith(_prefix)) return null;
    try {
      final parts = value.substring(_prefix.length).split('.');
      if (parts.length != 2) return null;
      final connectionId = _decodePart(parts.first);
      final modelId = _decodePart(parts.last);
      if (connectionId.isEmpty || modelId.isEmpty) return null;
      return VirtualWorkspaceModelSelectionIdentity(
        connectionId: connectionId,
        modelId: modelId,
      );
    } on FormatException {
      return null;
    }
  }

  static String _encodePart(String value) =>
      base64UrlEncode(utf8.encode(value)).replaceAll('=', '');

  static String _decodePart(String value) =>
      utf8.decode(base64Url.decode(base64Url.normalize(value)));
}

class const VirtualWorkspaceModelSelectionIdentity({
  required final String connectionId,
  required final String modelId,
});

class const ResolvedVirtualWorkspaceModelSelection({
  required final WorkspaceModelConnection connection,
  required final ApiModel model,
});

class const VirtualWorkspaceModelSelectionResolver() {
  Future<ResolvedVirtualWorkspaceModelSelection?> resolve(
    Session session, {
    required int workspaceId,
    required String selectionId,
    Transaction? transaction,
  }) async {
    final identity = VirtualWorkspaceModelSelectionId.tryDecode(selectionId);
    if (identity == null) return null;
    final connection = await WorkspaceModelConnection.db.findFirstRow(
      session,
      where: (table) =>
          table.workspaceId.equals(workspaceId) &
          table.connectionId.equals(identity.connectionId) &
          table.deletedAt.equals(null),
      transaction: transaction,
    );
    if (connection == null) return null;
    final model = await ApiModel.db.findFirstRow(
      session,
      where: (table) =>
          table.providerId.equals(connection.providerId) &
          table.modelId.equals(identity.modelId),
      transaction: transaction,
    );
    if (model == null) return null;
    return ResolvedVirtualWorkspaceModelSelection(
      connection: connection,
      model: model,
    );
  }
}
