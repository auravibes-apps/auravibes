import 'dart:async';

import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/check_cloud_account_usecase.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test(
    'availability and discovery share expired and unknown health by origin',
    () async {
      final one = CloudAccountKeyFactory.fromIdentity(
        'https://one.example',
        'same',
      );
      final two = CloudAccountKeyFactory.fromIdentity(
        'https://two.example',
        'same',
      );
      final calls = <CloudAccountKey>[];
      final container = ProviderContainer(
        overrides: [
          checkCloudAccountUsecaseProvider.overrideWith(
            (ref) => CheckCloudAccountUsecase(
              check: (key) async {
                calls.add(key);
                if (key == one) {
                  throw CloudWorkspaceException(code: .authenticationRequired);
                }
                throw StateError('offline fixture');
              },
            ),
          ),
          workspaceSessionForRouteProvider.overrideWith(
            (ref, id) async => WorkspaceSession(
              CloudWorkspaceRef(
                localWorkspaceId: id,
                serverUrl: id == 'one' ? one.serverUrl : two.serverUrl,
                accountId: 'same',
                cloudWorkspaceId: 11,
              ),
            ),
          ),
        ],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);
      final first = container.listen(
        workspaceAvailabilityProvider('one'),
        (_, _) => 0,
      );
      final second = container.listen(
        cloudWorkspaceStateProvider(one),
        (_, _) => 0,
      );
      final third = container.listen(
        workspaceAvailabilityProvider('two'),
        (_, _) => 0,
      );
      final fourth = container.listen(
        cloudWorkspaceStateProvider(two),
        (_, _) => 0,
      );
      addTearDown(first.close);
      addTearDown(second.close);
      addTearDown(third.close);
      addTearDown(fourth.close);
      expect(
        await container.read(workspaceAvailabilityProvider('one').future),
        isA<WorkspaceAuthenticationRequired>(),
      );
      expect(
        (await container.read(cloudWorkspaceStateProvider(one).future))
            ?.authenticationRequired,
        isTrue,
      );
      await expectLater(
        container.read(workspaceAvailabilityProvider('two').future),
        throwsA(isA<AppCloudWorkspaceException>()),
      );
      await expectLater(
        container.read(cloudWorkspaceStateProvider(two).future),
        throwsA(isA<AppCloudWorkspaceException>()),
      );
      expect(calls.where((key) => key == one), hasLength(1));
      expect(calls.where((key) => key == two), hasLength(1));
    },
  );

  test('canonical keys preserve origin for a shared account ID', () {
    expect(
      CloudAccountKeyFactory.fromIdentity('https://ONE.example/api', 'same'),
      (serverUrl: 'https://one.example', accountId: 'same'),
    );
    expect(
      CloudAccountKeyFactory.fromIdentity('https://one.example', 'same'),
      isNot(CloudAccountKeyFactory.fromIdentity('https://two.example', 'same')),
    );
  });

  test(
    'current user result verifies identity and records check time',
    () async {
      final check = CheckCloudAccountUsecase(
        check: (key) async => key.accountId,
      );
      final before = DateTime.now();
      final health = await check.call(
        CloudAccountKeyFactory.fromIdentity('https://one.example', 'same'),
      );
      expect(health.status, CloudAccountHealthStatus.verified);
      expect(health.checkedAt?.isBefore(before), isFalse);
    },
  );

  test(
    'expired, email-required, wrong user and unreachable remain distinct',
    () async {
      final key = CloudAccountKeyFactory.fromIdentity(
        'https://one.example',
        'same',
      );
      for (final code in [
        CloudWorkspaceErrorCode.authenticationRequired,
        CloudWorkspaceErrorCode.emailAccountRequired,
      ]) {
        final check = CheckCloudAccountUsecase(
          check: (_) async => throw CloudWorkspaceException(code: code),
        );
        expect(
          (await check.call(key)).status,
          CloudAccountHealthStatus.needsSignIn,
        );
      }
      expect(
        (await CheckCloudAccountUsecase(check: (_) async => 'other').call(key))
            .status,
        CloudAccountHealthStatus.needsSignIn,
      );
      expect(
        (await CheckCloudAccountUsecase(
          check: (_) async => throw StateError('offline'),
        ).call(key)).status,
        CloudAccountHealthStatus.unknown,
      );
    },
  );

  test(
    'loading is stored/checking and retry checks only selected origin',
    () async {
      final calls = <CloudAccountKey>[];
      final pending = Completer<String>();
      final first = CloudAccountKeyFactory.fromIdentity(
        'https://one.example',
        'same',
      );
      final second = CloudAccountKeyFactory.fromIdentity(
        'https://two.example',
        'same',
      );
      final container = ProviderContainer(
        overrides: [
          checkCloudAccountUsecaseProvider.overrideWith(
            (ref) => CheckCloudAccountUsecase(
              check: (key) async {
                calls.add(key);

                return key == first ? await pending.future : key.accountId;
              },
            ),
          ),
        ],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);
      final one = container.listen(
        cloudAccountHealthProvider(first),
        (_, _) => 0,
      );
      final two = container.listen(
        cloudAccountHealthProvider(second),
        (_, _) => 0,
      );
      addTearDown(one.close);
      addTearDown(two.close);
      expect(
        container.read(cloudAccountHealthProvider(first)).isLoading,
        isTrue,
      );
      pending.complete('same');
      final _ = await container.read(cloudAccountHealthProvider(first).future);
      final _ = await container.read(cloudAccountHealthProvider(second).future);
      container.invalidate(cloudAccountHealthProvider(first));
      final _ = await container.read(cloudAccountHealthProvider(first).future);
      expect(calls.where((key) => key == first), hasLength(2));
      expect(calls.where((key) => key == second), hasLength(1));
    },
  );
}
