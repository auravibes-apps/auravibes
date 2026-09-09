// ignore_for_file: type=lint, type=warning
import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/agent_adapters/chat_a2ui_genui_adapter.dart';
import 'package:auravibes_app/features/chats/models/chat_a2ui_message_state.dart';
import 'package:auravibes_app/features/chats/models/chat_a2ui_surface_state.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        A2uiChatAction,
        A2uiChatContract,
        A2uiFormValidationResult,
        a2uiChatCatalogIds,
        a2uiChatFormCatalogId,
        a2uiChatFormSubmitActionName,
        a2uiChatFormSubmitComponentId,
        a2uiChatInteractionModes,
        a2uiChatProtocolVersion,
        a2uiChatWireVersion,
        a2uiIssueCodeFromName,
        activeA2uiWireCodec,
        maxA2uiChatPayloadBytes,
        supportedA2uiChatComponents;
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

const String chatA2uiProtocolVersion = a2uiChatProtocolVersion;
final _logger = Logger('chat_a2ui_runtime');

typedef ChatUiAction = A2uiChatAction;
typedef _PendingSurfaceContext = ({
  String wireSurfaceId,
  String scopedSurfaceId,
  ChatA2uiSurfaceState surface,
});

class ChatA2uiRuntime extends ChangeNotifier {
  new({required this.conversationId, this.enabled = false}) {
    _surfaceSubscription = _controller.surfaceUpdates.listen((_) {
      notifyListeners();
    });
  }

  final String conversationId;
  bool enabled;

  late final SurfaceController _controller = SurfaceController(
    catalogs: auraChatCatalogs(),
  );
  late final StreamSubscription<SurfaceUpdate> _surfaceSubscription;
  final StreamController<ChatUiAction> _actions =
      StreamController<ChatUiAction>.broadcast();
  final Map<String, ChatA2uiMessageState> _messageStates = {};
  final Map<String, ChatA2uiSurfaceState> _surfaceStates = {};
  final Set<String> _submittedActions = {};
  final Set<ChatA2uiSurfaceIssue> _unboundIssues = {};
  final Set<String> _unboundDiagnosticPayloads = {};
  String? _restoringMessageId;
  String? _currentMessageId;

  SurfaceController get controller => _controller;

  Stream<ChatUiAction> get actions => _actions.stream;

  ChatA2uiMessageState _messageState(String messageId) => _messageStates
      .putIfAbsent(messageId, () => ChatA2uiMessageState(messageId));

  List<String> get messages => messagesFor(_currentMessageId ?? '');

  List<String> messagesFor(String messageId) =>
      List.unmodifiable(_messageStates[messageId]?.payloads ?? const []);

  List<String> diagnosticPayloadsFor(String messageId) => List.unmodifiable(
    _messageStates[messageId]?.diagnosticPayloads ?? const <String>[],
  );

  String? get currentMessageId => _currentMessageId;

  bool isCurrentMessage(String messageId) =>
      enabled && messageId == _currentMessageId;

  bool get requiresUserAction {
    final messageId = _currentMessageId;

    return messageId != null && (_messageStates[messageId]?.blocking ?? false);
  }

  bool hasSurfaceIssue(String messageId) =>
      _messageStates[messageId]?.issues.isNotEmpty ?? false;

  bool isReadySurface(String messageId, String surfaceId) =>
      _surfaceStates[surfaceId]?.ownerMessageId == messageId &&
      (_surfaceStates[surfaceId]?.hasRoot ?? false) &&
      _controller.activeSurfaceIds.contains(surfaceId);

  Iterable<String> surfaceIdsFor(String messageId) =>
      _controller.activeSurfaceIds.where(
        (surfaceId) => _surfaceStates[surfaceId]?.ownerMessageId == messageId,
      );

  Iterable<String> surfaceSlotsFor(String messageId) {
    final ordered = _messageStates[messageId]?.surfaceOrder ?? const <String>[];
    final issueIds = _surfaceStates.values
        .where(
          (state) =>
              state.ownerMessageId == messageId && state.issues.isNotEmpty,
        )
        .map((state) => state.scopedSurfaceId);

    return <String>{...ordered, ...surfaceIdsFor(messageId), ...issueIds};
  }

  Iterable<ChatA2uiSurfaceIssue> issuesForSurface(String surfaceId) =>
      _surfaceStates[surfaceId]?.issues ?? const <ChatA2uiSurfaceIssue>{};

  bool hasSubmissionIssue(String surfaceId) =>
      _surfaceStates[surfaceId]?.submissionIssues.isNotEmpty ?? false;

  List<String> a2uiMessageIssuesFor(String messageId) => [
    for (final issue
        in _messageStates[messageId]?.messageIssues ??
            const <ChatA2uiSurfaceIssue>{})
      issue.name,
  ];

  Map<String, List<String>> a2uiIssuesBySurfaceFor(String messageId) {
    final result = <String, List<String>>{};
    final scopedIds = _messageStates[messageId]?.scopedSurfaceIds ?? const {};
    for (final surface in _surfaceStates.values) {
      if (surface.ownerMessageId != messageId || surface.issues.isEmpty) {
        continue;
      }
      if (!scopedIds.containsKey(surface.wireSurfaceId)) continue;
      result[surface.wireSurfaceId] = surface.issues
          .map((issue) => issue.name)
          .toList();
    }

    return result;
  }

  String? catalogIdForSurface(String surfaceId) =>
      _surfaceStates[surfaceId]?.catalogId;

  String? interactionModeForSurface(String surfaceId) =>
      _surfaceStates[surfaceId]?.interactionMode;

  bool isInteractiveSurface(String messageId, String surfaceId) {
    return isCurrentMessage(messageId) &&
        isReadySurface(messageId, surfaceId) &&
        _surfaceStates[surfaceId]?.catalogId == a2uiChatFormCatalogId &&
        _surfaceStates[surfaceId]?.interactionMode == 'requiresUserAction' &&
        _surfaceStates[surfaceId]?.issues.isNotEmpty != true;
  }

  A2uiFormValidationResult? formValidationFor(String surfaceId) {
    final surface = _surfaceStates[surfaceId];
    if (surface == null ||
        surface.catalogId != a2uiChatFormCatalogId ||
        surface.interactionMode != 'requiresUserAction') {
      return null;
    }
    final data = _controller
        .contextFor(surfaceId)
        .dataModel
        .getValue<Object?>(DataPath.root);
    final answers = _jsonObject(data);
    if (answers == null) return null;
    final components = surface.components.values.map(
      (component) => Map<String, Object?>.from(component),
    );
    final normalized = A2uiChatContract.normalizeFormValues(
      components: components,
      values: answers,
    );
    return A2uiChatContract.validateFormValues(
      components: components,
      values: normalized,
      touchedPaths: surface.touchedPaths,
    );
  }

  bool canSubmitForm(String messageId, String surfaceId) {
    final validation = formValidationFor(surfaceId);
    return isInteractiveSurface(messageId, surfaceId) &&
        validation?.isValid == true;
  }

  String? formSubmitLabel(String surfaceId) =>
      _formLabel(surfaceId, 'submitLabel');

  String? formResetLabel(String surfaceId) =>
      _formLabel(surfaceId, 'resetLabel');

  String? _formLabel(String surfaceId, String field) {
    final surface = _surfaceStates[surfaceId];
    if (surface == null) return null;
    for (final component in surface.components.values) {
      if (component['component'] == 'Form' && component[field] is String) {
        return component[field] as String;
      }
    }
    return null;
  }

  void markFormPathTouched(String surfaceId, String path) {
    if (!path.startsWith('/')) return;
    final surface = _surfaceStates[surfaceId];
    if (surface == null || surface.touchedPaths.add(path) == false) return;
    notifyListeners();
  }

  void enable() => enabled = true;

  void bindMessage(String messageId) {
    if (_currentMessageId != messageId) _submittedActions.clear();
    _currentMessageId = messageId;
    if (_unboundIssues.isNotEmpty) {
      final state = _messageState(messageId);
      state.issues.addAll(_unboundIssues);
      state.messageIssues.addAll(_unboundIssues);
      _unboundIssues.clear();
    }
    for (final payload in _unboundDiagnosticPayloads) {
      _recordDiagnosticPayload(messageId, payload);
    }
    _unboundDiagnosticPayloads.clear();
    notifyListeners();
  }

  void restoreMessage(
    String messageId,
    Iterable<String> payloads, {
    bool current = false,
    Map<String, List<String>> a2uiIssuesBySurface = const {},
    List<String> a2uiMessageIssues = const [],
    Iterable<String> diagnosticPayloads = const [],
  }) {
    if (!enabled) return;
    final state = _messageState(messageId);
    if (current && !state.closed) {
      if (_currentMessageId != messageId) _submittedActions.clear();
      _currentMessageId = messageId;
    }
    final savedPayloads = payloads.toList(growable: false);
    _restoreIssueMetadata(
      messageId,
      a2uiIssuesBySurface: a2uiIssuesBySurface,
      a2uiMessageIssues: a2uiMessageIssues,
    );
    for (final payload in diagnosticPayloads) {
      _recordDiagnosticPayload(messageId, payload);
    }
    if (listEquals(state.payloads, savedPayloads) && savedPayloads.isNotEmpty) {
      notifyListeners();

      return;
    }
    _restoringMessageId = messageId;
    try {
      for (final payload in savedPayloads) {
        addMessageJson(payload, allowLegacyBindings: true);
      }
      commitMessage(messageId);
    } finally {
      _restoringMessageId = null;
    }
    notifyListeners();
  }

  void _restoreIssueMetadata(
    String messageId, {
    required Map<String, List<String>> a2uiIssuesBySurface,
    required List<String> a2uiMessageIssues,
  }) {
    for (final issueName in a2uiMessageIssues) {
      final issue = a2uiIssueCodeFromName(issueName);
      if (issue != null) {
        final state = _messageState(messageId);
        final _ = state.messageIssues.add(issue);
        final _ = state.issues.add(issue);
      }
    }
    for (final entry in a2uiIssuesBySurface.entries) {
      final state = _messageState(messageId);
      final scopedId = state.scopedSurfaceIds[entry.key] ??=
          '$messageId:${entry.key}';
      final surface = _surfaceStates.putIfAbsent(
        scopedId,
        () => ChatA2uiSurfaceState(
          ownerMessageId: messageId,
          wireSurfaceId: entry.key,
          scopedSurfaceId: scopedId,
        ),
      );
      final order = state.surfaceOrder;
      if (!order.contains(scopedId)) order.add(scopedId);
      for (final issueName in entry.value) {
        final issue = a2uiIssueCodeFromName(issueName);
        if (issue == null) continue;
        final _ = surface.issues.add(issue);
        final _ = state.issues.add(issue);
      }
    }
  }

  void addMessageJson(String payload, {bool allowLegacyBindings = false}) {
    if (!enabled) {
      return;
    }
    if (utf8.encode(payload).length > maxA2uiChatPayloadBytes) {
      recordIssue(
        ChatA2uiSurfaceIssue.oversizedPayload,
        surfaceId: _recoverWireSurfaceIdFromText(payload),
      );

      return;
    }
    final decoded = _tryDecode(payload);
    for (final result in parseChatA2uiProtocolMessageResults(
      decoded,
      allowLegacyBindings: allowLegacyBindings,
    )) {
      final message = result.message;
      if (message != null) {
        addProtocolMessage(message);
      } else if (result.issue != null) {
        recordIssue(
          result.issue!,
          surfaceId: result.wireSurfaceId,
          diagnosticPayloadJson: decoded is Map
              ? jsonEncode(decoded)
              : jsonEncode({'rawPayload': payload}),
        );
      }
    }
  }

  void addMessage(
    core.A2uiMessage message, {
    String interactionMode = 'passive',
  }) {
    _handleMessage(message, interactionMode);
  }

  void addProtocolMessage(ChatA2uiProtocolMessage message) {
    _handleMessage(message.message, message.interactionMode);
  }

  void recordIssue(
    ChatA2uiSurfaceIssue issue, {
    String? surfaceId,
    String? diagnosticPayloadJson,
  }) {
    if (!enabled) return;
    final messageId = _restoringMessageId ?? _currentMessageId;
    if (_isClosedMessage(messageId)) return;
    if (messageId == null) {
      _recordUnboundIssue(issue, diagnosticPayloadJson);

      return;
    }
    _recordBoundIssue(
      messageId,
      issue,
      surfaceId: surfaceId,
      diagnosticPayloadJson: diagnosticPayloadJson,
    );
  }

  bool _isClosedMessage(String? messageId) =>
      messageId != null && (_messageStates[messageId]?.closed ?? false);

  void _recordUnboundIssue(
    ChatA2uiSurfaceIssue issue,
    String? diagnosticPayloadJson,
  ) {
    final _ = _unboundIssues.add(issue);
    if (!kReleaseMode && diagnosticPayloadJson != null) {
      final _ = _unboundDiagnosticPayloads.add(diagnosticPayloadJson);
    }
  }

  void _recordBoundIssue(
    String messageId,
    ChatA2uiSurfaceIssue issue, {
    required String? surfaceId,
    required String? diagnosticPayloadJson,
  }) {
    if (diagnosticPayloadJson != null) {
      _recordDiagnosticPayload(messageId, diagnosticPayloadJson);
    }
    final state = _messageState(messageId);
    final _ = state.issues.add(issue);
    if (surfaceId != null && surfaceId.isNotEmpty) {
      _recordSurfaceIssue(messageId, surfaceId, issue);
    } else {
      final _ = state.messageIssues.add(issue);
    }
    _logger.warning(
      'A2UI surface rejected issue=$issue conversation=$conversationId '
      'message=$messageId${surfaceId == null ? '' : ' surface=$surfaceId'}',
    );
    _recomputeBlocking(messageId);
    notifyListeners();
  }

  void _recordSurfaceIssue(
    String messageId,
    String surfaceId,
    ChatA2uiSurfaceIssue issue,
  ) {
    final state = _messageState(messageId);
    final scopedSurfaceId = _scopedSurfaceIdFor(messageId, surfaceId);
    final order = state.surfaceOrder;
    if (!order.contains(scopedSurfaceId)) order.add(scopedSurfaceId);
    final _ = _surfaceStates[scopedSurfaceId]!.issues.add(issue);
  }

  void _recomputeBlocking(String messageId) {
    final state = _messageState(messageId);
    final surfaceIds = state.scopedSurfaceIds.values;
    final requiresAction = surfaceIds.any(
      (surfaceId) =>
          isReadySurface(messageId, surfaceId) &&
          _surfaceStates[surfaceId]?.catalogId == a2uiChatFormCatalogId &&
          _surfaceStates[surfaceId]?.interactionMode == 'requiresUserAction' &&
          _surfaceStates[surfaceId]?.issues.isNotEmpty != true,
    );
    if (requiresAction) {
      state.blocking = true;
    } else {
      state.blocking = false;
    }
  }

  void commitCurrentMessage() => commitMessage(_currentMessageId);

  /// Stops interaction while retaining the committed surface for read-only
  /// rendering and replay.
  void closeMessage(String messageId) {
    final state = _messageState(messageId)..closed = true;
    state.messageKeys.clear();
    if (_currentMessageId == messageId) _currentMessageId = null;
    state.blocking = false;
    notifyListeners();
  }

  void beginGeneration() {
    final messageId = _currentMessageId;
    if (messageId != null) closeMessage(messageId);
  }

  void restore(Iterable<String> payloads) {
    for (final payload in payloads) {
      addMessageJson(payload, allowLegacyBindings: true);
    }
  }

  void _handleMessage(core.A2uiMessage message, String interactionMode) {
    if (!enabled) return;
    final owner = _restoringMessageId ?? _currentMessageId;
    if (owner == null || (_messageStates[owner]?.closed ?? false)) return;
    _recordDiagnosticPayload(
      owner,
      jsonEncode({
        'protocolVersion': chatA2uiProtocolVersion,
        'interactionMode': interactionMode,
        'message': message.toJson(),
      }),
    );
    final surfaceId = _surfaceId(message);
    final issue = _incomingMessageIssue(
      message,
      interactionMode,
      owner,
      surfaceId,
    );
    if (issue != null) {
      recordIssue(issue, surfaceId: surfaceId);

      return;
    }
    final encoded = jsonEncode({
      'protocolVersion': chatA2uiProtocolVersion,
      'interactionMode': interactionMode,
      'message': message.toJson(),
    });
    final decodedEnvelope = activeA2uiWireCodec
        .decode(jsonDecode(encoded))
        .envelope;
    if (decodedEnvelope == null) {
      recordIssue(ChatA2uiSurfaceIssue.malformedPayload, surfaceId: surfaceId);

      return;
    }
    final state = _messageState(owner);
    if (!state.messageKeys.add(encoded)) return;
    state.pendingMessages.add(
      ChatA2uiProtocolMessage(envelope: decodedEnvelope, message: message),
    );
    notifyListeners();
  }

  ChatA2uiSurfaceIssue? _incomingMessageIssue(
    core.A2uiMessage message,
    String interactionMode,
    String owner,
    String? surfaceId,
  ) {
    if (!a2uiChatInteractionModes.contains(interactionMode)) {
      return ChatA2uiSurfaceIssue.invalidInteractionMode;
    }
    final contractIssue = A2uiChatContract.validateMessage(
      Map<String, Object?>.from(message.toJson()),
      interactionMode: interactionMode,
    );
    if (contractIssue != null) return contractIssue;
    if (!_isSupported(message)) {
      return message is core.UpdateComponentsMessage
          ? ChatA2uiSurfaceIssue.unsupportedComponent
          : ChatA2uiSurfaceIssue.unsupportedCatalog;
    }
    final surfaceIssue = _surfaceReferenceIssue(
      message,
      interactionMode,
      owner,
      surfaceId,
    );
    if (surfaceIssue != null) return surfaceIssue;
    if (!_isCatalogModeAllowed(message, interactionMode)) {
      return ChatA2uiSurfaceIssue.invalidInteractionMode;
    }
    return null;
  }

  ChatA2uiSurfaceIssue? _surfaceReferenceIssue(
    core.A2uiMessage message,
    String interactionMode,
    String owner,
    String? surfaceId,
  ) {
    if (surfaceId == null || message is core.CreateSurfaceMessage) return null;
    final ownerState = _messageStates[owner];
    final scopedSurfaceId = ownerState?.scopedSurfaceIds[surfaceId];
    if (!_hasSurfaceReference(ownerState, scopedSurfaceId, surfaceId)) {
      return ChatA2uiSurfaceIssue.malformedPayload;
    }
    if (_hasMismatchedSurfaceMode(scopedSurfaceId, interactionMode)) {
      return ChatA2uiSurfaceIssue.invalidInteractionMode;
    }
    return null;
  }

  bool _hasSurfaceReference(
    ChatA2uiMessageState? ownerState,
    String? scopedSurfaceId,
    String surfaceId,
  ) =>
      scopedSurfaceId != null ||
      ownerState?.pendingMessages.any(
            (pending) =>
                pending.message is core.CreateSurfaceMessage &&
                chatA2uiSurfaceId(pending.message) == surfaceId,
          ) ==
          true;

  bool _hasMismatchedSurfaceMode(
    String? scopedSurfaceId,
    String interactionMode,
  ) =>
      scopedSurfaceId != null &&
      _surfaceStates[scopedSurfaceId]?.interactionMode != interactionMode;

  void _recordDiagnosticPayload(String messageId, String payload) {
    if (kReleaseMode) return;
    final payloads = _messageState(messageId).diagnosticPayloads;
    if (!payloads.contains(payload)) payloads.add(payload);
  }

  void commitMessage(String? messageId) {
    if (messageId == null) return;
    final state = _messageState(messageId);
    final pending = List<ChatA2uiProtocolMessage>.of(state.pendingMessages);
    state.pendingMessages.clear();
    if (pending.isEmpty) return;

    final savedPayloads = <String>[];
    for (final pendingMessage in pending) {
      final savedPayload = _commitPendingMessage(
        messageId,
        state,
        pendingMessage,
      );
      if (savedPayload != null) savedPayloads.add(savedPayload);
    }
    _recordUnreadySurfaces(messageId, state.scopedSurfaceIds);
    if (savedPayloads.isNotEmpty) {
      state.payloads.addAll(savedPayloads);
    }
    _recomputeBlocking(messageId);
    notifyListeners();
  }

  _PendingSurfaceContext? _preparePendingSurface(
    String messageId,
    ChatA2uiMessageState state,
    ChatA2uiProtocolMessage pendingMessage,
  ) {
    final wireSurfaceId = chatA2uiSurfaceId(pendingMessage.message);
    if (wireSurfaceId == null) return null;
    final existingSurfaceId = state.scopedSurfaceIds[wireSurfaceId];
    if (pendingMessage.message is core.CreateSurfaceMessage &&
        existingSurfaceId != null) {
      return null;
    }
    final scopedSurfaceId = existingSurfaceId ?? '$messageId:$wireSurfaceId';
    state.scopedSurfaceIds[wireSurfaceId] = scopedSurfaceId;
    final surface = _surfaceStates.putIfAbsent(
      scopedSurfaceId,
      () => ChatA2uiSurfaceState(
        ownerMessageId: messageId,
        wireSurfaceId: wireSurfaceId,
        scopedSurfaceId: scopedSurfaceId,
      ),
    );
    final surfaceOrder = state.surfaceOrder;
    if (!surfaceOrder.contains(scopedSurfaceId)) {
      surfaceOrder.add(scopedSurfaceId);
    }
    if (surface.deleted) return null;
    return (
      wireSurfaceId: wireSurfaceId,
      scopedSurfaceId: scopedSurfaceId,
      surface: surface,
    );
  }

  String? _commitPendingMessage(
    String messageId,
    ChatA2uiMessageState state,
    ChatA2uiProtocolMessage pendingMessage,
  ) {
    final context = _preparePendingSurface(messageId, state, pendingMessage);
    if (context == null) return null;
    final scopedMessage = scopeChatA2uiMessage(
      pendingMessage.message,
      scopedSurfaceId: context.scopedSurfaceId,
    );
    if (scopedMessage == null) return null;
    final surfaceId = _surfaceId(scopedMessage);
    final previousComponents = Map<String, Map<String, dynamic>>.from(
      context.surface.components,
    );
    final previouslyHadRoot = context.surface.hasRoot;
    final componentsBySurface = <String, Map<String, Map<String, dynamic>>>{
      context.scopedSurfaceId: Map.of(context.surface.components),
    };
    final surfacesWithRoot = <String>{
      if (context.surface.hasRoot) context.scopedSurfaceId,
    };
    final normalizedMessage = ChatA2uiRuntime.normalizeChatA2uiMessage(
      scopedMessage,
      componentsBySurface: componentsBySurface,
      surfacesWithRoot: surfacesWithRoot,
    );
    _replaceSurfaceComponents(
      context.surface,
      componentsBySurface[context.scopedSurfaceId] ?? const {},
      surfacesWithRoot.contains(context.scopedSurfaceId),
    );
    if (normalizedMessage is core.UpdateComponentsMessage &&
        !_isRenderableComponentGraph(surfaceId)) {
      if (surfaceId == null) return null;
      final issue = context.surface.components.containsKey('root')
          ? ChatA2uiSurfaceIssue.malformedPayload
          : ChatA2uiSurfaceIssue.missingRoot;
      _restoreSurfaceComponents(
        context.surface,
        previousComponents,
        previouslyHadRoot,
      );
      recordIssue(issue, surfaceId: context.wireSurfaceId);
      return null;
    }
    if (!_applySurfaceLifecycle(context, pendingMessage, normalizedMessage)) {
      return null;
    }
    return _renderPendingMessage(
      messageId,
      context,
      pendingMessage,
      normalizedMessage,
      surfaceId,
      previousComponents,
      previouslyHadRoot,
    );
  }

  void _replaceSurfaceComponents(
    ChatA2uiSurfaceState surface,
    Map<String, Map<String, dynamic>> components,
    bool hasRoot,
  ) {
    surface.components
      ..clear()
      ..addAll(components);
    surface.hasRoot = hasRoot;
  }

  void _restoreSurfaceComponents(
    ChatA2uiSurfaceState surface,
    Map<String, Map<String, dynamic>> components,
    bool hadRoot,
  ) {
    surface.components
      ..clear()
      ..addAll(components);
    surface.hasRoot = hadRoot;
  }

  bool _applySurfaceLifecycle(
    _PendingSurfaceContext context,
    ChatA2uiProtocolMessage pendingMessage,
    core.A2uiMessage normalizedMessage,
  ) {
    if (normalizedMessage is core.CreateSurfaceMessage) {
      if (_controller.activeSurfaceIds.contains(context.scopedSurfaceId)) {
        return false;
      }
      context.surface
        ..catalogId = normalizedMessage.catalogId
        ..interactionMode = pendingMessage.interactionMode
        ..deleted = false;
    }
    if (normalizedMessage is core.DeleteSurfaceMessage) {
      context.surface
        ..components.clear()
        ..hasRoot = false
        ..deleted = true;
    }
    return true;
  }

  String? _renderPendingMessage(
    String messageId,
    _PendingSurfaceContext context,
    ChatA2uiProtocolMessage pendingMessage,
    core.A2uiMessage normalizedMessage,
    String? surfaceId,
    Map<String, Map<String, dynamic>> previousComponents,
    bool previouslyHadRoot,
  ) {
    try {
      _controller.handleMessage(normalizedMessage);
      _captureInitialDataModel(context.surface, normalizedMessage);
      _recordAcceptedMessage(messageId, context, pendingMessage, surfaceId);
      return pendingMessage.payloadJson;
    } on Object catch (_) {
      _restoreSurfaceComponents(
        context.surface,
        previousComponents,
        previouslyHadRoot,
      );
      _restoreSurfaceFromHistory(surfaceId);
      recordIssue(
        ChatA2uiSurfaceIssue.renderFailure,
        surfaceId: context.wireSurfaceId,
      );
      return null;
    }
  }

  void _captureInitialDataModel(
    ChatA2uiSurfaceState surface,
    core.A2uiMessage normalizedMessage,
  ) {
    if (surface.catalogId != a2uiChatFormCatalogId) return;
    if (normalizedMessage is core.UpdateDataModelMessage &&
        normalizedMessage.path == '/' &&
        surface.initialDataModel == null) {
      surface.initialDataModel = _jsonObject(normalizedMessage.value);
    }
    if (surface.initialDataModel == null && surface.hasRoot) {
      surface.initialDataModel = _jsonObject(
        _controller
            .contextFor(surface.scopedSurfaceId)
            .dataModel
            .getValue<Object?>(DataPath.root),
      );
    }
  }

  void _recordAcceptedMessage(
    String messageId,
    _PendingSurfaceContext context,
    ChatA2uiProtocolMessage pendingMessage,
    String? surfaceId,
  ) {
    if (surfaceId != null) {
      _surfaceStates[surfaceId]?.acceptedMessages.add(pendingMessage);
    }
    if (surfaceId == null || !context.surface.hasRoot) return;
    _clearReadinessIssues(messageId, surfaceId);
  }

  void _recordUnreadySurfaces(
    String messageId,
    Map<String, String> scopedSurfaceIds,
  ) {
    for (final entry in scopedSurfaceIds.entries.toList(growable: false)) {
      final wireSurfaceId = entry.key;
      final surfaceId = entry.value;
      if (!_needsReadinessIssue(messageId, surfaceId)) continue;
      recordIssue(
        (_surfaceStates[surfaceId]?.components.isEmpty ?? true)
            ? ChatA2uiSurfaceIssue.emptySurface
            : ChatA2uiSurfaceIssue.missingRoot,
        surfaceId: wireSurfaceId,
      );
    }
  }

  bool _needsReadinessIssue(String messageId, String surfaceId) {
    final surface = _surfaceStates[surfaceId];
    return surface?.ownerMessageId == messageId &&
        _controller.activeSurfaceIds.contains(surfaceId) &&
        !(surface?.hasRoot ?? false) &&
        surface?.issues.isNotEmpty != true;
  }

  void _clearReadinessIssues(String messageId, String surfaceId) {
    _clearSurfaceReadinessIssues(surfaceId);
    final issues = _messageStates[messageId]?.issues;
    if (issues == null) return;
    _clearMessageReadinessIssues(messageId, issues);
    if (issues.isEmpty) _messageStates[messageId]?.issues.clear();
  }

  void _clearSurfaceReadinessIssues(String surfaceId) {
    final surface = _surfaceStates[surfaceId];
    if (surface == null) return;
    surface.issues.removeAll(const [
      ChatA2uiSurfaceIssue.missingRoot,
      ChatA2uiSurfaceIssue.emptySurface,
      ChatA2uiSurfaceIssue.renderFailure,
    ]);
    if (surface.issues.isEmpty) surface.issues.clear();
  }

  void _clearMessageReadinessIssues(
    String messageId,
    Set<ChatA2uiSurfaceIssue> issues,
  ) {
    for (final issue in const [
      ChatA2uiSurfaceIssue.missingRoot,
      ChatA2uiSurfaceIssue.emptySurface,
      ChatA2uiSurfaceIssue.renderFailure,
    ]) {
      if (!_hasReadinessIssueOnAnotherSurface(messageId, issue)) {
        final _ = issues.remove(issue);
      }
    }
  }

  bool _hasReadinessIssueOnAnotherSurface(
    String messageId,
    ChatA2uiSurfaceIssue issue,
  ) => _surfaceStates.values.any(
    (surface) =>
        surface.ownerMessageId == messageId && surface.issues.contains(issue),
  );

  static core.A2uiMessage normalizeChatA2uiMessage(
    core.A2uiMessage message, {
    required Map<String, Map<String, Map<String, dynamic>>> componentsBySurface,
    required Set<String> surfacesWithRoot,
  }) {
    if (message case core.CreateSurfaceMessage(:final surfaceId)) {
      componentsBySurface[surfaceId] = {};
      final _ = surfacesWithRoot.remove(surfaceId);

      return message;
    }
    if (message case core.DeleteSurfaceMessage(:final surfaceId)) {
      final _ = componentsBySurface.remove(surfaceId);
      final _ = surfacesWithRoot.remove(surfaceId);

      return message;
    }
    if (message is! core.UpdateComponentsMessage) return message;

    final knownComponents = componentsBySurface.putIfAbsent(
      message.surfaceId,
      () => {},
    );
    for (final component in message.components) {
      final id = component['id'];
      if (id is String) {
        knownComponents[id] = Map<String, dynamic>.from(component);
      }
    }
    if (surfacesWithRoot.contains(message.surfaceId) ||
        knownComponents.containsKey('root')) {
      final _ = surfacesWithRoot.add(message.surfaceId);
    }

    return message;
  }

  bool _isSupported(core.A2uiMessage message) {
    if (A2uiChatContract.containsAgentAction(message.toJson())) return false;
    if (message is core.CreateSurfaceMessage) {
      return a2uiChatCatalogIds.contains(message.catalogId);
    }
    if (message is core.UpdateComponentsMessage) {
      return message.components.every(
        (component) =>
            component['component'] is String &&
            supportedA2uiChatComponents.contains(component['component']),
      );
    }

    return true;
  }

  bool _isRenderableComponentGraph(String? surfaceId) {
    if (surfaceId == null) return false;
    final components = _surfaceStates[surfaceId]?.components;
    if (components == null) return false;
    return A2uiChatContract.isRenderableComponentGraph(
      components.map(
        (id, component) => MapEntry(id, Map<String, Object?>.from(component)),
      ),
    );
  }

  bool _isCatalogModeAllowed(core.A2uiMessage message, String interactionMode) {
    if (message is! core.CreateSurfaceMessage) return true;

    return A2uiChatContract.isCatalogAllowedForMode(
      message.catalogId,
      interactionMode,
    );
  }

  String _scopedSurfaceIdFor(String messageId, String wireSurfaceId) {
    final ids = _messageState(messageId).scopedSurfaceIds;
    final scopedSurfaceId = ids[wireSurfaceId] ??= '$messageId:$wireSurfaceId';
    final _ = _surfaceStates.putIfAbsent(
      scopedSurfaceId,
      () => ChatA2uiSurfaceState(
        ownerMessageId: messageId,
        wireSurfaceId: wireSurfaceId,
        scopedSurfaceId: scopedSurfaceId,
      ),
    );

    return scopedSurfaceId;
  }

  void submitForm(String surfaceId, {required String messageText}) {
    if (!enabled) return;
    final surface = _surfaceStates[surfaceId];
    if (surface == null) return;
    final turnId = surface.ownerMessageId;
    if (!isInteractiveSurface(turnId, surfaceId)) return;
    final action = _buildFormAction(surfaceId, surface, turnId, messageText);
    if (action == null) {
      _recordSubmissionIssue(surfaceId);

      return;
    }
    if (!A2uiChatContract.isValidAction(
      action.toJson(),
      conversationId: conversationId,
    )) {
      _recordSubmissionIssue(surfaceId);

      return;
    }
    final actionKey = _formSubmissionKey(turnId, surfaceId);
    final accepted = _submittedActions.add(actionKey);
    if (!accepted) return;
    _acceptFormSubmission(surfaceId, turnId, action);
  }

  ChatUiAction? _buildFormAction(
    String surfaceId,
    ChatA2uiSurfaceState surface,
    String turnId,
    String messageText,
  ) {
    final data = _controller
        .contextFor(surfaceId)
        .dataModel
        .getValue<Object?>(DataPath.root);
    final answers = _jsonObject(data);
    if (answers == null) return null;
    final components = surface.components.values.map(
      (component) => Map<String, Object?>.from(component),
    );
    final normalizedAnswers = A2uiChatContract.normalizeFormValues(
      components: components,
      values: answers,
    );
    final validation = formValidationFor(surfaceId);
    if (validation == null || !validation.isValid) return null;
    final wireSurfaceId = _wireSurfaceId(surfaceId, turnId);
    return ChatUiAction(
      protocolVersion: chatA2uiProtocolVersion,
      conversationId: conversationId,
      turnId: turnId,
      assistantMessageId: turnId,
      surfaceId: surfaceId,
      wireSurfaceId: wireSurfaceId,
      componentId: a2uiChatFormSubmitComponentId,
      actionName: a2uiChatFormSubmitActionName,
      context: const {},
      messageText: messageText,
      answers: normalizedAnswers,
      touchedPaths: surface.touchedPaths.toList()..sort(),
      unansweredPaths: validation.unansweredPaths,
      submittedAtUtc: DateTime.now().toUtc().toIso8601String(),
    );
  }

  String _formSubmissionKey(String turnId, String surfaceId) =>
      '$conversationId:$turnId:$surfaceId:$a2uiChatFormSubmitActionName';

  void _acceptFormSubmission(
    String surfaceId,
    String turnId,
    ChatUiAction action,
  ) {
    final replayPayload = chatA2uiSubmittedAnswersReplayPayload(action);
    if (replayPayload != null) {
      _messageState(turnId).payloads.add(replayPayload);
    }
    _surfaceStates[surfaceId]?.submissionIssues.clear();
    _messageState(turnId)
      ..closed = true
      ..blocking = false;
    _currentMessageId = null;
    _actions.add(action);
    notifyListeners();
  }

  void resetForm(String surfaceId) {
    final surface = _surfaceStates[surfaceId];
    final messageId = surface?.ownerMessageId;
    final initial = surface?.initialDataModel;
    if (surface == null ||
        messageId == null ||
        initial == null ||
        !isInteractiveSurface(messageId, surfaceId)) {
      return;
    }
    _controller.handleMessage(
      core.UpdateDataModelMessage(
        surfaceId: surfaceId,
        path: '/',
        value: initial,
      ),
    );
    surface
      ..touchedPaths.clear()
      ..submissionIssues.clear();
    notifyListeners();
  }

  void _recordSubmissionIssue(String surfaceId) {
    final _ = _surfaceStates[surfaceId]?.submissionIssues.add(
      ChatA2uiSurfaceIssue.malformedPayload,
    );
    notifyListeners();
  }

  void rejectFormSubmission(String surfaceId) {
    final messageId = _surfaceStates[surfaceId]?.ownerMessageId;
    if (messageId == null) return;
    final state = _messageState(messageId)..closed = false;
    final _ = _submittedActions.remove(
      '$conversationId:$messageId:$surfaceId:$a2uiChatFormSubmitActionName',
    );
    _currentMessageId = messageId;
    state.blocking = true;
    final _ = _surfaceStates[surfaceId]?.submissionIssues.add(
      ChatA2uiSurfaceIssue.renderFailure,
    );
    notifyListeners();
  }

  void _restoreSurfaceFromHistory(String? surfaceId) {
    if (surfaceId == null) return;
    final surface = _surfaceStates[surfaceId];
    final history = surface?.acceptedMessages;
    if (history == null || history.isEmpty) return;
    try {
      _replaySurfaceHistory(surfaceId, surface, history);
    } on Object catch (_) {
      _logger.warning(
        'A2UI surface restore failed conversation=$conversationId '
        'surface=$surfaceId',
      );
    }
  }

  void _replaySurfaceHistory(
    String surfaceId,
    ChatA2uiSurfaceState? surface,
    Iterable<ChatA2uiProtocolMessage> history,
  ) {
    _controller.handleMessage(core.DeleteSurfaceMessage(surfaceId: surfaceId));
    final componentsBySurface = <String, Map<String, Map<String, dynamic>>>{};
    final surfacesWithRoot = <String>{};
    for (final accepted in history) {
      final scoped = scopeChatA2uiMessage(
        accepted.message,
        scopedSurfaceId: surfaceId,
      );
      if (scoped == null) continue;
      final normalized = normalizeChatA2uiMessage(
        scoped,
        componentsBySurface: componentsBySurface,
        surfacesWithRoot: surfacesWithRoot,
      );
      _controller.handleMessage(normalized);
    }
    surface?.components
      ?..clear()
      ..addAll(componentsBySurface[surfaceId] ?? const {});
    if (surface != null) {
      surface.hasRoot = surfacesWithRoot.contains(surfaceId);
    }
  }

  Object? _tryDecode(String source) {
    try {
      return jsonDecode(source);
    } on Object catch (_) {
      return null;
    }
  }

  String? _surfaceId(core.A2uiMessage message) => switch (message) {
    core.CreateSurfaceMessage(:final surfaceId) => surfaceId,
    core.UpdateComponentsMessage(:final surfaceId) => surfaceId,
    core.UpdateDataModelMessage(:final surfaceId) => surfaceId,
    core.DeleteSurfaceMessage(:final surfaceId) => surfaceId,
    _ => null,
  };

  String? _wireSurfaceId(String scopedSurfaceId, String messageId) {
    for (final entry
        in (_messageStates[messageId]?.scopedSurfaceIds ?? const {}).entries) {
      if (entry.value == scopedSurfaceId) return entry.key;
    }

    return null;
  }

  String? _recoverWireSurfaceIdFromText(String value) {
    final match = RegExp(r'"surfaceId"\s*:\s*"([^"\\]{1,200})"')
        .firstMatch(value);

    return match?.group(1);
  }

  @override
  void dispose() {
    unawaited(_surfaceSubscription.cancel());
    unawaited(_actions.close());
    _controller.dispose();
    super.dispose();
  }
}

String? chatA2uiSubmittedAnswersReplayPayload(A2uiChatAction action) {
  final wireSurfaceId = action.wireSurfaceId;
  if (wireSurfaceId == null ||
      action.componentId != a2uiChatFormSubmitComponentId ||
      action.actionName != a2uiChatFormSubmitActionName) {
    return null;
  }

  return A2uiChatContract.encodeEnvelope({
    'version': a2uiChatWireVersion,
    'updateDataModel': {
      'surfaceId': wireSurfaceId,
      'path': '/',
      'value': action.answers,
    },
  }, interactionMode: 'requiresUserAction');
}

// ignore: unnecessary-nullable, surface data is untrusted and may be null.
Map<String, Object?>? _jsonObject(Object? value) {
  if (value is! Map || !value.keys.every((key) => key is String)) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final child = _jsonValue(entry.value);
    if (child == _invalidJson) return null;
    result[entry.key as String] = child;
  }

  return result;
}

Object? _jsonValue(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is Map) return _jsonObject(value) ?? _invalidJson;
  if (value is List) {
    final result = <Object?>[];
    for (final child in value) {
      final normalized = _jsonValue(child);
      if (normalized == _invalidJson) return _invalidJson;
      result.add(normalized);
    }

    return result;
  }

  return _invalidJson;
}

const _invalidJson = Object();
