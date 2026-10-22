part of '../widgets/ux_validation_layout_test.dart';

void _registerIntroJourneyCaptures() {
  for (final locale in ['en', 'es']) {
    for (final mobile in [false, true]) {
      testWidgets('Intro journey forms and recovery $locale mobile=$mobile', (
        tester,
      ) async {
        final journey = await _IntroCapture.create(
          tester,
          locale,
          mobile: mobile,
        );
        for (var page = 1; page <= 3; page++) {
          await journey.capture('Welcome$page');
          await journey.tapKey('intro_welcome_next_button');
        }
        await journey.capture('Chooser');
        await journey.tapKey('intro_route_local_button');
        await journey.capture('LocalName');
        await tester.enterText(find.byType(AuraInput), 'ab');
        await journey.tapKey('intro_create_workspace_button');
        await journey.capture('NameValidation');
        await tester.enterText(find.byType(AuraInput), 'Design studio');
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await journey.capture('LocalKeyboard');
        tester.view.resetViewInsets();
        await journey.tapKey('intro_back_to_route_chooser_button');
        journey
          ..accountsLoad = (() async => [_journeyAccount])
          ..discoveryLoad = (() async => const .authenticationRequired())
          ..container.invalidate(cloudAccountsProvider);
        await journey.tapKey('intro_connect_existing_button');
        await journey.tapText('cloud_accounts.session_expired');
        await journey.capture('SignIn');
        await tester.enterText(find.byType(EditableText).first, _journeyEmail);
        await tester.enterText(
          find.byType(EditableText).last,
          'fixture-password',
        );
        final login = Completer<CloudAuthResult>();
        when(() => journey.protocol.login(any(), any()))
            .thenAnswer((_) => login.future);
        final loginButton = find.widgetWithText(
          AuraButton,
          'workspace_management.cloud_login'.tr(),
        );
        expect(tester.widget<AuraButton>(loginButton).disabled, isFalse);
        await journey.tap(loginButton);
        await journey.capture('SignInWaiting');
        verify(() => journey.protocol.login(any(), any())).called(1);
        final cancel = find.widgetWithText(
          AuraButton,
          'cloud_accounts.cancel_auth'.tr(),
        );
        expect(tester.widget<AuraButton>(cancel).disabled, isTrue);
        login.completeError(const CloudAuthFailure('cloud_errors.unavailable'));
        await journey.capture('SignInError');
        await journey.tapText('cloud_accounts.create_new');
        await journey.capture('Register');
        await tester.enterText(find.byType(EditableText).first, _journeyEmail);
        await tester.enterText(
          find.byType(EditableText).last,
          'fixture-password',
        );
        when(() => journey.protocol.startRegistration(any()))
            .thenAnswer((_) async => _journeyRequest);
        await journey.tapText('workspace_management.cloud_register');
        await journey.capture('RegistrationCode');
        await journey.tapText('cloud_accounts.resend_code');
        await journey.capture('RegistrationResent');
        final codeCheck = Completer<String>();
        when(() => journey.protocol.verifyRegistrationCode(any(), any()))
            .thenAnswer((_) => codeCheck.future);
        await tester.enterText(find.byType(EditableText), '123456');
        await journey.tapText('workspace_management.cloud_finish_register');
        await journey.capture('RegistrationVerificationWaiting');
        codeCheck.completeError(
          const CloudAuthFailure('cloud_accounts.code_invalid_error'),
        );
        await journey.capture('RegistrationCodeError');
        await journey.tapText('cloud_accounts.edit_email');
        await journey.capture('RegistrationEditEmail');
        await journey.tapText('cloud_accounts.login_existing');
        await journey.tapText('cloud_accounts.forgot_password');
        await journey.capture('PasswordRecovery');
        when(() => journey.protocol.startPasswordReset(any()))
            .thenAnswer((_) async => _journeyRequest);
        await journey.tapText('cloud_accounts.send_password_reset_code');
        await journey.capture('PasswordResetCode');
        await journey.tapText('cloud_accounts.resend_code');
        await journey.capture('PasswordResetResent');
        when(() => journey.protocol.verifyPasswordResetCode(any(), any()))
            .thenAnswer((_) async => 'fixture-reset');
        when(() => journey.protocol.finishPasswordReset(any(), any()))
            .thenAnswer((_) => Future<void>.value());
        await tester.enterText(find.byType(EditableText).first, '123456');
        await tester.enterText(
          find.byType(EditableText).last,
          'fixture-password',
        );
        await journey.tapText('cloud_accounts.finish_password_reset');
        await journey.capture('PasswordChanged');
        await journey.tapText('cloud_accounts.cancel_auth');
        await journey.tapKey('workspace_setup_back_to_creation_button');
        final accountsWaiting = Completer<List<CloudAccountSession>>();
        journey.accountsLoad = () => accountsWaiting.future;
        journey.container.invalidate(cloudAccountsProvider);
        await journey.tapKey('intro_route_cloud_button');
        expect(find.text('Design studio'), findsOneWidget);
        await journey.capture('CloudDraftRestored');
        await journey.capture('CloudAccountsWaiting');
        accountsWaiting.completeError(StateError('fixture account storage'));
        await journey.capture('CloudAccountsError');
        journey.accountsLoad = () async => [_journeyAccount];
        journey.container.invalidate(cloudAccountsProvider);
        await journey.capture('CloudAccountAvailable');
        await journey.tap(
          find
              .descendant(
                of: find.byType(AuraDropdownSelector<String>),
                matching: find.byType(AuraPressable),
              )
              .first,
        );
        await journey.tap(
          find.text('$_journeyEmail (${_journeyAccount.serverUrl})').last,
        );
        await journey.capture('CloudAccountSelected');
        await journey.tapKey('intro_create_workspace_button');
        await journey.capture('CloudCreateWaiting');
        journey.createPending.completeError(
          const AppCloudWorkspaceException('cloud_errors.unavailable'),
        );
        await journey.capture('CloudCreateError');
        journey.createPending = Completer<CloudWorkspaceSummary>();
        await journey.tapKey('intro_create_workspace_button');
        journey.createPending.complete(_journeySummary());
        await journey.capture('CloudCreated');
        expect(find.text('intro_flow.ready.title'.tr()), findsOneWidget);
        await journey.close();
      });
      testWidgets('Intro exploration $locale mobile=$mobile', (tester) async {
        final journey = await _IntroCapture.create(
          tester,
          locale,
          mobile: mobile,
        );
        await journey.tapKey('intro_welcome_skip_button');
        await journey.tapKey('intro_route_local_button');
        await tester.enterText(find.byType(AuraInput), 'Design studio');
        await journey.tapKey('intro_create_workspace_button');
        await journey.tapKey('intro_skip_ai_button');
        expect(find.byType(NewChatScreen), findsOneWidget);
        final id =
            (await journey.fixture.database.workspaceDao.getAllWorkspaces())
                .single
                .id;
        final container = ProviderScope.containerOf(
          tester.element(find.byType(NewChatScreen)),
          listen: false,
        );
        expect(container.read(newChatProvider(id)).modelId, isNull);
        await journey.capture('ExploreWithoutAI');
        await journey.close();
      });
      testWidgets('Intro journey discovery $locale mobile=$mobile', (
        tester,
      ) async {
        final journey = await _IntroCapture.create(
          tester,
          locale,
          mobile: mobile,
        );
        journey.accountsLoad = () async => [_journeyAccount];
        journey.container.invalidate(cloudAccountsProvider);
        final waiting = Completer<CloudWorkspaceViewState?>();
        journey.discoveryLoad = () => waiting.future;
        await journey.tapKey('intro_welcome_skip_button');
        await journey.tapKey('intro_connect_existing_button');
        await journey.capture('DiscoveryWaiting');
        waiting.completeError(StateError('fixture offline'));
        await journey.capture('DiscoveryError');
        journey.discoveryLoad = () async => const .authenticationRequired();
        await journey.tapText('workspace_management.cloud_retry');
        await journey.capture('DiscoverySignInRequired');
        await journey.tapText('cloud_accounts.session_expired');
        await journey.capture('DiscoveryReauthentication');
        await journey.tapText('cloud_accounts.cancel_auth');
        journey.discoveryLoad = () async =>
            const .new(workspaces: [], pendingInvites: []);
        journey.container.invalidate(cloudWorkspaceStateProvider);
        await journey.capture('DiscoveryEmpty');
        await journey.tapText('intro_flow.choice.cloud_create_title');
        await journey.capture('DiscoveryCreateCloud');
        await journey.tapKey('intro_back_to_route_chooser_button');
        await journey.tapKey('intro_connect_existing_button');
        journey.discoveryLoad = () async =>
            .new(workspaces: [_journeySummary()], pendingInvites: []);
        journey.container.invalidate(cloudWorkspaceStateProvider);
        await journey.capture('DiscoveryAvailable');
        await journey.tapText('cloud_accounts.connect_workspace_action');
        await journey.capture('WorkspaceConnected');
        expect(
          find.text('intro_flow.ready.connected_title'.tr()),
          findsOneWidget,
        );
        await journey.close();
        for (final accept in [false, true]) {
          final invites = await _IntroCapture.create(
            tester,
            locale,
            mobile: mobile,
          );
          invites.accountsLoad = () async => [_journeyAccount];
          invites.container.invalidate(cloudAccountsProvider);
          var responded = false;
          invites.discoveryLoad = () async => .new(
            workspaces: [],
            pendingInvites: responded
                ? []
                : [
                    PendingWorkspaceInviteSummary(
                      id: 7,
                      workspaceId: 11,
                      workspaceName: 'Design studio',
                      email: _journeyEmail,
                      role: 'member',
                      revision: 2,
                      createdAt: .new(2026),
                    ),
                  ],
          );
          when(() => invites.endpoint.acceptInvite(any()))
              .thenAnswer((_) async {
                responded = true;

                return _journeySummary();
              });
          when(() => invites.endpoint.declineInvite(any())).thenAnswer((_) {
            responded = true;

            return Future<void>.value();
          });
          await invites.tapKey('intro_welcome_skip_button');
          await invites.tapKey('intro_connect_existing_button');
          await invites.capture('Invitation${accept ? 'Accept' : 'Decline'}');
          await invites.tapText(
            accept
                ? 'workspace_management.cloud_accept'
                : 'workspace_management.cloud_decline',
          );
          await invites.capture(
            accept ? 'WorkspaceJoined' : 'InvitationDeclined',
          );
          expect(responded, isTrue);
          await invites.close();
        }
      });
      testWidgets(
        'Intro journey AI save cancel recovery $locale mobile=$mobile',
        (tester) async {
          final journey = await _IntroCapture.create(
            tester,
            locale,
            mobile: mobile,
          );
          await journey.tapKey('intro_welcome_skip_button');
          await journey.tapKey('intro_route_local_button');
          await tester.enterText(find.byType(AuraInput), 'Design studio');
          await journey.tapKey('intro_create_workspace_button');
          await journey.capture('LocalCreatedNoAI');
          final id =
              (await journey.fixture.database.workspaceDao.getAllWorkspaces())
                  .single
                  .id;
          await journey.tapKey('workspace_add_model_provider');
          expect(
            find.text(
              'chats_screens.chat_conversation.select_model_selctor'.tr(),
            ),
            findsNothing,
          );
          await journey.capture('ProviderChoice');
          await journey.tap(find.text('OpenAI').last);
          await journey.capture('ProviderCredentials');
          await tester.enterText(
            find.byType(EditableText).at(1),
            'fixture-api-key',
          );
          final verification = Completer<ModelProviderVerification>();
          ModelProviderVerificationRequest? request;
          when(() => journey.modelStore.verifyModelConnection(any()))
              .thenAnswer((call) {
                request =
                    call.positionalArguments.single
                        as ModelProviderVerificationRequest;

                return verification.future;
              });
          await journey.tapText('mcp_modal.test_connection');
          await journey.capture('ProviderVerifyWaiting');
          verification.completeError(
            const ModelConnectionException('Fixture connection rejected'),
          );
          await journey.capture('ProviderVerifyError');
          when(() => journey.modelStore.verifyModelConnection(any()))
              .thenAnswer(
                (call) async => ModelProviderVerification.fromRequest(
                  request:
                      call.positionalArguments.single
                          as ModelProviderVerificationRequest,
                  modelIds: ['fixture-model'],
                ),
              );
          await journey.tapText('mcp_modal.test_connection');
          await journey.capture('ProviderVerified');
          expect(request?.workspaceId, id);
          var saving = Completer<ModelConnectionEntity>();
          when(
            () => journey.modelStore.createModelConnection(
              any(),
              verification: any(named: 'verification'),
            ),
          ).thenAnswer((_) => saving.future);
          await journey.tapText('models_screens.add_provider.open_button');
          await journey.capture('ProviderSaveWaiting');
          saving.completeError(
            const ModelConnectionException('Fixture provider save unavailable'),
          );
          await journey.capture('ProviderSaveError');
          saving = Completer<ModelConnectionEntity>();
          await journey.tapText('models_screens.add_provider.open_button');
          final model = _journeyModel(id);
          journey
            ..connections = [model.modelConnection]
            ..models = {
              'connection': [model],
            };
          saving.complete(model.modelConnection);
          await journey.capture('ProviderSavedChooseModel');
          expect(find.text('intro_flow.ready.title'.tr()), findsOneWidget);
          final pendingModels =
              Completer<
                Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
              >();
          journey.modelsLoad = () => Stream.fromFuture(pendingModels.future);
          journey.container.invalidate(listModelsGroupedByProviderProvider);
          await journey.capture('ModelsWaiting');
          pendingModels.completeError(StateError('fixture model availability'));
          await journey.capture('ModelsError');
          journey.models = {};
          journey.modelsLoad = () => Stream.value(journey.models);
          journey.container.invalidate(listModelsGroupedByProviderProvider);
          await journey.capture('ModelsUnavailable');
          journey.connections = [model.modelConnection.copyWith(hasKey: false)];
          journey.container.invalidate(chatModelConnectionsProvider);
          await journey.capture('CredentialsRequired');
          await journey.tapText('chat_readiness.review_connections');
          await journey.capture('ReviewConnections');
          await journey.tapText('common.edit');
          await journey.capture('EditConnection');
          await journey.tap(find.byType(AuraIconButton).last);
          await journey.capture('ConnectionEditCancelled');
          final frames = find.byType(SetupPageFrame);
          final frame = tester.widget<SetupPageFrame>(frames.last);
          frame.page.onBack?.call();
          await journey.pump();
          journey
            ..connections = [model.modelConnection]
            ..models = {
              'connection': [model],
            };
          journey.container.invalidate(chatModelConnectionsProvider);
          journey.container.invalidate(listModelsGroupedByProviderProvider);
          await journey.capture('ModelsAvailable');
          await journey.tap(
            find
                .descendant(
                  of: find.byType(AuraDropdownSelector<String>),
                  matching: find.byType(AuraPressable),
                )
                .first,
          );
          await journey.capture('ModelOptions');
          await journey.tap(find.text('Fixture model').last);
          await journey.capture('ModelSelected');
          expect(
            tester
                .widget<AuraButton>(
                  find.byKey(const Key('intro_start_chat_button')),
                )
                .disabled,
            isFalse,
          );
          // Provider cancellation stays within the committed workspace.
          tester
              .widget<ChatReadinessSummary>(find.byType(ChatReadinessSummary))
              .onAddProvider
              ?.call();
          await journey.pump();
          await journey.tap(find.text('OpenAI').last);
          await journey.tapText('common.cancel');
          await journey.capture('ProviderDiscardPrompt');
          await journey.tapText('common.discard_changes');
          await journey.capture('ProviderCancelled');
          tester
              .widget<ChatReadinessSummary>(find.byType(ChatReadinessSummary))
              .onAddProvider
              ?.call();
          await journey.pump();
          await journey.tap(
            find.text(ModelProviderOAuthProfiles.displayName).last,
          );
          await journey.capture('ProviderOAuth');
          if (!mobile) {
            final browser = Completer<OAuthTokenEntity>();
            when(
              () => journey.oauth.authenticateWithBrowser(
                isCancelled: any(named: 'isCancelled'),
              ),
            ).thenAnswer((_) => browser.future);
            await journey.tapText(
              'models_screens.add_provider.connect_browser',
            );
            await journey.capture('OAuthBrowserWaiting');
            await journey.tapText(
              'models_screens.add_provider.cancel_connection',
            );
            browser.completeError(const CodexOAuthCanceledException());
            await journey.capture('OAuthBrowserCancelled');
          }
          final oauth = Completer<OAuthTokenEntity>();
          when(
            () => journey.oauth.authenticateWithDeviceCode(
              onDeviceCode: any(named: 'onDeviceCode'),
              isCancelled: any(named: 'isCancelled'),
            ),
          ).thenAnswer((call) {
            (call.namedArguments[#onDeviceCode]
                    as void Function(CodexDeviceCode)?)
                ?.call(
                  const CodexDeviceCode(
                    verificationUrl: 'https://fixture.example/device',
                    userCode: 'SAMPLE-CODE',
                  ),
                );

            return oauth.future;
          });
          await journey.tapText('models_screens.add_provider.use_device_code');
          await journey.capture('OAuthDeviceWaiting');
          await journey.tapText(
            'models_screens.add_provider.cancel_connection',
          );
          oauth.completeError(const CodexOAuthCanceledException());
          await journey.capture('OAuthCancelled');
          await journey.tapText('common.cancel');
          await journey.tapText('common.discard_changes');
          await journey.capture('ReadyAfterOAuthCancel');
          await journey.tapKey('intro_start_chat_button');
          await journey.pump();
          expect(find.byType(NewChatScreen), findsOneWidget);
          final chatContainer = ProviderScope.containerOf(
            tester.element(find.byType(NewChatScreen)),
            listen: false,
          );
          expect(chatContainer.read(newChatProvider(id)).modelId, 'selection');
          await journey.capture('ChatChosenModel');
          await journey.close();
        },
      );
    }
  }
}

const _journeyEmail = 'reviewer@example.test';
const _journeyUser = '11111111-1111-4111-8111-111111111111';
const _journeyAccount = CloudAccountSession(
  serverUrl: 'https://fixture.example',
  userId: _journeyUser,
  email: _journeyEmail,
);
final _journeyRequest = UuidValue.fromString(_journeyUser);
class _JourneyProtocol extends Mock implements CloudAuthProtocol;
class _JourneyClient extends Mock implements Client;
class _JourneyEndpoint extends Mock implements EndpointCloudWorkspace;
class _JourneyModelStore extends Mock implements ModelConnectionStore;
class _JourneyCatalog extends Mock implements ModelCatalogStore;
class _JourneySelections extends Mock implements ModelSelectionStore;
class _JourneyOAuth extends Mock implements CodexOAuthService;

class _IntroCapture {
  new(this.tester, this.fixture, this.locale, {required this.mobile});
  final WidgetTester tester;
  final UxValidationFixture fixture;
  final String locale;
  final bool mobile;
  final protocol = _JourneyProtocol();
  final client = _JourneyClient();
  final endpoint = _JourneyEndpoint();
  final modelStore = _JourneyModelStore();
  final catalog = _JourneyCatalog();
  final selections = _JourneySelections();
  final oauth = _JourneyOAuth();
  Future<List<CloudAccountSession>> Function() accountsLoad = () async => [];
  Future<CloudWorkspaceViewState?> Function() discoveryLoad = () async =>
      const .new(workspaces: [], pendingInvites: []);
  Completer<CloudWorkspaceSummary> createPending = .new();
  List<ModelConnectionEntity> connections = [];
  Map<String, List<WorkspaceModelSelectionWithConnectionEntity>> models = {};
  Stream<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>
  Function()?
  modelsLoad;

  Size get size => mobile ? const Size(360, 640) : const Size(1280, 1200);
  double get scale => mobile ? 1.8 : 1;
  ProviderContainer get container => ProviderScope.containerOf(
    tester.element(find.byKey(const Key('ux-capture'))),
    listen: false,
  );

  static Future<_IntroCapture> create(
    WidgetTester tester,
    String locale, {
    required bool mobile,
  }) async {
    debugDefaultTargetPlatformOverride = mobile
        ? TargetPlatform.android
        : TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    FlutterSecureStorage.setMockInitialValues({});
    registerFallbackValue(_journeyRequest);
    registerFallbackValue(
      const ModelProviderVerificationRequest(
        workspaceId: 'fixture',
        providerId: 'openai',
        connectionId: null,
        expectedRevision: null,
        url: null,
        key: null,
      ),
    );
    registerFallbackValue(
      const ModelConnectionToCreate(
        name: 'OpenAI',
        workspaceId: 'fixture',
        modelId: 'openai',
        key: 'fixture-key',
      ),
    );
    registerFallbackValue(
      CreateCloudWorkspaceRequest(name: 'Design studio', requestId: 'fixture'),
    );
    registerFallbackValue(
      AcceptWorkspaceInviteRequest(
        inviteId: 7,
        requestId: 'fixture',
        expectedInviteRevision: 2,
      ),
    );
    registerFallbackValue(
      DeclineWorkspaceInviteRequest(
        inviteId: 7,
        requestId: 'fixture',
        expectedInviteRevision: 2,
      ),
    );
    final fixture = await UxValidationFixture.create(empty: true);
    final journey = _IntroCapture(tester, fixture, locale, mobile: mobile);
    final logo = await const SvgStringLoader(
      '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><circle cx="10" cy="10" r="8"/></svg>',
    ).loadBytes(null);
    for (final provider in ['openai', ModelProviderOAuthProfiles.providerId]) {
      final loader = SvgNetworkLoader('https://models.dev/logos/$provider.svg');
      final _ = await svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () async => logo,
      );
    }
    when(() => journey.catalog.getModelsByProvider('openai')).thenAnswer(
      (_) async => const [
        ApiModelEntity(
          modelProvider: 'openai',
          id: 'fixture-model',
          name: 'Fixture model',
          limitContext: 32000,
          limitOutput: 4000,
          modalitiesInput: ['text'],
          modalitiesOutput: ['text'],
          supportsPriorityMode: true,
        ),
      ],
    );
    when(() => journey.selections.getById(any())).thenAnswer(
      (_) async => journey.models.values.expand((group) => group).firstOrNull,
    );
    when(() => journey.modelStore.getModelConnectionForEdit(any())).thenAnswer(
      (_) async => ModelConnectionForEdit(
        id: 'connection',
        name: 'OpenAI',
        modelId: 'openai',
        workspaceId: journey.connections.first.workspaceId,
        hasKey: true,
      ),
    );
    when(() => journey.client.cloudWorkspace).thenReturn(journey.endpoint);
    when(() => journey.endpoint.createWorkspace(any()))
        .thenAnswer((_) => journey.createPending.future);
    final usecases = CloudAccountUseCases(
      store: .new(),
      workspaceRepository: .new(fixture.database),
      deleteRemoteAccount: ({required serverUrl, required userId}) =>
          Future<void>.value(),
      invalidateAccount: (serverUrl, userId) {
        expect(serverUrl, isNotEmpty);
        expect(userId, isNotEmpty);
      },
      createAuthProtocol: (_) => journey.protocol,
      emailDelivery: .email,
    );
    final _ = await fixture.pump(
      tester,
      '/intro',
      locale: locale,
      size: journey.size,
      scale: journey.scale,
      realSessions: true,
      emptyModels: false,
      accountsLoad: () => journey.accountsLoad(),
      overrides: [
        cloudAccountUseCasesProvider.overrideWithValue(usecases),
        cloudEmailDeliveryProvider.overrideWithValue(.email),
        cloudWorkspaceStateProvider.overrideWith(
          (ref, key) => journey.discoveryLoad(),
        ),
        cloudWorkspaceUseCasesProvider.overrideWith(
          (ref, key) async => CloudWorkspaceUseCases(
            cloudRepository: .new(journey.client),
            workspaceRepository: .new(fixture.database),
            cloudAccountId: key.accountId,
            serverUrl: key.serverUrl,
          ),
        ),
        chatModelConnectionsProvider.overrideWith(
          (ref, id) => Stream.value(journey.connections),
        ),
        listModelsGroupedByProviderProvider.overrideWith(
          (ref, id) =>
              journey.modelsLoad?.call() ?? Stream.value(journey.models),
        ),
        modelConnectionStoreProvider.overrideWith(
          (ref, id) async => journey.modelStore,
        ),
        modelCatalogStoreProvider.overrideWith(
          (ref, id) async => journey.catalog,
        ),
        modelSelectionStoreProvider.overrideWith(
          (ref, id) async => journey.selections,
        ),
        codexOAuthServiceProvider.overrideWithValue(journey.oauth),
        apiModelProvidersProvider.overrideWith(
          (ref, id) async => const [
            ApiModelProviderEntity(id: 'openai', name: 'OpenAI', type: .openai),
            ApiModelProviderEntity(
              id: ModelProviderOAuthProfiles.providerId,
              name: ModelProviderOAuthProfiles.displayName,
              type: .openai,
            ),
          ],
        ),
      ],
    );

    return journey;
  }

  Future<void> pump() async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> capture(String stage) async {
    await pump();
    await _capture(
      tester,
      'Intro-$stage-$locale-${mobile ? 'mobile' : 'desktop'}',
      container
          .read(routerProvider)
          .routeInformationProvider
          .value
          .uri
          .toString(),
      locale: locale,
      size: size,
      scale: scale,
      dark: false,
    );
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await pump();
  }

  Future<void> tapKey(String key) => tap(find.byKey(.new(key)));
  Future<void> tapText(String key) => tap(find.text(key.tr()).last);
  Future<void> close() async {
    await fixture.close(tester);
    debugDefaultTargetPlatformOverride = null;
  }
}

WorkspaceModelSelectionWithConnectionEntity _journeyModel(String workspaceId) =>
    .new(
      workspaceModelSelection: .new(
        id: 'selection',
        modelId: 'fixture-model',
        modelName: 'Fixture model',
        modelConnectionId: 'connection',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        modalitiesInput: ['text'],
        modalitiesOutput: ['text'],
      ),
      modelConnection: .new(
        id: 'connection',
        name: 'OpenAI',
        modelId: 'openai',
        workspaceId: workspaceId,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        hasKey: true,
      ),
      modelsProvider: const .new(id: 'openai', name: 'OpenAI', type: .openai),
    );

CloudWorkspaceSummary _journeySummary() => CloudWorkspaceSummary(
  id: 11,
  name: 'Design studio',
  role: 'owner',
  revision: 1,
  sequence: 1,
  createdAt: .new(2026),
  updatedAt: .new(2026),
);
