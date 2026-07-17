import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/src/framework.dart' show Override;

class TestProviderScope extends StatelessWidget {
  const TestProviderScope({
    required this.overrides,
    required this.child,
    super.key,
  });

  final List<Override> overrides;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        workspaceSessionProvider.overrideWithValue(
          const WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: 'test-workspace'),
          ),
        ),
        ...overrides,
      ],
      child: child,
    );
  }
}
