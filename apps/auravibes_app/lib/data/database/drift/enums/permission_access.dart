enum PermissionAccess {
  ask('ask'),
  granted('granted')
  ;

  const PermissionAccess(this.value);

  final String value;

  static PermissionAccess fromString(String value) {
    return PermissionAccess.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PermissionAccess.ask,
    );
  }
}
