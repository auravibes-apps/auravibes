enum PermissionAccess {
  ask('ask'),
  granted('granted');

  const PermissionAccess(this.value);

  final String value;

  static PermissionAccess fromString(String value) {
    if (!PermissionAccess.values.map((access) => access.name).contains(value)) {
      return PermissionAccess.ask;
    }

    return PermissionAccess.values.byName(value);
  }
}
