import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class _DraftExitRegistryChanges extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Entries belong to mounted route screens. Only the visible URI can prompt.
class DraftExitRegistry {
  final _changes = _DraftExitRegistryChanges();
  final _listenedGuards = <DraftExitGuard>{};
  final _entries =
      <Uri, List<({BuildContext context, DraftExitGuard guard})>>{};
  GoRouter? _router;
  bool _notificationPending = false;
  bool _isDisposed = false;

  Listenable get changes => _changes;

  void register(Uri uri, BuildContext context, DraftExitGuard guard) {
    _registerEntry(uri, context, guard);
    if (_listenedGuards.add(guard)) guard.addListener(_scheduleNotification);
    _listenToRouter(.of(context));
    _scheduleNotification();
  }

  void unregister(Uri uri, DraftExitGuard guard) {
    final entries = _entries[uri];
    if (entries == null) return;
    entries.removeWhere((entry) => identical(entry.guard, guard));
    if (entries.isEmpty && _entries.remove(uri) == null) return;
    _unregisterGuardIfUnused(this, guard);
    _scheduleNotification();
  }

  bool hasActiveRoute(GoRouter router) =>
      _entries.isNotEmpty && _entryFor(router.state.uri) != null;

  Future<bool> canExitActive(GoRouter router) {
    if (_entries.isEmpty) return Future.value(true);
    if (_taskEntries(router.state.uri)
        .any((entry) => entry.guard.isTransitioning)) {
      return Future.value(false);
    }

    return canExitRoute(router.state.uri);
  }

  Future<bool> canExitRoute(Uri uri) async {
    if (_isInactiveRoute(uri)) return true;
    final entries = _taskEntries(uri);
    if (entries.isEmpty) return true;

    return await _confirmEntries(entries);
  }

  /// Freeze user edits after consent while selection persistence is pending.
  void holdActiveApproval(GoRouter router) {
    if (_entries.isEmpty) return;
    for (final entry in _taskEntries(router.state.uri)) {
      entry.guard.holdApproval();
    }
  }

  /// Allow the already-approved exit only after selection has persisted.
  void completeActiveTransition(GoRouter router) {
    if (_entries.isEmpty) return;
    for (final entry in _taskEntries(router.state.uri)) {
      entry.guard.finishTransition();
    }
  }

  /// Release after a failed/cancelled preflight, without changing the draft.
  void releaseApprovals() {
    final activeUri = _router?.state.uri;
    final activeGuard = activeUri == null ? null : _entryFor(activeUri)?.guard;
    for (final entries in _entries.values) {
      for (final entry in entries) {
        entry.guard.releaseApproval(
          restoreFocus: identical(entry.guard, activeGuard),
        );
      }
    }
  }

  void _scheduleNotification() {
    if (_notificationPending || _isDisposed) return;
    _notificationPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationPending = false;
      if (!_isDisposed) _changes.notify();
    });
    WidgetsBinding.instance.scheduleFrame();
  }
}

extension _DraftExitRegistryRegistration on DraftExitRegistry {
  void _registerEntry(Uri uri, BuildContext context, DraftExitGuard guard) {
    final entries = _entries.putIfAbsent(uri, () => []);
    final index = entries.indexWhere((entry) => identical(entry.guard, guard));
    final entry = (context: context, guard: guard);
    if (index == -1) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
  }

  void _listenToRouter(GoRouter router) {
    if (identical(_router, router)) return;
    _router?.routerDelegate.removeListener(releaseApprovals);
    _router = router;
    router.routerDelegate.addListener(releaseApprovals);
  }
}

void _unregisterGuardIfUnused(
  DraftExitRegistry registry,
  DraftExitGuard guard,
) {
  final isRegistered = registry._entries.values.any(
    (entries) => entries.any((entry) => identical(entry.guard, guard)),
  );
  if (isRegistered) return;
  guard.removeListener(registry._scheduleNotification);
  if (!registry._listenedGuards.remove(guard)) return;
}

extension DraftExitRegistryBackNavigation on DraftExitRegistry {
  bool canUseNativeBack(GoRouter router) =>
      _taskEntries(router.state.uri).every((entry) => entry.guard.canPop);
}

extension DraftExitRegistryLifecycle on DraftExitRegistry {
  void dispose() {
    _isDisposed = true;
    _router?.routerDelegate.removeListener(releaseApprovals);
    for (final guard in _listenedGuards) {
      guard.removeListener(_scheduleNotification);
    }
    _entries.clear();
    _listenedGuards.clear();
    _changes.dispose();
  }
}

extension _DraftExitRegistryExitChecks on DraftExitRegistry {
  bool _isInactiveRoute(Uri uri) {
    final router = _router;

    return router != null && router.state.uri != uri;
  }

  Future<bool> _confirmEntries(
    List<({BuildContext context, DraftExitGuard guard})> entries,
  ) async {
    final activeContext = entries.firstOrNull?.context;
    if (activeContext == null) return true;
    var discardConfirmed = false;
    for (final entry in entries) {
      final dirty = entry.guard.isDirty;
      if (!await entry.guard.canExit(
        activeContext,
        discardConfirmed: discardConfirmed,
      )) {
        releaseApprovals();

        return false;
      }
      discardConfirmed = discardConfirmed || dirty;
    }

    return true;
  }
}

extension _DraftExitRegistryEntries on DraftExitRegistry {
  List<({BuildContext context, DraftExitGuard guard})> _taskEntries(Uri uri) {
    final active = _entryFor(uri);
    if (active == null) return const [];
    final entries = _entries[uri] ?? const [];
    final activeIndex = entries.indexWhere(
      (entry) => identical(entry.guard, active.guard),
    );

    return _collectTaskEntries(entries, activeIndex);
  }

  List<({BuildContext context, DraftExitGuard guard})> _collectTaskEntries(
    List<({BuildContext context, DraftExitGuard guard})> entries,
    int activeIndex,
  ) {
    final task = <({BuildContext context, DraftExitGuard guard})>[];
    for (var index = activeIndex; index >= 0; index--) {
      final entry = entries[index];
      if (!entry.context.mounted) continue;
      task.add(entry);
      if (_isPageRoute(entry.context)) break;
    }

    return task;
  }

  bool _isPageRoute(BuildContext context) =>
      ModalRoute.of(context)?.settings is Page;

  ({BuildContext context, DraftExitGuard guard})? _entryFor(Uri uri) {
    final entries = _entries[uri];
    if (entries == null) return null;
    // A popped page can remain mounted during its exit animation. Prefer the
    // current page; a dialog overlays all pages, so fall back to mount order.
    for (final entry in entries.reversed) {
      if (entry.context.mounted && _isCurrentRoute(entry.context)) {
        return entry;
      }
    }

    return entries.reversed.where((entry) => entry.context.mounted).firstOrNull;
  }

  bool _isCurrentRoute(BuildContext context) =>
      ModalRoute.of(context)?.isCurrent ?? false;
}
