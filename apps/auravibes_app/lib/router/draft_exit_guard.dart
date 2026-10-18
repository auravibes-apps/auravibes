import 'package:auravibes_app/widgets/unsaved_changes_dialog.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// One confirmation owner for Back, route replacement and context switches.
/// Approval lasts only until navigation commits, or its caller releases it.
class DraftExitGuard extends ChangeNotifier {
  bool _preferReturn = false;
  bool _isDirty = false;
  bool _isSaving = false;
  bool? _lastDirty;
  bool? _lastSaving;
  bool _approved = false;
  bool _transitioning = false;
  bool _transitionExitAllowed = false;
  bool _notificationPending = false;
  bool _isDisposed = false;
  FocusNode? _transitionFocus;
  Future<bool>? _pending;
  bool Function()? _readDirty;
  bool Function()? _readSaving;
  Future<bool?> Function(BuildContext)? _confirm;
  void Function(BuildContext)? _onReturn;
  void Function(BuildContext, Object?)? _onPop;

  bool get isApproved => _approved;
  bool get isTransitioning => _transitioning;
  bool get isDirty => _readDirty?.call() ?? _isDirty;
  bool get isSaving => _readSaving?.call() ?? _isSaving;
  bool get canPop => !isSaving && !isTransitioning && (isApproved || !isDirty);

  void bind({
    required ({bool Function() isDirty, bool Function() isSaving}) readers,
    DraftExitGuardCallbacks callbacks = const DraftExitGuardCallbacks(),
    bool preferReturn = false,
  }) {
    _bindCallbacks(readers, callbacks, preferReturn);
    _syncStateFromReaders();
  }

  /// Retained for existing template-tool route callers.
  void update({required bool isDirty, required bool isSaving}) {
    final didChange = _lastDirty != isDirty || _lastSaving != isSaving;
    if (didChange) _approved = false;
    _isDirty = isDirty;
    _isSaving = isSaving;
    _lastDirty = isDirty;
    _lastSaving = isSaving;
    if (didChange) _notifyChanged();
  }

  /// [discardConfirmed] shares consent only across drafts in the same task
  /// being removed together. Ordinary editor Close/Apply never supplies it.
  Future<bool> canExit(BuildContext context, {bool discardConfirmed = false}) {
    if (_pending case final pending?) return pending;
    final pending = _confirmExit(context, discardConfirmed: discardConfirmed);
    _pending = pending;

    return pending.whenComplete(() => _pending = null);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifyChanged() {
    // Guard owners can update from descendant initState during a build.
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_notificationPending || _isDisposed) return;
      _notificationPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notificationPending = false;
        if (!_isDisposed) notifyListeners();
      });
      WidgetsBinding.instance.scheduleFrame();

      return;
    }

    notifyListeners();
  }
}

extension _DraftExitGuardBinding on DraftExitGuard {
  void _bindCallbacks(
    ({bool Function() isDirty, bool Function() isSaving}) readers,
    DraftExitGuardCallbacks callbacks,
    bool preferReturn,
  ) {
    _preferReturn = preferReturn;
    _readDirty = readers.isDirty;
    _readSaving = readers.isSaving;
    _confirm = callbacks.confirm;
    _onReturn = callbacks.onReturn;
    _onPop = callbacks.onPop;
  }

  void _syncStateFromReaders() {
    final previousDirty = _lastDirty;
    final previousSaving = _lastSaving;
    final isDirty = this.isDirty;
    final isSaving = this.isSaving;
    final didChange =
        previousDirty != null &&
        (previousDirty != isDirty || previousSaving != isSaving);
    if (didChange) _approved = false;
    _lastDirty = isDirty;
    _lastSaving = isSaving;
    if (previousDirty == null || didChange) _notifyChanged();
  }
}

class const DraftExitGuardCallbacks({
  final Future<bool?> Function(BuildContext)? confirm,
  final void Function(BuildContext)? onReturn,
  final void Function(BuildContext, Object?)? onPop,
});

extension DraftExitGuardTransitions on DraftExitGuard {
  void holdApproval() {
    if (!_approved) return;
    _transitioning = true;
    _transitionExitAllowed = false;
    _transitionFocus ??= FocusManager.instance.primaryFocus;
    FocusManager.instance.primaryFocus?.unfocus();
    _notifyChanged();
  }

  void finishTransition() {
    _transitionExitAllowed = true;
  }

  void releaseApproval({bool restoreFocus = true}) {
    final shouldRestoreFocus = _transitioning && restoreFocus;
    final focus = _clearApprovalState();
    _notifyChanged();
    if (!shouldRestoreFocus || focus == null) return;
    _scheduleFocusRestore(focus);
  }

  Future<void> pop(BuildContext context, [Object? result]) async {
    if (!await canExit(context) || !context.mounted) return;
    // Let PopScope observe approval before issuing the actual pop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _completePop(context, result);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Remove screen closures when its scope is disposed; route guards may
  /// live longer.
  void unbind() {
    _preferReturn = false;
    _readDirty = null;
    _readSaving = null;
    _confirm = null;
    _onReturn = null;
    _onPop = null;
    _transitionFocus = null;
    _approved = false;
    _transitioning = false;
    _transitionExitAllowed = false;
    _isDirty = false;
    _isSaving = false;
    _lastDirty = null;
    _lastSaving = null;
  }
}

extension _DraftExitGuardFocus on DraftExitGuard {
  FocusNode? _clearApprovalState() {
    _approved = false;
    _transitioning = false;
    _transitionExitAllowed = false;
    final focus = _transitionFocus;
    _transitionFocus = null;

    return focus;
  }

  void _scheduleFocusRestore(FocusNode focus) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_transitioning && focus.context != null) {
        focus.requestFocus();
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }
}

extension _DraftExitGuardExit on DraftExitGuard {
  void _completePop(BuildContext context, Object? result) {
    if (!context.mounted) return;
    if (_onPop case final onPop?) {
      onPop(context, result);

      return;
    }
    if (_preferReturn && _onReturn != null) {
      _onReturn?.call(context);

      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(result);
    } else {
      _onReturn?.call(context);
    }
  }

  Future<bool> _confirmExit(
    BuildContext context, {
    required bool discardConfirmed,
  }) async {
    if (!_canStartExit(context)) return false;
    if (_approved) return true;
    if (isDirty && !discardConfirmed && !await _confirmDiscard(context)) {
      return false;
    }
    _approved = true;
    _notifyChanged();

    return true;
  }

  bool _canStartExit(BuildContext context) =>
      !((_transitioning && !_transitionExitAllowed) ||
          (_readSaving?.call() ?? _isSaving) ||
          !context.mounted);

  Future<bool> _confirmDiscard(BuildContext context) async {
    final focus = FocusManager.instance.primaryFocus;
    if (!await _discardWasConfirmed(context)) {
      if (context.mounted) _restoreFocusAfterDiscardDeclined(context, focus);

      return false;
    }
    _transitionFocus = focus;
    // Saving may have started while the confirmation was open.

    return !_isSavingNow;
  }

  Future<bool> _discardWasConfirmed(BuildContext context) async =>
      await (_confirm ?? UnsavedChangesDialog.confirm)(context) == true &&
      context.mounted;

  void _restoreFocusAfterDiscardDeclined(
    BuildContext context,
    FocusNode? focus,
  ) {
    if (context.mounted && focus?.context != null) focus?.requestFocus();
  }

  bool get _isSavingNow => _readSaving?.call() ?? _isSaving;
}
