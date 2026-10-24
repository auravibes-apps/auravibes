import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';

/// An opaque reference, never a filesystem path or a temporary download URL.
class WorkspaceAssetLocation {
  const WorkspaceAssetLocation._(
    this.namespace,
    this.workspaceId,
    this.assetId,
  );

  factory create({
    required String namespace,
    required String workspaceId,
    required String assetId,
  }) {
    if (!_key.hasMatch(namespace) ||
        !_key.hasMatch(assetId) ||
        workspaceId.isEmpty) {
      throw const WorkspaceAssetException(.invalid);
    }
    return WorkspaceAssetLocation._(namespace, workspaceId, assetId);
  }

  static final _key = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  final String namespace;
  final String workspaceId;
  final String assetId;

  static WorkspaceAssetLocation? parse(String value) {
    final uri = Uri.tryParse(value);
    if (uri?.scheme != 'workspace-asset') return null;
    if (uri == null ||
        uri.host != 'asset' ||
        uri.pathSegments.length != 3 ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort) {
      throw const WorkspaceAssetException(.invalid);
    }
    final segments = uri.pathSegments;
    return .create(
      namespace: segments[0],
      workspaceId: segments[1],
      assetId: segments[2],
    );
  }

  String get location => Uri(
    scheme: 'workspace-asset',
    host: 'asset',
    pathSegments: [namespace, workspaceId, assetId],
  ).toString();
}
