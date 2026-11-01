import 'dart:math';

import 'package:auravibes_server/src/features/objects/object_gateway_ledger.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Object gateway PostgreSQL ledger', (sessionBuilder, _) {
    test(
      'registration and pending operations survive ledger restart',
      () async {
        final key = _randomHex(24);
        final registrationId = _randomHex(32);
        final operationId = _randomHex(24);
        final firstSession = sessionBuilder.build();
        const firstLedger = PostgresObjectGatewayLedger();
        await firstLedger.register(firstSession, key, registrationId);
        await firstLedger.start(firstSession, key, registrationId, operationId);
        final initialStatus = await firstLedger.status(
          firstSession,
          key,
          registrationId,
        );
        expect(initialStatus.closed, isFalse);
        expect(initialStatus.pendingOperations, 1);
        await expectLater(
          firstLedger.status(firstSession, key, _randomHex(32)),
          throwsA(
            isA<ObjectGatewayLedgerException>().having(
              (error) => error.failure,
              'failure',
              ObjectGatewayLedgerFailure.unknown,
            ),
          ),
        );
        await firstSession.close();

        final restartedSession = sessionBuilder.build();
        const restartedLedger = PostgresObjectGatewayLedger();
        await restartedLedger.allow(restartedSession, key, registrationId);
        expect(
          await restartedLedger.close(restartedSession, key, registrationId),
          isFalse,
        );
        final closedStatus = await restartedLedger.status(
          restartedSession,
          key,
          registrationId,
        );
        expect(closedStatus.closed, isTrue);
        expect(closedStatus.pendingOperations, 1);
        await expectLater(
          restartedLedger.start(
            restartedSession,
            key,
            registrationId,
            _randomHex(24),
          ),
          throwsA(
            isA<ObjectGatewayLedgerException>().having(
              (error) => error.failure,
              'failure',
              ObjectGatewayLedgerFailure.closed,
            ),
          ),
        );
        await restartedSession.close();

        final nextSession = sessionBuilder.build();
        await restartedLedger.finish(nextSession, key, operationId);
        expect(
          await restartedLedger.close(nextSession, key, registrationId),
          isTrue,
        );
        final drainedStatus = await restartedLedger.status(
          nextSession,
          key,
          registrationId,
        );
        expect(drainedStatus.closed, isTrue);
        expect(drainedStatus.pendingOperations, 0);
        await nextSession.close();
      },
    );

    test('upload start and quiescence serialize on the key row', () async {
      final key = _randomHex(24);
      final registrationId = _randomHex(32);
      final operationId = _randomHex(24);
      final setupSession = sessionBuilder.build();
      const ledger = PostgresObjectGatewayLedger();
      await ledger.register(setupSession, key, registrationId);
      await setupSession.close();

      final uploadSession = sessionBuilder.build();
      final closeSession = sessionBuilder.build();
      final startResult = _capture(() async {
        await ledger.start(uploadSession, key, registrationId, operationId);
      });
      final closeResult = ledger.close(closeSession, key, registrationId);
      final results = await Future.wait<Object?>([startResult, closeResult]);
      final startError = results[0];
      final isQuiescent = results[1] as bool;

      if (startError == null) {
        expect(isQuiescent, isFalse);
        await ledger.finish(closeSession, key, operationId);
        expect(await ledger.close(closeSession, key, registrationId), isTrue);
      } else {
        expect(startError, isA<ObjectGatewayLedgerException>());
        expect(isQuiescent, isTrue);
      }

      await expectLater(
        ledger.allow(closeSession, key, registrationId),
        throwsA(
          isA<ObjectGatewayLedgerException>().having(
            (error) => error.failure,
            'failure',
            ObjectGatewayLedgerFailure.closed,
          ),
        ),
      );
      await expectLater(
        ledger.start(uploadSession, key, registrationId, _randomHex(24)),
        throwsA(
          isA<ObjectGatewayLedgerException>().having(
            (error) => error.failure,
            'failure',
            ObjectGatewayLedgerFailure.closed,
          ),
        ),
      );
      await uploadSession.close();
      await closeSession.close();
    });

    test(
      'nonce replay stays rejected after constructing a new ledger',
      () async {
        final key = _randomHex(24);
        final registrationId = _randomHex(32);
        final operationId = _randomHex(24);
        final session = sessionBuilder.build();
        const ledger = PostgresObjectGatewayLedger();
        await ledger.register(session, key, registrationId);
        await ledger.start(session, key, registrationId, operationId);
        await expectLater(
          const PostgresObjectGatewayLedger().start(
            session,
            key,
            registrationId,
            operationId,
          ),
          throwsA(
            isA<ObjectGatewayLedgerException>().having(
              (error) => error.failure,
              'failure',
              ObjectGatewayLedgerFailure.replay,
            ),
          ),
        );
        await session.close();
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}

Future<Object?> _capture(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } on Object catch (error) {
    return error;
  }
}

String _randomHex(int bytes) => List<int>.generate(
  bytes,
  (_) => Random.secure().nextInt(256),
).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
