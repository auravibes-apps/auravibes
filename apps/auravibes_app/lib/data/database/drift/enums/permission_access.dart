enum PermissionAccess(final String value) {
  ask('ask'),
  granted('granted'),
  denied('denied');

  static PermissionAccess fromString(String value) {
    if (!PermissionAccess.values.map((access) => access.name).contains(value)) {
      return PermissionAccess.ask;
    }

    return PermissionAccess.values.byName(value);
  }
}
