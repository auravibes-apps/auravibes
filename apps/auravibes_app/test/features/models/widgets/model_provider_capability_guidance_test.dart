import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  for (final isCloud in [false, true]) {
    for (final platform in [TargetPlatform.android, TargetPlatform.linux]) {
      testWidgets('Codex guidance reflects $platform and cloud=$isCloud', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          await tester.binding.setSurfaceSize(const Size(1000, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final workspace = isCloud
              ? const CloudWorkspaceRef(
                  localWorkspaceId: 'test-workspace',
                  serverUrl: 'https://example.test',
                  accountId: 'account',
                  cloudWorkspaceId: 1,
                )
              : const LocalWorkspaceRef(localWorkspaceId: 'test-workspace');
          await tester.runAsync(() async {
            final bytes = await const SvgStringLoader(
              '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><circle cx="10" cy="10" r="8"/></svg>',
            ).loadBytes(null);
            const loader = SvgNetworkLoader(
              'https://models.dev/logos/openai-codex.svg',
            );
            final _ = await svg.cache.putIfAbsent(
              loader.cacheKey(null),
              () async => bytes,
            );
            await tester.pumpWidget(
              TestableApp(
                child: const Scaffold(
                  body: AddModelProviderWidget(
                    workspaceId: 'test-workspace',
                    showHeader: false,
                  ),
                ),
                overrides: [
                  addModelProviderStateProvider.overrideWith2(
                    (_) => _CodexDraft(),
                  ),
                  apiModelProvidersProvider.overrideWith(
                    (_, _) async => const [
                      ApiModelProviderEntity(
                        id: ModelProviderOAuthProfiles.providerId,
                        name: 'Codex',
                        type: .openai,
                      ),
                    ],
                  ),
                ],
                workspaceSession: .new(workspace),
              ),
            );
          });
          final _ = await tester.pumpAndSettle();
          expect(
            find.text('Connect with browser'),
            platform == .linux ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('Use device code'),
            isCloud ? findsNothing : findsOneWidget,
          );
          expect(
            find.textContaining('Browser sign-in requires'),
            platform == .android ? findsOneWidget : findsNothing,
          );
          expect(
            find.textContaining('Device sign-in is unavailable'),
            isCloud ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}

class _CodexDraft extends AddModelProviderState {
  @override
  AddModelProviderModel build(String workspaceId) {
    final _ = super.build(workspaceId);

    return const AddModelProviderModel(
      name: 'Codex account',
      modelId: ModelProviderOAuthProfiles.providerId,
      authMode: .oauth2,
    );
  }
}
