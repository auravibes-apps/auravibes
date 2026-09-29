import 'package:auravibes_app/features/cloud_accounts/screens/cloud_account_login_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_forgot_password_form.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_login_form.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_register_form.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  ProviderContainer submissionContainer(void Function() onRead) =>
      ProviderContainer(
        overrides: [
          cloudAccountUseCasesProvider.overrideWith((_) {
            onRead();
            throw StateError('Test submission reached');
          }),
        ],
      );

  Widget wrapProviderScope(ProviderContainer? container, Widget child) =>
      container == null
      ? ProviderScope(child: child)
      : UncontrolledProviderScope(container: container, child: child);

  Future<void> pumpForm(
    WidgetTester tester,
    Widget form, {
    bool screen = false,
    ProviderContainer? container,
  }) async {
    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        wrapProviderScope(
          container,
          EasyLocalization(
            child: Builder(
              builder: (context) => AuraThemeScope(
                theme: .light,
                child: MaterialApp(
                  home: screen
                      ? form
                      : Scaffold(body: SingleChildScrollView(child: form)),
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
            supportedLocales: const [Locale('en')],
            path: 'assets/i18n',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('en'),
            useOnlyLangCode: true,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
  }

  testWidgets('password reset focuses its only initial field', (tester) async {
    await pumpForm(
      tester,
      CloudAccountForgotPasswordForm(
        onFinished: () => fail('Unexpected reset completion'),
      ),
    );

    expect(tester.widget<AuraInput>(find.byType(AuraInput)).autofocus, isTrue);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('login advances to password and submits once from Done', (
    tester,
  ) async {
    var submissionCount = 0;
    final container = submissionContainer(() => submissionCount++);
    addTearDown(container.dispose);
    await pumpForm(
      tester,
      CloudAccountLoginForm(
        onSignedIn: (_) => fail('Unexpected sign in completion'),
      ),
      container: container,
    );

    final inputs = find.byType(EditableText);
    final passwordFocus = tester.widget<EditableText>(inputs.at(1)).focusNode;
    final actions = tester.widgetList<AuraInput>(find.byType(AuraInput));
    expect(actions.map((input) => input.textInputAction), <TextInputAction>[
      TextInputAction.next,
      TextInputAction.done,
    ]);

    await tester.tap(inputs.first);
    await tester.pump();
    final _ = await tester.testTextInput.receiveAction(.next);
    final _ = await tester.pumpAndSettle();
    expect(passwordFocus.hasFocus, isTrue);

    final _ = await tester.testTextInput.receiveAction(.done);
    final _ = await tester.pumpAndSettle();
    expect(submissionCount, 1);
  });

  testWidgets('registration uses Next then Done and submits once', (
    tester,
  ) async {
    var submissionCount = 0;
    final container = submissionContainer(() => submissionCount++);
    addTearDown(container.dispose);
    await pumpForm(
      tester,
      CloudAccountRegisterForm(
        onSignedIn: (_) => fail('Unexpected registration completion'),
      ),
      container: container,
    );

    final actions = tester.widgetList<AuraInput>(find.byType(AuraInput));
    expect(actions.map((input) => input.textInputAction), <TextInputAction>[
      TextInputAction.next,
      TextInputAction.done,
    ]);
    await tester.tap(find.byType(EditableText).last);
    await tester.pump();
    final _ = await tester.testTextInput.receiveAction(.done);
    final _ = await tester.pumpAndSettle();
    expect(submissionCount, 1);
  });

  testWidgets('password reset uses Done and submits once', (tester) async {
    var submissionCount = 0;
    final container = submissionContainer(() => submissionCount++);
    addTearDown(container.dispose);
    await pumpForm(
      tester,
      CloudAccountForgotPasswordForm(
        onFinished: () => fail('Unexpected reset completion'),
      ),
      container: container,
    );

    expect(
      tester.widget<AuraInput>(find.byType(AuraInput)).textInputAction,
      TextInputAction.done,
    );
    final _ = await tester.testTextInput.receiveAction(.done);
    final _ = await tester.pumpAndSettle();
    expect(submissionCount, 1);
  });

  testWidgets('registration initial multi-field step does not autofocus', (
    tester,
  ) async {
    await pumpForm(
      tester,
      CloudAccountRegisterForm(
        onSignedIn: (_) => fail('Unexpected registration completion'),
      ),
    );

    final fields = tester.widgetList<AuraInput>(find.byType(AuraInput));
    expect(fields, hasLength(2));
    expect(fields.every((field) => !field.autofocus), isTrue);
  });

  testWidgets('dragging a cloud login form dismisses its focused field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpForm(
      tester,
      const CloudAccountLoginScreen(workspaceId: 'ws', returnPath: null),
      screen: true,
    );

    final input = find.byType(EditableText).first;
    await tester.tap(input);
    await tester.pump();
    final focusNode = tester.widget<EditableText>(input).focusNode;
    expect(focusNode.hasFocus, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });
}
