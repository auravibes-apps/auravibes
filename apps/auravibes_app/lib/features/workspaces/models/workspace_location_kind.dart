/// Describes where an active workspace is stored and whether it is shared.
enum WorkspaceLocationKind {
  /// Stored on this device.
  onDevice,

  /// Cloud workspace with only its owner and no pending invitations.
  personalCloud,

  /// Cloud workspace with collaborators or pending invitations.
  teamWorkspace,

  /// Cloud destination while sharing details are unavailable.
  cloud,
}
