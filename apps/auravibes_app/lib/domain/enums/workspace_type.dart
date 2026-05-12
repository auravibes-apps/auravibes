/// Enum representing the type of workspace.
enum WorkspaceType {
  /// Local workspace stored on the device
  local('local'),

  /// Remote workspace accessed via URL
  remote('remote');

  /// Creates a new WorkspaceType with the given string value
  const WorkspaceType(this.value);

  /// Creates a WorkspaceType from a string value
  ///
  /// Throws [ArgumentError] if the value is not a valid workspace type
  factory WorkspaceType.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'local':
        return WorkspaceType.local;
      case 'remote':
        return WorkspaceType.remote;
      default:
        throw ArgumentError('Invalid workspace type: $value');
    }
  }

  /// String value representing the workspace type
  final String value;

  /// Returns true if this is a local workspace
  bool get isLocal => this == WorkspaceType.local;

  /// Returns true if this is a remote workspace
  bool get isRemote => this == WorkspaceType.remote;

  @override
  String toString() => value;
}
