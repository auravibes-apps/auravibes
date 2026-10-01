import 'dart:async';

import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_accounts_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/check_cloud_account_usecase.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('stored accounts show checking, expired and unknown by origin', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final pending = Completer<String>();
    final calls = <CloudAccountKey>[];
    final first = cloudAccountKey('https://one.example', 'same');
    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: const CloudAccountsScreen(workspaceId: 'local'),
          overrides: [
            cloudAccountsProvider.overrideWith(
              (ref) async => const [
                CloudAccountSession(
                  serverUrl: 'https://one.example',
                  userId: 'same',
                  email: 'first@example.test',
                ),
                CloudAccountSession(
                  serverUrl: 'https://two.example',
                  userId: 'same',
                  email: 'second@example.test',
                ),
              ],
            ),
            checkCloudAccountUsecaseProvider.overrideWith(
              (ref) => CheckCloudAccountUsecase(
                check: (key) async {
                  calls.add(key);
                  if (key == first) return await pending.future;
                  throw StateError('fixture offline');
                },
              ),
            ),
          ],
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    expect(find.text('first@example.test'), findsOneWidget);
    expect(find.text('second@example.test'), findsOneWidget);
    expect(find.textContaining('Account stored'), findsOneWidget);
    expect(find.textContaining('Access unknown'), findsOneWidget);
    pending.completeError(
      CloudWorkspaceException(code: .authenticationRequired),
    );
    final _ = await tester.pumpAndSettle();
    expect(find.text('Needs sign in'), findsOneWidget);
    expect(find.text('Signed in'), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('account_health_https://two.example_same')),
    );
    await tester.tap(
      find.byKey(const ValueKey('account_health_https://two.example_same')),
    );
    final _ = await tester.pumpAndSettle();
    expect(calls.where((key) => key == first), hasLength(1));
    expect(
      calls.where((key) => key.serverUrl == 'https://two.example'),
      hasLength(2),
    );
  });
}
