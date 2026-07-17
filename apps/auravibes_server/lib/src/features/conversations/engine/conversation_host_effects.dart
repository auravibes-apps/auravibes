import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../objects/object_store.dart';
import '../domain/conversation_values.dart';
import '../live_turn_broker.dart';

const maxConcurrentProviderTurns = 32;
const maxConcurrentProviderTurnsPerWorkspace = 4;
const maxProviderTurnsPerWorkspacePerMinute = 60;
const maxAttachmentBytes = 20 * 1024 * 1024;
const maxProviderResponseBytes = 1024 * 1024;

Stream<T> cancellationCheckedStream<T>(
  Stream<T> source,
  Future<bool> Function() isCancelled,
) async* {
  await for (final value in source) {
    if (await isCancelled()) throw const ConversationCancelledException();
    yield value;
  }
}

String fallbackConversationTitle(String content) {
  final normalized = content.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= 30) return normalized;
  return '${normalized.substring(0, 27).trimRight()}...';
}

abstract interface class ConversationCancellationProbe {
  Future<bool> isCancelled(Session session, int turnId);
}

class DatabaseConversationCancellationProbe
    implements ConversationCancellationProbe {
  const DatabaseConversationCancellationProbe();

  @override
  Future<bool> isCancelled(Session session, int turnId) async {
    final turn = await ConversationTurn.db.findById(session, turnId);
    return turn == null || turn.cancellationRequestedAt != null;
  }
}

abstract interface class ConversationLiveTurnPublisher {
  Future<void> queued();

  Future<void> running();

  Future<void> text(String text);
}

class BrokerConversationLiveTurnPublisher
    implements ConversationLiveTurnPublisher {
  BrokerConversationLiveTurnPublisher({
    required this.session,
    required this.workspaceId,
    required this.turnId,
    this.broker = const LiveTurnBroker(),
  });

  final Session session;
  final int workspaceId;
  final String turnId;
  final LiveTurnBroker broker;
  var _sequence = 0;

  @override
  Future<void> queued() => _publish(LiveTurnEventKind.queued);

  @override
  Future<void> running() => _publish(LiveTurnEventKind.running);

  @override
  Future<void> text(String text) {
    if (text.isEmpty) return Future.value();
    return _publish(LiveTurnEventKind.text, text: text);
  }

  Future<void> _publish(LiveTurnEventKind kind, {String? text}) =>
      broker.publish(
        session,
        LiveTurnEvent(
          workspaceId: workspaceId,
          turnId: turnId,
          sequence: ++_sequence,
          kind: kind,
          text: text,
        ),
      );
}

class ConversationResponseAccumulator {
  ConversationResponseAccumulator({required this.publisher});

  final ConversationLiveTurnPublisher publisher;
  final StringBuffer _content = StringBuffer();
  Future<void> _pending = Future.value();
  var _contentBytes = 0;

  String get content => _content.toString();

  void addText(String text) {
    if (text.isEmpty) return;
    _contentBytes += utf8.encode(text).length;
    if (_contentBytes > maxProviderResponseBytes) {
      throw const ConversationResponseLimitException();
    }
    _content.write(text);
    _pending = _pending.then((_) => publisher.text(text));
  }

  Future<void> close() => _pending;
}

abstract interface class ConversationAdmissionGate {
  Future<T> run<T>(
    Session session, {
    required ConversationJob job,
    required String providerId,
    required Future<T> Function(Future<void> admissionLost) body,
  });
}

class DatabaseConversationAdmissionGate implements ConversationAdmissionGate {
  const DatabaseConversationAdmissionGate();

  @override
  Future<T> run<T>(
    Session session, {
    required ConversationJob job,
    required String providerId,
    required Future<T> Function(Future<void> admissionLost) body,
  }) async {
    await _reserve(session, job: job, providerId: providerId);
    try {
      return _withReservationRenewal(job, body);
    } finally {
      await _release(session, job);
    }
  }

  Future<void> _reserve(
    Session session, {
    required ConversationJob job,
    required String providerId,
  }) => session.db.transaction((transaction) async {
    final now = DateTime.now().toUtc();
    final jobId = job.id;
    final leaseToken = job.leaseToken;
    if (jobId == null || leaseToken == null) {
      throw StateError('Conversation job lease is missing.');
    }
    final lock = await ProviderAdmissionLock.db.findFirstRow(
      session,
      where: (table) => table.key.equals('global'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lock == null) throw StateError('Provider admission lock is missing.');
    await ProviderAdmission.db.deleteWhere(
      session,
      where: (table) =>
          table.createdAt < now.subtract(const Duration(minutes: 1)),
      transaction: transaction,
    );
    final currentJob = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(jobId) &
          table.status.equals(ConversationJobStatuses.leased) &
          table.leaseToken.equals(leaseToken) &
          (table.leaseExpiresAt > now),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (currentJob == null) throw StateError('Conversation job lease is lost.');
    final active = await ProviderAdmissionReservation.db.find(
      session,
      where: (table) => table.expiresAt > now,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final recent = await ProviderAdmission.db.find(
      session,
      where: (table) =>
          table.workspaceId.equals(currentJob.workspaceId) &
          (table.createdAt >= now.subtract(const Duration(minutes: 1))),
      transaction: transaction,
    );
    if (active.length >= maxConcurrentProviderTurns ||
        active
                .where((item) => item.workspaceId == currentJob.workspaceId)
                .length >=
            maxConcurrentProviderTurnsPerWorkspace ||
        recent.length >= maxProviderTurnsPerWorkspacePerMinute) {
      throw const ConversationRateLimitException();
    }
    await ProviderAdmissionReservation.db.insertRow(
      session,
      ProviderAdmissionReservation(
        jobId: currentJob.id!,
        workspaceId: currentJob.workspaceId,
        providerId: providerId,
        leaseToken: leaseToken,
        expiresAt: currentJob.leaseExpiresAt!,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    await ProviderAdmission.db.insertRow(
      session,
      ProviderAdmission(
        jobId: currentJob.id!,
        workspaceId: currentJob.workspaceId,
        providerId: providerId,
        leaseToken: leaseToken,
        createdAt: now,
      ),
      transaction: transaction,
    );
  });

  Future<bool> renew(
    Session session, {
    required int jobId,
    required String leaseToken,
  }) => session.db.transaction((transaction) async {
    final now = DateTime.now().toUtc();
    final lock = await ProviderAdmissionLock.db.findFirstRow(
      session,
      where: (table) => table.key.equals('global'),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (lock == null) throw StateError('Provider admission lock is missing.');
    final job = await ConversationJob.db.findFirstRow(
      session,
      where: (table) =>
          table.id.equals(jobId) &
          table.status.equals(ConversationJobStatuses.leased) &
          table.leaseToken.equals(leaseToken) &
          (table.leaseExpiresAt > now),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (job == null) return false;
    final reservation = await ProviderAdmissionReservation.db.findFirstRow(
      session,
      where: (table) =>
          table.jobId.equals(jobId) & table.leaseToken.equals(leaseToken),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (reservation == null) return false;
    await ProviderAdmissionReservation.db.updateRow(
      session,
      reservation.copyWith(
        expiresAt: job.leaseExpiresAt!,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    return true;
  });

  Future<T> _withReservationRenewal<T>(
    ConversationJob job,
    Future<T> Function(Future<void> admissionLost) body,
  ) async {
    final admissionLost = Completer<void>();
    Future<void>? renewal;
    var renewing = false;
    final timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (renewing || admissionLost.isCompleted) return;
      renewing = true;
      renewal = _renewReservation(job)
          .then<void>((renewed) {
            if (!renewed) admissionLost.complete();
          }, onError: (_, _) => admissionLost.complete())
          .whenComplete(
            () => renewing = false,
          );
    });
    try {
      return await body(admissionLost.future);
    } finally {
      timer.cancel();
      await renewal;
    }
  }

  Future<bool> _renewReservation(ConversationJob job) async {
    final session = await Serverpod.instance.createSession();
    try {
      return await renew(
        session,
        jobId: job.id!,
        leaseToken: job.leaseToken!,
      );
    } finally {
      await session.close();
    }
  }

  Future<void> _release(Session session, ConversationJob job) =>
      session.db.transaction((transaction) async {
        final lock = await ProviderAdmissionLock.db.findFirstRow(
          session,
          where: (table) => table.key.equals('global'),
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (lock == null) {
          throw StateError('Provider admission lock is missing.');
        }
        await ProviderAdmissionReservation.db.deleteWhere(
          session,
          where: (table) =>
              table.jobId.equals(job.id) &
              table.leaseToken.equals(job.leaseToken),
          transaction: transaction,
        );
      });
}

class ConversationAttachment {
  const ConversationAttachment({
    required this.mimeType,
    required this.name,
    required this.bytes,
  });

  final String mimeType;
  final String name;
  final List<int> bytes;
}

abstract interface class ConversationAttachmentReader {
  Future<List<ConversationAttachment>> read(
    Session session, {
    required int workspaceId,
    required List<int> objectIds,
  });
}

class ServerConversationAttachmentReader
    implements ConversationAttachmentReader {
  const ServerConversationAttachmentReader();

  @override
  Future<List<ConversationAttachment>> read(
    Session session, {
    required int workspaceId,
    required List<int> objectIds,
  }) async {
    if (objectIds.isEmpty) return const [];
    final endpoint = Platform.environment['OBJECT_STORE_ENDPOINT'];
    if (endpoint == null) throw const ConversationAttachmentException('store');
    final store = HttpObjectStore(
      endpoint: Uri.parse(endpoint),
      bearerToken: Platform.environment['OBJECT_STORE_BEARER_TOKEN'],
    );
    final result = <ConversationAttachment>[];
    for (final objectId in objectIds.toSet()) {
      final object = await WorkspaceObject.db.findFirstRow(
        session,
        where: (table) =>
            table.id.equals(objectId) &
            table.workspaceId.equals(workspaceId) &
            table.status.equals('active') &
            table.deletedAt.equals(null),
      );
      if (object == null || object.sizeBytes > maxAttachmentBytes) {
        throw const ConversationAttachmentException('invalid');
      }
      if (!object.mimeType.startsWith('image/')) {
        throw const ConversationAttachmentException('unsupported');
      }
      final signed = await store.signGet(
        key: object.objectKey,
        contentDisposition: 'attachment',
        expiresIn: const Duration(minutes: 1),
      );
      final bytes = await _readSignedObject(signed, object.sizeBytes);
      result.add(
        ConversationAttachment(
          mimeType: object.mimeType,
          name: object.displayName,
          bytes: bytes,
        ),
      );
    }
    return result;
  }
}

Future<List<int>> _readSignedObject(
  SignedObjectRequest signed,
  int size,
) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(signed.url);
    signed.headers.forEach(request.headers.set);
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw const ConversationAttachmentException('download');
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > size || bytes.length > maxAttachmentBytes) {
        throw const ConversationAttachmentException('size');
      }
    }
    if (bytes.length != size) {
      throw const ConversationAttachmentException('size');
    }
    return bytes;
  } finally {
    client.close(force: true);
  }
}

class ConversationDurableJobs {
  const ConversationDurableJobs();

  Future<void> enqueueTitle(
    Session session, {
    required ConversationJob parent,
    required String content,
  }) => _enqueue(
    session,
    parent: parent,
    kind: ConversationJobKinds.title,
    payload: {
      'content': content,
      'fallbackTitle': fallbackConversationTitle(content),
    },
  );

  Future<void> enqueueSubAgent(
    Session session, {
    required ConversationJob parent,
    required String title,
    required String prompt,
    String? agentId,
  }) => _enqueue(
    session,
    parent: parent,
    kind: ConversationJobKinds.subAgent,
    payload: {'title': title, 'prompt': prompt, 'agentId': ?agentId},
  );

  Future<void> _enqueue(
    Session session, {
    required ConversationJob parent,
    required String kind,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().toUtc();
    await ConversationJob.db.insertRow(
      session,
      ConversationJob(
        workspaceId: parent.workspaceId,
        conversationId: parent.conversationId,
        turnId: parent.turnId,
        requestId: '${parent.requestId}:$kind',
        kind: kind,
        status: ConversationJobStatuses.queued,
        payloadJson: jsonEncode(payload),
        attempt: 0,
        maxAttempts: 3,
        availableAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

final class ConversationCancelledException implements Exception {
  const ConversationCancelledException();
}

final class ConversationRateLimitException implements Exception {
  const ConversationRateLimitException();
}

final class ConversationResponseLimitException implements Exception {
  const ConversationResponseLimitException();
}

final class ConversationAttachmentException implements Exception {
  const ConversationAttachmentException(this.code);
  final String code;
}
