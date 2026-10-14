import 'dart:async';

import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_webview_flutter/in_app_webview_flutter.dart';

typedef _BrowserWebViewKey = ({String sessionId, String tabId});

_BrowserWebViewKey _keyFor(String sessionId, String tabId) =>
    (sessionId: sessionId, tabId: tabId);

class BrowserWebViewAdapter implements BrowserWebViewService {
  final Map<_BrowserWebViewKey, InAppWebViewController> _controllers = {};
  final Map<_BrowserWebViewKey, Completer<InAppWebViewController>>
  _pendingControllers = {};
  final Map<_BrowserWebViewKey, Completer<void>> _pendingLoads = {};
  final Map<_BrowserWebViewKey, VoidCallback> _viewRecoveries = {};
  final Map<_BrowserWebViewKey, InAppWebViewKeepAlive> _keepAlives = {};
  final Set<_BrowserWebViewKey> _attachedBefore = {};
  final Set<_BrowserWebViewKey> _removedTabs = {};
  bool? _keepAliveSupported;

  bool get _supportsKeepAlive =>
      _keepAliveSupported ??= InAppWebView.isPropertySupported(
        PlatformInAppWebViewWidgetCreationParamsProperty.keepAlive,
      );

  @override
  Widget buildView({
    required String sessionId,
    required String tabId,
    required String initialUrl,
    required ValueChanged<String?> onTitleChanged,
    required ValueChanged<String?> onLoadStart,
    required ValueChanged<String?> onLoadStop,
    required VoidCallback onMainFrameError,
    required ValueChanged<String?> onVisitedHistory,
  }) {
    final key = _keyFor(sessionId, tabId);
    final keepAlive = _supportsKeepAlive
        ? _keepAlives.putIfAbsent(key, InAppWebViewKeepAlive.new)
        : null;

    return _InAppWebViewHost(
      service: this,
      sessionId: sessionId,
      tabId: tabId,
      initialUrl: keepAlive != null && _attachedBefore.contains(key)
          ? null
          : initialUrl,
      keepAlive: keepAlive,
      onTitleChanged: onTitleChanged,
      onLoadStart: onLoadStart,
      onLoadStop: onLoadStop,
      onMainFrameError: onMainFrameError,
      onVisitedHistory: onVisitedHistory,
    );
  }

  @override
  Future<void> removeTab({
    required String sessionId,
    required String tabId,
  }) async {
    final key = _keyFor(sessionId, tabId);
    if (_viewRecoveries.containsKey(key)) {
      final _ = _removedTabs.add(key);
    }
    final _ = _controllers.remove(key);
    final keepAlive = _keepAlives.remove(key);
    final _ = _attachedBefore.remove(key);
    final pending = _pendingControllers.remove(key);
    if (pending != null && !pending.isCompleted) {
      pending.completeError(StateError('Browser tab was closed.'));
    }
    final _ = _pendingLoads.remove(key);
    if (keepAlive != null) {
      await InAppWebViewController.disposeKeepAlive(keepAlive);
    }
  }

  @override
  bool hasController({required String sessionId, required String tabId}) =>
      _controllers.containsKey(_keyFor(sessionId, tabId));

  @override
  Future<BrowserPageState?> pageStateIfAttached({
    required String sessionId,
    required String tabId,
  }) async {
    final key = _keyFor(sessionId, tabId);
    final controller = _controllers[key];
    if (controller == null) return null;

    try {
      final page = await _readPageState(controller);
      if (!identical(_controllers[key], controller)) return null;

      return page;
    } on Object {
      if (!identical(_controllers[key], controller)) return null;
      rethrow;
    }
  }

  @override
  Future<BrowserPageState> pageState({
    required String sessionId,
    required String tabId,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );

    return await _readPageState(controller);
  }

  @override
  Future<bool> canGoBack({
    required String sessionId,
    required String tabId,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );

    return await controller.canGoBack();
  }

  @override
  Future<bool> canGoForward({
    required String sessionId,
    required String tabId,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );

    return await controller.canGoForward();
  }

  @override
  Future<void> navigate({
    required String sessionId,
    required String tabId,
    required String url,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );
    final pending = _expectLoad(sessionId, tabId);
    await controller.loadUrl(urlRequest: .new(url: .new(url)));
    await _waitForLoad(sessionId, tabId, pending);
  }

  @override
  Future<Object?> evaluateJavascript({
    required String sessionId,
    required String tabId,
    required String source,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );

    return await controller.evaluateJavascript(source: source);
  }

  @override
  Future<void> goBack({
    required String sessionId,
    required String tabId,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );
    await controller.goBack();
  }

  @override
  Future<void> goForward({
    required String sessionId,
    required String tabId,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );
    await controller.goForward();
  }

  @override
  Future<void> reload({
    required String sessionId,
    required String tabId,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );
    await controller.reload();
  }

  @override
  Future<void> stopLoading({
    required String sessionId,
    required String tabId,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );
    await controller.stopLoading();
  }

  @override
  Future<void> scrollBy({
    required String sessionId,
    required String tabId,
    required int x,
    required int y,
  }) async {
    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );
    await controller.scrollBy(x: x, y: y);
  }

  @override
  Future<Uint8List?> captureScreenshot({
    required String sessionId,
    required String tabId,
  }) async {
    if (!const {
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }.contains(defaultTargetPlatform)) {
      return null;
    }

    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );

    return await controller.takeScreenshot();
  }

  Future<InAppWebViewController> _waitForController({
    required String sessionId,
    required String tabId,
  }) async {
    final key = _keyFor(sessionId, tabId);
    final existing = _controllers[key];
    if (existing != null) return existing;

    var pending = _pendingControllers[key];
    if (pending == null) {
      pending = Completer<InAppWebViewController>();
      _pendingControllers[key] = pending;
      if (_attachedBefore.contains(key)) _viewRecoveries[key]?.call();
    }

    try {
      return await pending.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      if (identical(_pendingControllers[key], pending)) {
        final _ = _pendingControllers.remove(key);
      }
      rethrow;
    }
  }

  void _attach({
    required String sessionId,
    required String tabId,
    required InAppWebViewController controller,
  }) {
    final key = _keyFor(sessionId, tabId);
    if (_removedTabs.contains(key)) return;
    _controllers[key] = controller;
    final _ = _attachedBefore.add(key);
    final pending = _pendingControllers.remove(key);
    if (pending != null && !pending.isCompleted) pending.complete(controller);
  }

  void _detach({
    required String sessionId,
    required String tabId,
    required InAppWebViewController? controller,
  }) {
    final key = _keyFor(sessionId, tabId);
    if (controller != null &&
        identical(_controllers[key], controller) &&
        !_keepAlives.containsKey(key)) {
      final _ = _controllers.remove(key);
    }
  }

  void _registerRecovery(_BrowserWebViewKey key, VoidCallback recover) {
    _viewRecoveries[key] = recover;
  }

  void _unregisterRecovery(_BrowserWebViewKey key, VoidCallback recover) {
    if (_viewRecoveries[key] != recover) return;
    final _ = _viewRecoveries.remove(key);
    if (!_controllers.containsKey(key)) {
      final _ = _removedTabs.remove(key);
    }
  }

  Future<BrowserPageState> _readPageState(
    InAppWebViewController controller,
  ) async => (
    url: (await controller.getUrl())?.toString(),
    title: await controller.getTitle(),
    canGoBack: await controller.canGoBack(),
    canGoForward: await controller.canGoForward(),
  );

  Completer<void> _expectLoad(String sessionId, String tabId) {
    final key = _keyFor(sessionId, tabId);
    final pending = Completer<void>();
    _pendingLoads[key] = pending;

    return pending;
  }

  void _finishLoad(String sessionId, String tabId) {
    final pending = _pendingLoads.remove(_keyFor(sessionId, tabId));
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  Future<void> _waitForLoad(
    String sessionId,
    String tabId,
    Completer<void> pending,
  ) async {
    final key = _keyFor(sessionId, tabId);
    try {
      await pending.future.timeout(const Duration(seconds: 30));
    } on TimeoutException {
      if (identical(_pendingLoads[key], pending)) {
        final _ = _pendingLoads.remove(key);
      }
      rethrow;
    }
  }
}

class const _InAppWebViewHost({
  required final BrowserWebViewAdapter service,
  required final String sessionId,
  required final String tabId,
  required final String? initialUrl,
  required final InAppWebViewKeepAlive? keepAlive,
  required final ValueChanged<String?> onTitleChanged,
  required final ValueChanged<String?> onLoadStart,
  required final ValueChanged<String?> onLoadStop,
  required final VoidCallback onMainFrameError,
  required final ValueChanged<String?> onVisitedHistory,
}) extends StatefulWidget {
  @override
  State<_InAppWebViewHost> createState() => _InAppWebViewHostState();
}

class _InAppWebViewHostState extends State<_InAppWebViewHost> {
  InAppWebViewController? _controller;
  var _generation = 0;

  _BrowserWebViewKey get _key => _keyFor(widget.sessionId, widget.tabId);

  @override
  void initState() {
    super.initState();
    widget.service._registerRecovery(_key, _requestRecovery);
  }

  @override
  void dispose() {
    widget.service._unregisterRecovery(_key, _requestRecovery);
    widget.service._detach(
      sessionId: widget.sessionId,
      tabId: widget.tabId,
      controller: _controller,
    );
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _InAppWebViewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId == widget.sessionId &&
        oldWidget.tabId == widget.tabId) {
      return;
    }
    oldWidget.service._unregisterRecovery(
      _keyFor(oldWidget.sessionId, oldWidget.tabId),
      _requestRecovery,
    );
    oldWidget.service._detach(
      sessionId: oldWidget.sessionId,
      tabId: oldWidget.tabId,
      controller: _controller,
    );
    _controller = null;
    _generation = 0;
    widget.service._registerRecovery(_key, _requestRecovery);
  }

  @override
  Widget build(BuildContext context) {
    final initialUrl = widget.initialUrl;

    return InAppWebView(
      key: ValueKey((tabId: widget.tabId, generation: _generation)),
      keepAlive: widget.keepAlive,
      initialUrlRequest: initialUrl == null
          ? null
          : .new(url: .new(initialUrl)),
      onTitleChanged: (_, title) => widget.onTitleChanged(title),
      onReceivedError: _onReceivedError,
      onLoadStart: (_, url) => widget.onLoadStart(url?.toString()),
      onLoadStop: _onLoadStop,
      onUpdateVisitedHistory: _onUpdateVisitedHistory,
      onWebViewCreated: _onWebViewCreated,
    );
  }

  void _requestRecovery() {
    if (!mounted) return;
    setState(() => _generation++);
  }

  void _onLoadStop(InAppWebViewController _, WebUri? url) {
    widget.service._finishLoad(widget.sessionId, widget.tabId);
    widget.onLoadStop(url?.toString());
  }

  void _onReceivedError(
    InAppWebViewController _,
    WebResourceRequest request,
    WebResourceError _,
  ) {
    if (request.isForMainFrame ?? false) widget.onMainFrameError();
  }

  void _onUpdateVisitedHistory(
    InAppWebViewController _,
    WebUri? url,
    bool? _,
  ) => widget.onVisitedHistory(url?.toString());

  void _onWebViewCreated(InAppWebViewController controller) {
    _controller = controller;
    widget.service._attach(
      sessionId: widget.sessionId,
      tabId: widget.tabId,
      controller: controller,
    );
  }
}
