import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class BackgroundWorkRepository implements AgentBackgroundWorkStore {
  new(AppDatabase database) : _database = database;

  final AppDatabase _database;

  BackgroundWorksDao get _dao => _database.backgroundWorksDao;

  @override
  Future<AgentBackgroundWork?> find({
    required String conversationId,
    required String workId,
  }) => _dao.find(conversationId: conversationId, workId: workId);

  @override
  Stream<List<AgentBackgroundWork>> watchConversation(String conversationId) =>
      _dao.watchConversation(conversationId);

  @override
  Future<AgentBackgroundWork> create(
    AgentBackgroundWorkCreateRequest request,
  ) => _dao.create(request);

  @override
  Future<void> discard({
    required String conversationId,
    required String workId,
  }) async {
    await _dao.discard(conversationId: conversationId, workId: workId);
  }

  @override
  Future<bool> requestStop({
    required String conversationId,
    required String workId,
  }) async {
    return await _dao.requestStop(
      conversationId: conversationId,
      workId: workId,
    );
  }

  @override
  Future<AgentBackgroundWork?> finish(
    AgentBackgroundWorkCompletion completion,
  ) => _dao.finish(completion);
}
