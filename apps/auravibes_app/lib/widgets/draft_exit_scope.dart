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
    _registerCurrentRoute(.maybeOf(context));
  }

  @override
  Widget build(BuildContext context) =>
      _DraftExitScopeListener(guard: widget.guard, child: widget.child);

  void _registerCurrentRoute(GoRouter? router) {
    if (router == null) return;
    final uri = _routeUri(router);
    _updateRegistration(uri);
  }

  Uri _routeUri(GoRouter router) {
    final isPageRoute = ModalRoute.of(context)?.settings is Page;

    return isPageRoute ? GoRouterState.of(context).uri : router.state.uri;
  }

  void _updateRegistration(Uri uri) {
    final oldUri = _uri;
    if (oldUri != null && oldUri != uri) {
      _unregister(oldUri);
    }
    _uri = uri;
    final registry = ref.read(draftExitRegistryProvider);
    _registry = registry;
    registry.register(uri, context, widget.guard);
  }

  void _unregister(Uri uri) => _registry?.unregister(uri, widget.guard);
}

class _DraftExitScopeListener extends StatelessWidget {
  const new({required this.guard, required this.child});

  final DraftExitGuard guard;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: guard,
    builder: (context, _) => _DraftExitPopScope(guard: guard, child: child),
  );
}

class _DraftExitPopScope extends StatelessWidget {
  const new({required this.guard, required this.child});

  final DraftExitGuard guard;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    child: _DraftExitTransitionShield(guard: guard, child: child),
    canPop: guard.isApproved && !guard.isTransitioning,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(guard.pop(context, result));
    },
  );
}

class _DraftExitTransitionShield extends StatelessWidget {
  const new({required this.guard, required this.child});

  final DraftExitGuard guard;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isTransitioning = guard.isTransitioning;

    return AbsorbPointer(
      absorbing: isTransitioning,
      child: ExcludeFocus(excluding: isTransitioning, child: child),
    );
  }
}
