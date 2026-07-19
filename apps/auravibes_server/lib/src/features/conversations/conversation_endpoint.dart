import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import 'live_turn_broker.dart';
import 'repositories/conversation_repository.dart' as conversation_repo;
import 'usecases/conversation_usecases.dart';

class ConversationEndpoint extends Endpoint {
  ConversationUseCases get _useCases =>
      ConversationUseCases(conversation_repo.ConversationRepository());

  Future<ConversationSummary> create(
    Session session,
    CreateConversationRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.create(session, userId: account.userId, request: request);
  }

  Future<List<ConversationSummary>> list(
    Session session,
    ListConversationsRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.list(session, userId: account.userId, request: request);
  }

  Future<ConversationPage> listPage(
    Session session,
    ListConversationsRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.listPage(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<ConversationSummary> get(
    Session session,
    GetConversationRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.get(session, userId: account.userId, request: request);
  }

  Future<List<ConversationMessageView>> listMessages(
    Session session,
    ListConversationMessagesRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.listMessages(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<ConversationSummary> update(
    Session session,
    UpdateConversationRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.update(session, userId: account.userId, request: request);
  }

  Future<void> delete(
    Session session,
    DeleteConversationRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.delete(session, userId: account.userId, request: request);
  }

  Future<StartTurnResult> startTurn(
    Session session,
    StartTurnRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.startTurn(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<ConversationMutationResult> continueTurn(
    Session session,
    ContinueTurnRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.continueTurn(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<TurnSnapshot> getTurn(Session session, GetTurnRequest request) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.getTurn(session, userId: account.userId, request: request);
  }

  Stream<LiveTurnEvent> subscribeTurn(
    Session session,
    LiveTurnSubscribeRequest request,
  ) {
    final broker = const LiveTurnBroker();
    final events = broker.listen(session, request);
    return _authorizeTurnSubscription(session, request, broker, events);
  }

  Stream<LiveTurnEvent> _authorizeTurnSubscription(
    Session session,
    LiveTurnSubscribeRequest request,
    LiveTurnBroker broker,
    Stream<LiveTurnEvent> events,
  ) async* {
    final account = await const AuthenticatedAccountResolver()(session);
    yield* broker.authorize(
      session,
      request: request,
      userId: account.userId,
      events: events,
    );
  }

  Future<ConversationMutationResult> submitToolDecision(
    Session session,
    SubmitToolDecisionRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.submitToolDecision(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<ConversationMutationResult> cancelTurn(
    Session session,
    CancelTurnRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.cancelTurn(
      session,
      userId: account.userId,
      request: request,
    );
  }

  Future<ConversationMutationResult> compact(
    Session session,
    CompactConversationRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.compact(session, userId: account.userId, request: request);
  }
}
