import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'workspaceId from route state is available synchronously — no Riverpod dependency',
    (tester) async {
      String? capturedWorkspaceId;

      final router = GoRouter(
        initialLocation: '/workspaces/ws-test/tools',
        routes: [
          // Matches production structure: parent route has :workspaceId param,
          // child StatefulShellBranch routes have no parameters.
          GoRoute(
            path: '/workspaces/:workspaceId',
            // Production WorkspaceRoute.build returns SizedBox.shrink;
            // the shell builder provides the actual UI.
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (context, state, navigationShell) {
                  // Same pattern as MyShellRouteData.builder in app_router.dart:82.
                  // Before the fix, the sidebar read workspaceId from
                  // currentRouteWorkspaceIdProvider (a Riverpod proxy), which
                  // broke after the async redirect because the ChangeNotifier
                  // notification didn't reach the Riverpod provider tree.
                  // After the fix, workspaceId comes directly from GoRouter's
                  // synchronous pathParameters — no async dependency.
                  capturedWorkspaceId = state.pathParameters['workspaceId'];
                  return Text('workspaceId: $capturedWorkspaceId');
                },
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'tools',
                        builder: (context, state) => const Text('Tools screen'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      // Core assertion: workspaceId is resolved synchronously from route state,
      // not from an async Riverpod provider chain.
      expect(capturedWorkspaceId, 'ws-test');
      expect(find.text('workspaceId: ws-test'), findsOneWidget);
    },
  );
}
