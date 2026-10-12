import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/background_works.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';

part 'background_works_dao.g.dart';

@DriftAccessor(tables: [BackgroundWorks])
class BackgroundWorksDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$BackgroundWorksDaoMixin;

extension BackgroundWorksDaoOperations on BackgroundWorksDao {
  Future<AgentBackgroundWork?> find({
    required String conversationId,
    required String workId,
  }) async {
    final row =
        await (select(backgroundWorks)..where(
              (table) =>
                  table.conversationId.equals(conversationId) &
                  table.id.equals(workId),
            ))
            .getSingleOrNull();

    return row == null ? null : _toAgentBackgroundWork(row);
  }

  Stream<List<AgentBackgroundWork>> watchConversation(String conversationId) =>
      _conversationRows(conversationId).map(_toAgentBackgroundWorkList);

  Future<AgentBackgroundWork> create(
    AgentBackgroundWorkCreateRequest request,
  ) async {
    final existing = await _findByRequest(request);
    if (existing != null) return existing;

    return _toAgentBackgroundWork(await _insertRequest(request));
  }

  Future<void> discard({
    required String conversationId,
    required String workId,
  }) async {
    final _ = await (delete(
      backgroundWorks,
    )..where((table) => _provisionalWork(table, conversationId, workId))).go();
  }

  Future<bool> requestStop({
    required String conversationId,
    required String workId,
  }) async {
    final updated =
        await (update(backgroundWorks)..where(
              (table) => _provisionalWork(table, conversationId, workId),
            ))
            .writeReturning(_stopRequestUpdate());

    return updated.isNotEmpty;
  }

  Future<AgentBackgroundWork?> finish(
    AgentBackgroundWorkCompletion completion,
  ) => transaction(() => _finish(completion));
}

extension _BackgroundWorksDaoQueryOps on BackgroundWorksDao {
  Stream<List<BackgroundWorkTable>> _conversationRows(String conversationId) =>
      (select(backgroundWorks)
            ..where((table) => table.conversationId.equals(conversationId))
            ..orderBy([
              (table) => OrderingTerm(expression: table.createdAt),
              (table) => OrderingTerm(expression: table.id),
            ]))
          .watch();

  Future<AgentBackgroundWork?> _findByRequest(
    AgentBackgroundWorkCreateRequest request,
  ) => find(conversationId: request.conversationId, workId: request.id);

  Future<BackgroundWorkTable> _insertRequest(
    AgentBackgroundWorkCreateRequest request,
  ) => into(backgroundWorks).insertReturning(
    BackgroundWorksCompanion.insert(
      id: .new(request.id),
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      originatingMessageId: .new(request.originatingMessageId),
      toolCallId: request.toolCallId,
      toolKind: request.toolKind,
      status: AgentBackgroundWorkStatus.running.name,
    ),
  );

  Future<BackgroundWorkTable?> _findRunning(
    AgentBackgroundWorkCompletion completion,
  ) => (select(
    backgroundWorks,
  )..where((table) => _activeWork(table, completion))).getSingleOrNull();
}

extension _BackgroundWorksDaoCompletionOps on BackgroundWorksDao {
  Future<AgentBackgroundWork?> _finish(
    AgentBackgroundWorkCompletion completion,
  ) async {
    _requireTerminal(completion.status);
    if (await _findRunning(completion) == null) return null;

    final bounded = _boundedCompletion(completion);
    final updated = await _writeCompletion(completion, bounded);

    return updated == null ? null : _toAgentBackgroundWork(updated);
  }

  Future<BackgroundWorkTable?> _writeCompletion(
    AgentBackgroundWorkCompletion completion,
    _BoundedCompletion bounded,
  ) async {
    final updated =
        await (update(backgroundWorks)
              ..where((table) => _activeWork(table, completion)))
            .writeReturning(_completionUpdate(completion, bounded));

    return updated.isEmpty ? null : updated.single;
  }
}

const _activeStatuses = ['running', 'stopRequested'];
const _terminalStatuses = ['completed', 'failed', 'cancelled'];

typedef _BoundedCompletion = ({String? resultContent, String? statusPreview});

void _requireTerminal(AgentBackgroundWorkStatus status) {
  if (!_terminalStatuses.contains(status.name)) {
    throw ArgumentError.value(
      status,
      'status',
      'A terminal status is required.',
    );
  }
}

Expression<bool> _provisionalWork(
  $BackgroundWorksTable table,
  String conversationId,
  String workId,
) =>
    table.conversationId.equals(conversationId) &
    table.id.equals(workId) &
    table.status.equals(AgentBackgroundWorkStatus.running.name);

Expression<bool> _activeWork(
  $BackgroundWorksTable table,
  AgentBackgroundWorkCompletion completion,
) =>
    table.conversationId.equals(completion.conversationId) &
    table.id.equals(completion.workId) &
    table.status.isIn(_activeStatuses);

BackgroundWorksCompanion _stopRequestUpdate() => BackgroundWorksCompanion(
  updatedAt: .new(DateTime.now().toUtc()),
  status: .new(AgentBackgroundWorkStatus.stopRequested.name),
);

BackgroundWorksCompanion _completionUpdate(
  AgentBackgroundWorkCompletion completion,
  _BoundedCompletion bounded,
) => .new(
  updatedAt: .new(DateTime.now().toUtc()),
  status: .new(completion.status.name),
  statusPreview: .new(bounded.statusPreview),
  resultContent: .new(bounded.resultContent),
  resultByteLength: .new(completion.resultByteLength),
  errorCode: .new(completion.errorCode),
);

_BoundedCompletion _boundedCompletion(
  AgentBackgroundWorkCompletion completion,
) {
  final content = completion.resultContent;
  _requireCompleteByteLength(completion);

  return (
    resultContent: content == null
        ? null
        : _truncateUtf8(content, AgentBackgroundWorkLimits.resultBytes),
    statusPreview: _boundedPreview(completion.statusPreview),
  );
}

void _requireCompleteByteLength(AgentBackgroundWorkCompletion completion) {
  final inputByteLength = utf8.encode(completion.resultContent ?? '').length;
  if (completion.resultByteLength >= inputByteLength) return;

  throw ArgumentError.value(
    completion.resultByteLength,
    'resultByteLength',
    'Must include the UTF-8 byte length of the supplied content.',
  );
}

String? _boundedPreview(String? preview) => preview == null
    ? null
    : _truncateUtf8(preview, AgentBackgroundWorkLimits.statusPreviewBytes);

String _truncateUtf8(String value, int maxBytes) {
  final bytes = utf8.encode(value);
  if (bytes.length <= maxBytes) return value;
  var end = maxBytes;
  while (end > 0 && (bytes[end] & 0xc0) == 0x80) {
    end--;
  }

  return utf8.decode(bytes.sublist(0, end));
}

AgentBackgroundWork _toAgentBackgroundWork(BackgroundWorkTable row) =>
    AgentBackgroundWork(
      identity: _toBackgroundWorkIdentity(row),
      state: _toBackgroundWorkState(row),
    );

AgentBackgroundWorkIdentity _toBackgroundWorkIdentity(
  BackgroundWorkTable row,
) => .new(
  id: row.id,
  workspaceId: row.workspaceId,
  conversationId: row.conversationId,
  toolCallId: row.toolCallId,
  toolKind: row.toolKind,
  originatingMessageId: row.originatingMessageId,
);

AgentBackgroundWorkState _toBackgroundWorkState(BackgroundWorkTable row) =>
    AgentBackgroundWorkState(
      status: AgentBackgroundWorkStatus.values.byName(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      statusPreview: row.statusPreview,
      resultContent: row.resultContent,
      resultByteLength: row.resultByteLength,
      errorCode: row.errorCode,
    );

List<AgentBackgroundWork> _toAgentBackgroundWorkList(
  List<BackgroundWorkTable> rows,
) => [for (final row in rows) _toAgentBackgroundWork(row)];
