import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';

class PermissionsType {
  const PermissionsType(this.permissions);

  PermissionsType.empty() : permissions = {};

  factory PermissionsType.fromJson(Map<String, dynamic> json) {
    final perms = <String, PermissionAccess>{};
    json.forEach((key, value) {
      perms[key] = PermissionAccess.fromString(value as String);
    });
    return PermissionsType(perms);
  }

  final Map<String, PermissionAccess> permissions;

  Map<String, dynamic> toJson() {
    final json = <String, String>{};
    permissions.forEach((key, value) {
      json[key] = value.name;
    });
    return json;
  }
}
