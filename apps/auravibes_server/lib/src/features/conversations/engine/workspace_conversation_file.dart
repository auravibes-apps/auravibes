import 'dart:convert';
import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:cryptography/cryptography.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../objects/object_store.dart';
import '../../workspace_state/workspace_table_access.dart';

/// Reads only the explicitly selected file, without exposing object credentials.
class WorkspaceConversationFile {
  const WorkspaceConversationFile({this.fetch, this.store});

  final Future<List<int>> Function(SignedObjectRequest, int)? fetch;
  final ObjectStore? store;
  static const maxBytes = 64 * 1024;

  Future<Map<String, Object?>> read(
    Session session,
    WorkspaceMember member,
    String id,
  ) async {
    final resource = await _resource(session, member, id);
    final data = jsonDecode(resource.data) as Map<String, dynamic>;
    final objectId = int.tryParse(data['assetId'] as String? ?? '');
    final object = await WorkspaceObject.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(member.workspaceId) &
          row.id.equals(objectId) &
          row.status.equals('active') &
          row.deletedAt.equals(null),
    );
    if (object == null || object.sizeBytes < 0 || object.sizeBytes > maxBytes) {
      throw const FormatException('File is unavailable or too large.');
    }
    final mime = object.mimeType.split(';').first.trim().toLowerCase();
    if (!mime.startsWith('text/') && mime != 'application/json') {
      throw const FormatException('Only text and JSON files can be read.');
    }
    final upload = await ObjectUpload.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(member.workspaceId) &
          row.objectId.equals(object.id),
    );
    final List<int> bytes;
    try {
      final signed = await (store ?? HttpObjectStore.fromEnvironment()).signGet(
        key: object.objectKey,
        contentDisposition: 'attachment',
        expiresIn: const Duration(minutes: 1),
        registrationId: upload?.gatewayRegistrationId,
      );
      bytes = await (fetch ?? _fetch)(signed, maxBytes);
    } on Object {
      throw const FormatException('File storage is unavailable.');
    }
    if (bytes.length != object.sizeBytes) {
      throw const FormatException('File integrity check failed.');
    }
    final digest = (await Sha256().hash(bytes)).bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    if (digest != object.checksumSha256.toLowerCase()) {
      throw const FormatException('File integrity check failed.');
    }
    final content = utf8.decode(bytes);
    final current = await _resource(session, member, id);
    final currentObject = await WorkspaceObject.db.findById(
      session,
      object.id!,
    );
    if (current.revision != resource.revision ||
        currentObject == null ||
        currentObject.workspaceId != member.workspaceId ||
        currentObject.revision != object.revision ||
        currentObject.status != 'active' ||
        currentObject.deletedAt != null) {
      throw CloudWorkspaceException(code: .permissionDenied);
    }
    final name = data['name'];
    if (name is! String) throw const FormatException('Invalid file metadata.');
    return workspaceFileToolResult(
      id: id,
      name: name,
      mimeType: object.mimeType,
      revision: resource.revision,
      content: content,
    );
  }

  Future<WorkspaceResource> _resource(
    Session session,
    WorkspaceMember member,
    String id,
  ) async {
    final row = await WorkspaceResource.db.findFirstRow(
      session,
      where: (row) =>
          row.workspaceId.equals(member.workspaceId) &
          row.resourceKind.equals(.file) &
          row.resourceId.equals(id) &
          row.deletedAt.equals(null),
    );
    if (row == null ||
        await const WorkspaceTableAccess().visible(session, member, row) ==
            null) {
      throw CloudWorkspaceException(code: .permissionDenied);
    }
    return row;
  }

  static Future<List<int>> _fetch(SignedObjectRequest signed, int limit) async {
    final uri = signed.url;
    if (uri.scheme != 'https' &&
        !(uri.scheme == 'http' &&
            (uri.host == 'localhost' ||
                InternetAddress.tryParse(uri.host)?.isLoopback == true))) {
      throw const FormatException('File storage is unavailable.');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      signed.headers.forEach(request.headers.set);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw const FormatException('File storage is unavailable.');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        if (bytes.length + chunk.length > limit) {
          throw const FormatException('File is too large.');
        }
        bytes.addAll(chunk);
      }
      return bytes;
    } finally {
      client.close(force: true);
    }
  }
}
