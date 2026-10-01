import 'dart:async';

import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Registers the exact route and owns the editor's system Back confirmation.
class DraftExitScope extends ConsumerStatefulWidget {
  const new({required this.guard, required this.child, super.key});

  final DraftExitGuard guard;
  final Widget child;

  @override
  ConsumerState<DraftExitScope> createState() => _DraftExitScopeState();
}

class _DraftExitScopeState extends ConsumerState<DraftExitScope> {
  Uri? _uri;
  DraftExitRegistry? _registry;

  @override
  void dispose() {
    final uri = _uri;
    if (uri != null) _registry?.unregister(uri, widget.guard);
    widget.guard.unbind();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final uri = ModalRoute.of(context)?.settings is Page
        ? GoRouterState.of(context).uri
        : router.state.uri;
    final oldUri = _uri;
    if (oldUri != null && oldUri != uri) {
      _registry?.unregister(oldUri, widget.guard);
    }
    _uri = uri;
    final registry = ref.read(draftExitRegistryProvider);
    _registry = registry;
    registry.register(uri, context, widget.guard);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.guard,
    builder: (context, _) => PopScope<Object?>(
      child: AbsorbPointer(
        absorbing: widget.guard.isTransitioning,
        child: ExcludeFocus(
          excluding: widget.guard.isTransitioning,
          child: widget.child,
        ),
      ),
      canPop: widget.guard.isApproved && !widget.guard.isTransitioning,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(widget.guard.pop(context, result));
      },
    ),
  );
}
