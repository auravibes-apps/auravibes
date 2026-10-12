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
  testWidgets('account action labels explain their outcomes in English', (
    tester,
  ) async {
    await _pumpAccountsScreen(tester, const Locale('en'));

    expect(find.text('first@example.test'), findsOneWidget);
    expect(find.text('Remove from this app'), findsOneWidget);
    expect(find.text('Delete cloud account'), findsOneWidget);

    await tester.tap(find.text('Remove from this app'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Remove cloud account from this app?'), findsOneWidget);
    expect(
      find.text(
        'Remove first@example.test from this app? '
        'Cloud data stays in the cloud.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Local shortcuts for cloud workspaces connected through this account '
        'will be removed from this app.',
      ),
      findsOneWidget,
    );
    expect(find.text('Remove from this app'), findsNWidgets(2));

    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Delete cloud account'));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Permanently delete cloud account?'), findsOneWidget);
    expect(
      find.text(
        'Permanently delete first@example.test and its sign-in credentials? '
        'Your access to shared cloud workspaces will end, but their content '
        'will remain. Delete or transfer any cloud workspaces you own first. '
        'This cannot be undone.',
      ),
      findsOneWidget,
    );
    expect(find.text('Delete cloud account'), findsNWidgets(2));
  });

  testWidgets('account action labels explain their outcomes in Spanish', (
    tester,
  ) async {
    await _pumpAccountsScreen(tester, const Locale('es'));

    expect(find.text('first@example.test'), findsOneWidget);
    expect(find.text('Quitar de esta app'), findsOneWidget);
    expect(find.text('Eliminar cuenta en la nube'), findsOneWidget);

    await tester.tap(find.text('Quitar de esta app'));
    final _ = await tester.pumpAndSettle();

    expect(
      find.text(
        '${_spanishChar(0xBF)}Quitar la cuenta en la nube de esta app?',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '${_spanishChar(0xBF)}Quitar first@example.test de esta app? '
        'Los datos en la nube '
        'permanecen en la nube.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Los accesos locales a espacios en la nube conectados con esta cuenta '
        'se quitar${_spanishChar(0xE1)}n de esta app.',
      ),
      findsOneWidget,
    );
    expect(find.text('Quitar de esta app'), findsNWidgets(2));

    await tester.tap(find.text('Cancelar'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar cuenta en la nube'));
    final _ = await tester.pumpAndSettle();

    expect(
      find.text(
        '${_spanishChar(0xBF)}Eliminar definitivamente la cuenta en la nube?',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '${_spanishChar(0xBF)}Eliminar definitivamente first@example.test '
        'y sus credenciales de acceso? Perder${_spanishChar(0xE1)}s acceso a '
        'los espacios en la nube compartidos, pero su contenido '
        'permanecer${_spanishChar(0xE1)}. Primero '
        'elimina o transfiere los espacios en la nube que posees. Esta '
        'acci${_spanishChar(0xF3)}n no se puede deshacer.',
      ),
      findsOneWidget,
    );
    expect(find.text('Eliminar cuenta en la nube'), findsNWidgets(2));
  });

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

Future<void> _pumpAccountsScreen(WidgetTester tester, Locale locale) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
            ],
          ),
          checkCloudAccountUsecaseProvider.overrideWith(
            (ref) =>
                CheckCloudAccountUsecase(check: (key) async => key.accountId),
          ),
        ],
        startLocale: locale,
      ),
    );
  });
  final _ = await tester.pumpAndSettle();
}

String _spanishChar(int codePoint) => String.fromCharCode(codePoint);
