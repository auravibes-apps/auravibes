import 'package:auravibes_app/widgets/unsaved_changes_dialog.dart';
import 'package:flutter/widgets.dart';

/// One confirmation owner for Back, route replacement and context switches.
/// Approval lasts only until navigation commits, or its caller releases it.
class DraftExitGuard extends ChangeNotifier {
  bool _preferReturn = false;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _approved = false;
  bool _transitioning = false;
  bool _transitionExitAllowed = false;
  FocusNode? _transitionFocus;
  Future<bool>? _pending;
  bool Function()? _readDirty;
  bool Function()? _readSaving;
  Future<bool?> Function(BuildContext)? _confirm;
  void Function(BuildContext)? _onReturn;

  bool get isApproved => _approved;
  bool get isTransitioning => _transitioning;
  bool get isDirty => _readDirty?.call() ?? _isDirty;

  void bind({
    required bool Function() isDirty,
    required bool Function() isSaving,
    Future<bool?> Function(BuildContext)? confirm,
    void Function(BuildContext)? onReturn,
    bool preferReturn = false,
  }) {
    _preferReturn = preferReturn;
    _readDirty = isDirty;
    _readSaving = isSaving;
    _confirm = confirm;
    _onReturn = onReturn;
  }

  /// Retained for existing template-tool route callers.
  void update({required bool isDirty, required bool isSaving}) {
    if (_isDirty != isDirty || _isSaving != isSaving) _approved = false;
    _isDirty = isDirty;
    _isSaving = isSaving;
  }

  /// [discardConfirmed] shares consent only across drafts in the same task
  /// being removed together. Ordinary editor Close/Apply never supplies it.
  Future<bool> canExit(BuildContext context, {bool discardConfirmed = false}) {
    if (_pending case final pending?) return pending;
    final pending = _confirmExit(context, discardConfirmed: discardConfirmed);
    _pending = pending;

    return pending.whenComplete(() => _pending = null);
  }

  void holdApproval() {
    if (!_approved) return;
    _transitioning = true;
    _transitionExitAllowed = false;
    _transitionFocus ??= FocusManager.instance.primaryFocus;
    FocusManager.instance.primaryFocus?.unfocus();
    notifyListeners();
  }

  void finishTransition() {
    _transitionExitAllowed = true;
  }

  void releaseApproval({bool restoreFocus = true}) {
    final wasHeld = _transitioning;
    _approved = false;
    _transitioning = false;
    _transitionExitAllowed = false;
    final focus = _transitionFocus;
    _transitionFocus = null;
    notifyListeners();
    if (!restoreFocus || !wasHeld || focus == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_transitioning && focus.context != null) focus.requestFocus();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> pop(BuildContext context, [Object? result]) async {
    if (!await canExit(context) || !context.mounted) return;
    // Let PopScope observe approval before issuing the actual pop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
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
    _transitionFocus = null;
    _approved = false;
    _transitioning = false;
    _transitionExitAllowed = false;
    _isDirty = false;
    _isSaving = false;
  }

  Future<bool> _confirmExit(
    BuildContext context, {
    required bool discardConfirmed,
  }) async {
    if ((_transitioning && !_transitionExitAllowed) ||
        (_readSaving?.call() ?? _isSaving) ||
        !context.mounted) {
      return false;
    }
    if (_approved) return true;
    if (isDirty && !discardConfirmed) {
      final focus = FocusManager.instance.primaryFocus;
      final discard = await (_confirm ?? UnsavedChangesDialog.confirm)(context);
      if (discard != true || !context.mounted) {
        if (context.mounted && focus?.context != null) focus?.requestFocus();

        return false;
      }
      _transitionFocus = focus;
      // Saving may have started while the confirmation was open.
      if (_readSaving?.call() ?? _isSaving) return false;
    }
    _approved = true;
    notifyListeners();

    return true;
  }
}
