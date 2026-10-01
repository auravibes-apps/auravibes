import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_email_delivery.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_email_delivery_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_auth_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_auth_content.dart';
import 'package:auravibes_app/services/cloud_auth_protocol.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

class _Repository extends Mock implements WorkspaceRepository;

class _Protocol extends Mock implements CloudAuthProtocol;

void main() {
  const user = '11111111-1111-4111-8111-111111111111';
  const origin = 'https://a.example';
  const email = 'person@example.com';
  const target = CloudAuthTarget(
    serverUrl: origin,
    accountId: user,
    email: email,
  );
  final request = UuidValue.fromString(user);
  CloudAuthResult result(String server) => (
    session: CloudAccountSession(serverUrl: server, userId: user, email: email),
    auth: AuthSuccess(
      authStrategy: 'jwt',
      token: 'masked-token',
      authUserId: request,
      scopeNames: {},
    ),
  );
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ProviderContainer fixture(
    _Protocol protocol, {
    CloudEmailDelivery delivery = .email,
    void Function(String)? onOrigin,
  }) {
    final usecases = CloudAccountUseCases(
      store: .new(),
      workspaceRepository: _Repository(),
      deleteRemoteAccount: ({required serverUrl, required userId}) =>
          Future<void>.value(),
      invalidateAccount: (server, _) => expect(server, startsWith('https://')),
      createAuthProtocol: (origin) {
        onOrigin?.call(origin);

        return protocol;
      },
      emailDelivery: delivery,
    );
    final container = ProviderContainer(
      overrides: [
        cloudAccountUseCasesProvider.overrideWithValue(usecases),
        cloudEmailDeliveryProvider.overrideWithValue(delivery),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer container,
    Widget child, {
    GoRouter? router,
  }) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) => UncontrolledProviderScope(
              container: container,
              child: AuraThemeScope(
                theme: .light,
                child: router != null
                    ? MaterialApp.router(
                        routerConfig: router,
                        builder: (_, child) => AuraLegacyMaterialBridge(
                          child: child ?? const SizedBox.shrink(),
                        ),
                        locale: context.locale,
                        localizationsDelegates: [
                          ...GlobalMaterialLocalizations.delegates,
                          ...context.localizationDelegates,
                        ],
                        supportedLocales: context.supportedLocales,
                      )
                    : MaterialApp(
                        home: Scaffold(
                          body: SingleChildScrollView(child: child),
                        ),
                        builder: (_, child) => AuraLegacyMaterialBridge(
                          child: child ?? const SizedBox.shrink(),
                        ),
                        locale: context.locale,
                        localizationsDelegates: [
                          ...GlobalMaterialLocalizations.delegates,
                          ...context.localizationDelegates,
                        ],
                        supportedLocales: context.supportedLocales,
                      ),
              ),
            ),
          ),
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          startLocale: const Locale('en'),
          useOnlyLangCode: true,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    final _ = await tester.pumpAndSettle();
  }

  testWidgets('login owns success and cancel callbacks without any workspace', (
    tester,
  ) async {
    final protocol = _Protocol();
    when(() => protocol.login(email, 'password'))
        .thenAnswer((_) async => result(origin));
    var signedIn = 0;
    var canceled = 0;
    final origins = <String>[];
    await pump(
      tester,
      fixture(protocol, onOrigin: origins.add),
      CloudAccountAuthContent(
        onSignedIn: (_) => signedIn++,
        onCancel: () => canceled++,
        target: target,
      ),
    );
    expect(find.text(email), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isTrue,
    );
    await tester.enterText(find.byType(EditableText).last, 'password');
    await tap(tester, 'Log in');
    expect(signedIn, 1);
    expect(origins, [origin]);
    await tap(tester, 'Cancel and return');
    expect(canceled, 1);
  });

  testWidgets(
    'replacement target clears secrets and ignores prior pending completion',
    (tester) async {
      final protocol = _Protocol();
      final old = Completer<CloudAuthResult>();
      when(() => protocol.login(email, 'secret-A'))
          .thenAnswer((_) => old.future);
      when(() => protocol.login(email, 'secret-B'))
          .thenAnswer((_) async => result('https://b.example'));
      final origins = <String>[];
      final owner = ValueNotifier(target);
      addTearDown(owner.dispose);
      var completed = 0;
      await pump(
        tester,
        fixture(protocol, onOrigin: origins.add),
        ValueListenableBuilder(
          valueListenable: owner,
          builder: (_, value, _) => CloudAccountAuthContent(
            onSignedIn: (_) => completed++,
            onCancel: () => fail('pending cancel'),
            target: value,
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText).last, 'secret-A');
      await tester.tap(find.text('Log in').last);
      await tester.pump();
      expect(
        tester
            .widget<AuraButton>(
              find.ancestor(
                of: find.text('Cancel and return'),
                matching: find.byType(AuraButton),
              ),
            )
            .disabled,
        isTrue,
      );
      owner.value = const CloudAuthTarget(
        serverUrl: 'https://b.example',
        accountId: user,
        email: email,
      );
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .controller
            .text,
        isEmpty,
      );
      old.complete(result(origin));
      final _ = await tester.pumpAndSettle();
      expect(completed, 0);
      await tester.enterText(find.byType(EditableText).last, 'secret-B');
      await tap(tester, 'Log in');
      expect(origins, [origin, 'https://b.example']);
      expect(completed, 1);
      verify(() => protocol.login(email, 'secret-A')).called(1);
      verify(() => protocol.login(email, 'secret-B')).called(1);
    },
  );

  testWidgets('registration shows stage email resend success and edit email', (
    tester,
  ) async {
    final protocol = _Protocol();
    when(() => protocol.startRegistration(email))
        .thenAnswer((_) async => request);
    when(() => protocol.verifyRegistrationCode(request, '123456'))
        .thenAnswer((_) async => 'verified');
    when(() => protocol.finishRegistration('verified', 'password'))
        .thenAnswer((_) async => result(origin));
    var completed = 0;
    await pump(
      tester,
      fixture(protocol, delivery: .developmentLog),
      CloudAccountAuthContent(
        onSignedIn: (_) => completed++,
        onCancel: () => fail('Unexpected cancellation'),
        target: target,
        initialMode: .register,
      ),
    );
    expect(find.text('Create cloud account'), findsOneWidget);
    await tester.enterText(find.byType(EditableText).last, 'password');
    await tap(tester, 'Send code');
    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text(email), findsOneWidget);
    expect(tester.widget<AuraInput>(find.byType(AuraInput)).autofocus, isTrue);
    await tap(tester, 'Resend code');
    expect(
      find.text('A new verification code is available. Use the latest code.'),
      findsOneWidget,
    );
    await tap(tester, 'Edit email');
    expect(find.text('Create cloud account'), findsOneWidget);
    expect(
      find.text('A new verification code is available. Use the latest code.'),
      findsNothing,
    );
    await tap(tester, 'Send code');
    await tester.enterText(find.byType(EditableText), '123456');
    await tap(tester, 'Finish registration');
    expect(completed, 1);
    verify(() => protocol.startRegistration(email)).called(3);
  });

  testWidgets(
    'reset completes into login with changed-password guidance and email',
    (tester) async {
      final protocol = _Protocol();
      when(() => protocol.startPasswordReset(email))
          .thenAnswer((_) async => request);
      when(() => protocol.verifyPasswordResetCode(request, '654321'))
          .thenAnswer((_) async => 'reset');
      when(() => protocol.finishPasswordReset('reset', 'new-password'))
          .thenAnswer((_) => Future<void>.value());
      await pump(
        tester,
        fixture(protocol),
        CloudAccountAuthContent(
          onSignedIn: (_) => fail('Unexpected sign in'),
          onCancel: () => fail('Unexpected cancellation'),
          target: target,
          initialMode: .forgotPassword,
        ),
      );
      await tap(tester, 'Send reset code');
      expect(find.text(email), findsOneWidget);
      await tester.enterText(find.byType(EditableText).first, '654321');
      await tester.enterText(find.byType(EditableText).last, 'new-password');
      expect(
        tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
        isTrue,
      );
      await tap(tester, 'Reset password');
      expect(
        find.text('Password changed. Log in with your new password.'),
        findsOneWidget,
      );
      expect(find.text(email), findsOneWidget);
      expect(find.text('new-password'), findsNothing);
      verify(() => protocol.finishPasswordReset('reset', 'new-password'))
          .called(1);
    },
  );

  testWidgets(
    'unavailable delivery offers login and cancel without claiming a sent code',
    (tester) async {
      final protocol = _Protocol();
      await pump(
        tester,
        fixture(protocol, delivery: .unavailable),
        CloudAccountAuthContent(
          onSignedIn: (_) => fail('Unexpected sign in'),
          onCancel: () => fail('Unexpected cancellation'),
          target: target,
          initialMode: .register,
        ),
      );
      expect(find.textContaining('no email delivery'), findsOneWidget);
      expect(find.textContaining('server logs'), findsNothing);
      expect(
        tester
            .widget<AuraButton>(
              find.ancestor(
                of: find.text('Send code'),
                matching: find.byType(AuraButton),
              ),
            )
            .disabled,
        isTrue,
      );
      await tap(tester, 'Log in to existing account');
      expect(find.text('Log in'), findsWidgets);
      final _ = verifyNever(() => protocol.startRegistration(email));
    },
  );
  for (final cancel in [false, true]) {
    for (final safe in [false, true]) {
      testWidgets('auth return cancel=$cancel safe=$safe stays in workspace', (
        tester,
      ) async {
        final protocol = _Protocol();
        when(() => protocol.login(email, 'password'))
            .thenAnswer((_) async => result(origin));
        const destination =
            '/workspaces/w/more/service-connections?view=providers';
        const fallback = '/workspaces/w/more/cloud-accounts';
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/auth',
              builder: (_, state) => CloudAccountAuthScreen(
                workspaceId: 'w',
                returnPath: null,
                query: state.uri.queryParameters,
              ),
            ),
            GoRoute(
              path: '/workspaces/w/more/service-connections',
              builder: (_, _) => const Text('Connections destination'),
            ),
            GoRoute(
              path: fallback,
              builder: (_, _) => const Text('Accounts fallback'),
            ),
          ],
          initialLocation: Uri(
            path: '/auth',
            queryParameters: {
              'server-url': origin,
              'account-id': user,
              'email': email,
              'returnPath': safe ? destination : 'https://evil.example/steal',
            },
          ).toString(),
        );
        addTearDown(router.dispose);
        await pump(
          tester,
          fixture(protocol),
          const SizedBox.shrink(),
          router: router,
        );
        if (cancel) {
          await tap(tester, 'Cancel and return');
        } else {
          await tester.enterText(find.byType(EditableText).last, 'password');
          await tap(tester, 'Log in');
        }
        expect(router.state.uri.toString(), safe ? destination : fallback);
        expect(
          find.text(safe ? 'Connections destination' : 'Accounts fallback'),
          findsOneWidget,
        );
      });
    }
  }
  testWidgets('mode switches keep the edited email and clear passwords', (
    tester,
  ) async {
    final protocol = _Protocol();
    await pump(
      tester,
      fixture(protocol),
      CloudAccountAuthContent(
        onSignedIn: (_) => fail('Unexpected sign in'),
        onCancel: () => fail('Unexpected cancel'),
        target: const CloudAuthTarget(serverUrl: origin),
      ),
    );
    await tester.enterText(
      find.byType(EditableText).first,
      'edited@example.com',
    );
    await tester.enterText(find.byType(EditableText).last, 'private-password');
    await tap(tester, 'Forgot password?');
    expect(find.text('edited@example.com'), findsOneWidget);
    expect(find.text('private-password'), findsNothing);
    await tap(tester, 'Log in to existing account');
    expect(find.text('edited@example.com'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .controller
          .text,
      isEmpty,
    );
  });
}
