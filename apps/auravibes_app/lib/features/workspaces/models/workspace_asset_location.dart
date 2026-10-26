import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';

/// An opaque reference, never a filesystem path or a temporary download URL.
class WorkspaceAssetLocation {
  static final _key = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  const new _(this.namespace, this.workspaceId, this.assetId);

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

  final String namespace;
  final String workspaceId;
  final String assetId;

  String get location => Uri(
    scheme: 'workspace-asset',
    host: 'asset',
    pathSegments: [namespace, workspaceId, assetId],
  ).toString();

  static WorkspaceAssetLocation? parse(String value) {
    final uri = Uri.tryParse(value);
    if (uri?.scheme != 'workspace-asset') return null;
    if (uri == null || !_authority(uri) || !_path(uri)) {
      throw const WorkspaceAssetException(.invalid);
    }

    return _fromSegments(uri.pathSegments);
  }

  static WorkspaceAssetLocation _fromSegments(List<String> segments) => .create(
    namespace: segments.firstOrNull ?? '',
    workspaceId: segments[1],
    assetId: segments[2],
  );

  static bool _authority(Uri uri) =>
      uri.host == 'asset' && uri.userInfo.isEmpty && !uri.hasPort;
  static bool _path(Uri uri) =>
      uri.pathSegments.length == 3 && !uri.hasQuery && !uri.hasFragment;
}
