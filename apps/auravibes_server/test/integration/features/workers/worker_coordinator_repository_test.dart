import 'package:auravibes_server/src/features/workers/worker_coordinator_repository.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('WorkerCoordinatorRepository', (sessionBuilder, _) {
    test('renewal keeps the coordinator fencing token', () async {
      final session = sessionBuilder.build();
      final repository = const WorkerCoordinatorRepository();

      final initial = await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      );
      final renewed = await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      );

      expect(renewed!.fencingToken, initial!.fencingToken);
    });

    test('an expired coordinator lease increments the fencing token', () async {
      final session = sessionBuilder.build();
      final repository = const WorkerCoordinatorRepository();
      final initial = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      ))!;
      await _expireCoordinator(session);

      final takeover = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-b',
      ))!;

      expect(takeover.fencingToken, initial.fencingToken + 1);
    });

    test(
      'only one concurrent contender takes an expired coordinator lease',
      () async {
        final firstSession = sessionBuilder.build();
        final secondSession = sessionBuilder.build();
        final repository = const WorkerCoordinatorRepository();
        await repository.acquireCoordinator(firstSession, ownerId: 'expired');
        await _expireCoordinator(firstSession);

        final results = await Future.wait([
          repository.acquireCoordinator(firstSession, ownerId: 'server-a'),
          repository.acquireCoordinator(secondSession, ownerId: 'server-b'),
        ]);

        expect(results.whereType<WorkerCoordinatorLease>(), hasLength(1));
      },
    );

    test('an expired same-owner lease increments the fencing token', () async {
      final session = sessionBuilder.build();
      final repository = const WorkerCoordinatorRepository();
      final initial = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      ))!;
      await _expireCoordinator(session);

      final reacquired = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      ))!;

      expect(reacquired.fencingToken, initial.fencingToken + 1);
    });

    test('a re-fenced same owner cannot renew an older claimed run', () async {
      final session = sessionBuilder.build();
      final repository = const WorkerCoordinatorRepository();
      final original = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      ))!;
      await repository.seedSchedule(session, workerKey: 'conversation');
      final claimed = (await repository.claimDueRun(
        session,
        workerKey: 'conversation',
        coordinator: original,
        executionLease: const Duration(minutes: 5),
      ))!;
      await _expireCoordinator(session);
      final replacement = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      ))!;

      expect(
        await repository.renewRun(
          session,
          schedule: claimed,
          coordinator: replacement,
          executionLease: const Duration(minutes: 5),
        ),
        isFalse,
      );
    });

    test('a former coordinator cannot renew a claimed run', () async {
      final session = sessionBuilder.build();
      final repository = const WorkerCoordinatorRepository();
      final coordinator = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      ))!;
      await repository.seedSchedule(session, workerKey: 'conversation');
      final claimed = (await repository.claimDueRun(
        session,
        workerKey: 'conversation',
        coordinator: coordinator,
        executionLease: const Duration(minutes: 5),
      ))!;
      await _expireCoordinator(session);
      await repository.acquireCoordinator(session, ownerId: 'server-b');

      expect(
        await repository.renewRun(
          session,
          schedule: claimed,
          coordinator: coordinator,
          executionLease: const Duration(minutes: 5),
        ),
        isFalse,
      );
    });

    test('a former coordinator cannot complete a claimed run', () async {
      final session = sessionBuilder.build();
      final repository = const WorkerCoordinatorRepository();
      final coordinator = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      ))!;
      await repository.seedSchedule(session, workerKey: 'conversation');
      final claimed = (await repository.claimDueRun(
        session,
        workerKey: 'conversation',
        coordinator: coordinator,
        executionLease: const Duration(minutes: 5),
      ))!;
      await _expireCoordinator(session);
      await repository.acquireCoordinator(session, ownerId: 'server-b');

      expect(
        await repository.completeRun(
          session,
          schedule: claimed,
          coordinator: coordinator,
          interval: const Duration(seconds: 1),
        ),
        isFalse,
      );
    });

    test(
      'only the matching run token can renew or complete a schedule',
      () async {
        final session = sessionBuilder.build();
        final repository = const WorkerCoordinatorRepository();
        final coordinator = (await repository.acquireCoordinator(
          session,
          ownerId: 'server-a',
        ))!;
        await repository.seedSchedule(session, workerKey: 'conversation');
        final claimed = (await repository.claimDueRun(
          session,
          workerKey: 'conversation',
          coordinator: coordinator,
          executionLease: const Duration(minutes: 5),
        ))!;

        expect(
          await repository.renewRun(
            session,
            schedule: claimed,
            coordinator: coordinator,
            executionLease: const Duration(minutes: 5),
          ),
          isTrue,
        );
        expect(
          await repository.completeRun(
            session,
            schedule: claimed.copyWith(runToken: 'stale'),
            coordinator: coordinator,
            interval: const Duration(seconds: 1),
          ),
          isFalse,
        );
      },
    );

    test('an expired execution lease can be reclaimed', () async {
      final session = sessionBuilder.build();
      final repository = const WorkerCoordinatorRepository();
      final coordinator = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      ))!;
      await repository.seedSchedule(session, workerKey: 'conversation');
      final first = (await repository.claimDueRun(
        session,
        workerKey: 'conversation',
        coordinator: coordinator,
        executionLease: const Duration(minutes: 5),
      ))!;
      await session.db.unsafeQuery(
        'UPDATE recurring_worker_schedule '
        'SET "runLeaseExpiresAt" = CURRENT_TIMESTAMP - INTERVAL \'1 second\'',
      );

      final reclaimed = await repository.claimDueRun(
        session,
        workerKey: 'conversation',
        coordinator: coordinator,
        executionLease: const Duration(minutes: 5),
      );

      expect(reclaimed, isNotNull);
      expect(reclaimed!.runToken, isNot(first.runToken));
    });

    test('completion clears the run and advances its schedule', () async {
      final session = sessionBuilder.build();
      final repository = const WorkerCoordinatorRepository();
      final coordinator = (await repository.acquireCoordinator(
        session,
        ownerId: 'server-a',
      ))!;
      await repository.seedSchedule(session, workerKey: 'conversation');
      final claimed = (await repository.claimDueRun(
        session,
        workerKey: 'conversation',
        coordinator: coordinator,
        executionLease: const Duration(minutes: 5),
      ))!;

      expect(
        await repository.completeRun(
          session,
          schedule: claimed,
          coordinator: coordinator,
          interval: const Duration(minutes: 1),
        ),
        isTrue,
      );
      final completed = await RecurringWorkerSchedule.db.findFirstRow(
        session,
        where: (table) => table.workerKey.equals('conversation'),
      );

      expect(completed!.runToken, isNull);
      expect(
        completed.nextRunAt,
        isA<DateTime>().having(
          (value) => value.isAfter(claimed.nextRunAt),
          'after the claimed schedule',
          isTrue,
        ),
      );
    });
  });
}

Future<void> _expireCoordinator(Session session) => session.db.unsafeQuery(
  'UPDATE worker_coordinator_lease '
  'SET "expiresAt" = CURRENT_TIMESTAMP - INTERVAL \'1 second\'',
);
