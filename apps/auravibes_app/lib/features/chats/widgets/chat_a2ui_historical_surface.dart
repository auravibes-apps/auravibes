// ignore_for_file: type=lint, type=warning
import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as core;
import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/agent_adapters/chat_a2ui_genui_adapter.dart';
import 'package:auravibes_app/features/chats/models/chat_a2ui_message_state.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_warning.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

class ChatA2uiHistoricalSurface extends StatefulWidget {
  const new({required this.messageId, required this.payloads, super.key});

  final String messageId;
  final Iterable<String> payloads;

  @override
  State<ChatA2uiHistoricalSurface> createState() =>
      _ChatA2uiHistoricalSurfaceState();
}

class _ChatA2uiHistoricalSurfaceState extends State<ChatA2uiHistoricalSurface> {
  SurfaceController? _controller;
  StreamSubscription<SurfaceUpdate>? _updates;
  var _payloadHash = 0;
  final _issues = <String>{};
  final _validatedPayloads = <String>[];
  final _components = <String, Map<String, Map<String, dynamic>>>{};
  final _roots = <String>{};

  @override
  void initState() {
    super.initState();
    _load(widget.payloads);
  }

  @override
  void didUpdateWidget(covariant ChatA2uiHistoricalSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hash = Object.hashAll(widget.payloads);
    if (widget.messageId != oldWidget.messageId || hash != _payloadHash) {
      _load(widget.payloads);
    }
  }

  void _load(Iterable<String> payloads) {
    final saved = payloads.toList(growable: false);
    _payloadHash = Object.hashAll(saved);
    unawaited(_updates?.cancel());
    _controller?.dispose();
    final controller = SurfaceController(catalogs: auraChatCatalogs());
    _controller = controller;
    _components.clear();
    _roots.clear();
    _issues.clear();
    _validatedPayloads.clear();
    _updates = controller.surfaceUpdates.listen((_) {
      if (mounted)
        setState(() {
          final _ = 0;
        });
    });
    final messages = <ChatA2uiProtocolMessage>[];
    for (final payload in saved) {
      try {
        for (final result in parseChatA2uiProtocolMessageResults(
          jsonDecode(payload),
          allowLegacyBindings: true,
        )) {
          if (result.message == null) {
            final _ = _issues.add('malformedPayload');
          } else {
            messages.add(result.message!);
            _validatedPayloads.add(result.message!.payloadJson);
          }
        }
      } on Object catch (_) {
        final _ = _issues.add('malformedPayload');
      }
    }
    for (final pending in scopeChatA2uiMessages(messages, widget.messageId)) {
      try {
        final message = pending.message;
        if (message is! core.CreateSurfaceMessage &&
            !controller.activeSurfaceIds.contains(chatA2uiSurfaceId(message))) {
          final _ = _issues.add('malformedPayload');
          continue;
        }
        controller.handleMessage(
          ChatA2uiRuntime.normalizeChatA2uiMessage(
            message,
            componentsBySurface: _components,
            surfacesWithRoot: _roots,
          ),
        );
      } on Object catch (_) {
        final _ = _issues.add('renderFailure');
      }
    }
    if (controller.activeSurfaceIds.any((id) => !_roots.contains(id))) {
      final _ = _issues.add('missingRoot');
    }
    if (mounted)
      setState(() {
        final _ = 0;
      });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    final ids = controller.activeSurfaceIds.where(_roots.contains).toList();
    if (ids.isEmpty && _issues.isEmpty) return const SizedBox.shrink();

    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in ids)
          AuraInteractionScope(
            policy: const AuraInteractionPolicy.readOnly(),
            child: TickerMode(
              enabled: false,
              child: Surface(
                key: ValueKey(id),
                surfaceContext: controller.contextFor(id),
                actionDelegate: const ReadOnlyChatA2uiActionDelegate(),
              ),
            ),
          ),
        if (_issues.isNotEmpty)
          ChatA2uiWarning(
            details: chatA2uiDiagnosticDetails(
              messageId: widget.messageId,
              issues: _issues,
            ),
            uiPayloads: _validatedPayloads,
          ),
      ],
    );
  }

  @override
  void dispose() {
    unawaited(_updates?.cancel());
    _controller?.dispose();
    super.dispose();
  }
}

class ReadOnlyChatA2uiActionDelegate implements ActionDelegate {
  const new();

  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genuiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
    buildWidget,
  ) => true;
}
