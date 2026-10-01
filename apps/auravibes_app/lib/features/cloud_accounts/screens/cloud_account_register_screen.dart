import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_auth_screen.dart';
import 'package:material_ui/material_ui.dart';

class const CloudAccountRegisterScreen({
  required final String workspaceId,
  required final String? returnPath,
  final Map<String, String> query = const {},
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CloudAccountAuthScreen(
    workspaceId: workspaceId,
    returnPath: returnPath,
    query: query,
    mode: .register,
  );
}
