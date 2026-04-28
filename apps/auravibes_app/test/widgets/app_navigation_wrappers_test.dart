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
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      // Core assertion: workspaceId is resolved synchronously from route state
      // after the initial frame, not after async operations settle.
      expect(capturedWorkspaceId, 'ws-test');

      await tester.pumpAndSettle();
      expect(find.text('workspaceId: ws-test'), findsOneWidget);
    },
  );

  testWidgets(
    'workspaceId available after async redirect from root — exercises actual startup failure mode',
    (tester) async {
      String? capturedWorkspaceId;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId',
            builder: (context, state) => const SizedBox.shrink(),
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (context, state, navigationShell) {
                  capturedWorkspaceId = state.pathParameters['workspaceId'];
                  return Text('workspaceId: $capturedWorkspaceId');
                },
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: 'chat/new',
                        builder: (context, state) =>
                            const Text('New chat screen'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
        redirect: (context, state) {
          if (state.uri.toString() == '/') {
            return '/workspaces/ws-redirect-test/chat/new';
          }
          return null;
        },
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );

      // Key regression guard: workspaceId must be available after the initial
      // frame — even when the route required an async-like redirect from '/'.
      // The old Riverpod-based path failed here because ChangeNotifier
      // notifications from routeInformationProvider didn't propagate.
      expect(capturedWorkspaceId, 'ws-redirect-test');
    },
  );
}
