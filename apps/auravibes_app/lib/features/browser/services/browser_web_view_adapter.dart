import 'dart:async';

import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_webview_flutter/in_app_webview_flutter.dart';

typedef _BrowserWebViewKey = ({String sessionId, String tabId});
typedef _InAppWebViewHostRequest = ({
  BrowserWebViewAdapter service,
  BrowserWebViewRequest browserView,
  String? initialUrl,
  InAppWebViewKeepAlive? keepAlive,
});
typedef _RemovedBrowserWebViewTab = ({
  InAppWebViewKeepAlive? keepAlive,
  Completer<InAppWebViewController>? pendingController,
});

_BrowserWebViewKey _keyFor(String sessionId, String tabId) =>
    (sessionId: sessionId, tabId: tabId);

InAppWebViewController _inAppControllerFromPlatform(
  PlatformInAppWebViewController controller,
) => InAppWebViewController.fromPlatform(platform: controller);

URLRequest? _initialWebViewRequest(String? url) =>
    url == null ? null : .new(url: .new(url));

InAppWebViewController _controllerFromCallback(Object? controller) =>
    switch (controller) {
      final InAppWebViewController inAppController => inAppController,
      final PlatformInAppWebViewController platformController =>
        InAppWebViewController.fromPlatform(platform: platformController),
      _ => throw StateError('Unexpected WebView controller.'),
    };

abstract class _BrowserWebViewAdapterBase
    implements BrowserWebViewHostService, BrowserWebViewControllerService {
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

  Future<InAppWebViewController> _waitForController({
    required String sessionId,
    required String tabId,
  });

  Future<BrowserPageState> _readPageState(InAppWebViewController controller);

  Completer<void> _expectLoad(String sessionId, String tabId);

  Future<void> _waitForLoad(
    String sessionId,
    String tabId,
    Completer<void> pending,
  );
}

mixin _BrowserWebViewHostOperations on _BrowserWebViewAdapterBase {
  @override
  Widget buildView(BrowserWebViewRequest request) => _InAppWebViewHost(
    request: _newInAppWebViewHostRequest(
      this as BrowserWebViewAdapter,
      request,
    ),
  );
}

mixin _BrowserWebViewTabRemovalOperations on _BrowserWebViewAdapterBase {
  @override
  Future<void> removeTab({
    required String sessionId,
    required String tabId,
  }) async {
    final key = _keyFor(sessionId, tabId);
    final removed = _removeTabState(key);
    _failRemovedTabController(removed.pendingController);
    final _ = _pendingLoads.remove(key);
    await _disposeRemovedTab(removed.keepAlive);
  }

  void _failRemovedTabController(Completer<InAppWebViewController>? pending) {
    if (pending == null || pending.isCompleted) return;
    pending.completeError(StateError('Browser tab was closed.'));
  }

  Future<void> _disposeRemovedTab(InAppWebViewKeepAlive? keepAlive) async {
    if (keepAlive == null) return;
    await InAppWebViewController.disposeKeepAlive(keepAlive);
  }

  _RemovedBrowserWebViewTab _removeTabState(_BrowserWebViewKey key) {
    if (_viewRecoveries.containsKey(key)) {
      final _ = _removedTabs.add(key);
    }
    final _ = _controllers.remove(key);
    final keepAlive = _keepAlives.remove(key);
    final _ = _attachedBefore.remove(key);

    return (
      keepAlive: keepAlive,
      pendingController: _pendingControllers.remove(key),
    );
  }
}

mixin _BrowserWebViewControllerReadOperations on _BrowserWebViewAdapterBase {
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
}

extension _BrowserControllerAttachment on _BrowserWebViewAdapterBase {
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
}

_InAppWebViewHostRequest _newInAppWebViewHostRequest(
  BrowserWebViewAdapter service,
  BrowserWebViewRequest request,
) => _buildInAppWebViewHostRequest(
  service,
  request,
  _keyFor(request.sessionId, request.tabId),
);

_InAppWebViewHostRequest _buildInAppWebViewHostRequest(
  BrowserWebViewAdapter service,
  BrowserWebViewRequest request,
  _BrowserWebViewKey key,
) {
  final keepAlive = service._supportsKeepAlive
      ? service._keepAlives.putIfAbsent(key, InAppWebViewKeepAlive.new)
      : null;
  final initialUrl = keepAlive != null && service._attachedBefore.contains(key)
      ? null
      : request.initialUrl;

  return (
    service: service,
    browserView: request,
    initialUrl: initialUrl,
    keepAlive: keepAlive,
  );
}

mixin _BrowserWebViewControllerLifecycle on _BrowserWebViewAdapterBase {
  @override
  Future<InAppWebViewController> _waitForController({
    required String sessionId,
    required String tabId,
  }) {
    final key = _keyFor(sessionId, tabId);
    final existing = _controllers[key];
    if (existing != null) return Future.value(existing);

    final pending = _pendingControllers.putIfAbsent(
      key,
      () => _createPendingController(key),
    );

    return _awaitController(key, pending);
  }

  Completer<InAppWebViewController> _createPendingController(
    _BrowserWebViewKey key,
  ) {
    final pending = Completer<InAppWebViewController>();
    if (_attachedBefore.contains(key)) _viewRecoveries[key]?.call();

    return pending;
  }

  Future<InAppWebViewController> _awaitController(
    _BrowserWebViewKey key,
    Completer<InAppWebViewController> pending,
  ) async {
    try {
      return await pending.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      _removePendingController(key, pending);
      rethrow;
    }
  }

  void _removePendingController(
    _BrowserWebViewKey key,
    Completer<InAppWebViewController> pending,
  ) {
    if (identical(_pendingControllers[key], pending)) {
      final _ = _pendingControllers.remove(key);
    }
  }
}

mixin _BrowserWebViewReadOperations on _BrowserWebViewAdapterBase {
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
  Future<BrowserPageState> _readPageState(
    InAppWebViewController controller,
  ) async => (
    url: (await controller.getUrl())?.toString(),
    title: await controller.getTitle(),
    canGoBack: await controller.canGoBack(),
    canGoForward: await controller.canGoForward(),
  );
}

mixin _BrowserWebViewNavigationOperations on _BrowserWebViewAdapterBase {
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
    if (!_supportsBrowserScreenshot) return null;

    final controller = await _waitForController(
      sessionId: sessionId,
      tabId: tabId,
    );

    return await controller.takeScreenshot();
  }
}

const Set<TargetPlatform> _browserScreenshotPlatforms = {
  TargetPlatform.android,
  TargetPlatform.iOS,
  TargetPlatform.macOS,
  TargetPlatform.windows,
};

bool get _supportsBrowserScreenshot =>
    _browserScreenshotPlatforms.contains(defaultTargetPlatform);

mixin _BrowserWebViewLoadOperations on _BrowserWebViewAdapterBase {
  @override
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

  @override
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

class BrowserWebViewAdapter extends _BrowserWebViewAdapterBase
    with
        _BrowserWebViewHostOperations,
        _BrowserWebViewTabRemovalOperations,
        _BrowserWebViewControllerReadOperations,
        _BrowserWebViewControllerLifecycle,
        _BrowserWebViewReadOperations,
        _BrowserWebViewNavigationOperations,
        _BrowserWebViewLoadOperations;

class const _InAppWebViewHost({required final _InAppWebViewHostRequest request})
    extends StatefulWidget {
  @override
  State<_InAppWebViewHost> createState() => _InAppWebViewHostState();
}

class _InAppWebViewHostState extends State<_InAppWebViewHost> {
  InAppWebViewController? _controller;
  var _generation = 0;

  _BrowserWebViewKey get _key => _keyFor(
    widget.request.browserView.sessionId,
    widget.request.browserView.tabId,
  );
  BrowserWebViewAdapter get _service => widget.request.service;
  BrowserWebViewRequest get _browserView => widget.request.browserView;

  @override
  void initState() {
    super.initState();
    _service._registerRecovery(_key, _requestRecovery);
  }

  @override
  void dispose() {
    _unregisterAndDetach(widget.request);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _InAppWebViewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameWebViewTab(oldWidget.request.browserView, _browserView)) return;
    _unregisterAndDetach(oldWidget.request);
    _controller = null;
    _generation = 0;
    _service._registerRecovery(_key, _requestRecovery);
  }

  @override
  Widget build(BuildContext context) => _buildInAppWebView();

  void _requestRecovery() {
    if (!mounted) return;
    setState(() => _generation++);
  }
}

extension _InAppWebViewHostCallbacks on _InAppWebViewHostState {
  Widget _buildInAppWebView() {
    final request = widget.request;
    final browserView = request.browserView;

    return InAppWebView.fromPlatformCreationParams(
      key: ValueKey((tabId: browserView.tabId, generation: _generation)),
      params: _inAppWebViewCreationParams(request),
    );
  }

  PlatformInAppWebViewWidgetCreationParams _inAppWebViewCreationParams(
    _InAppWebViewHostRequest request,
  ) => PlatformInAppWebViewWidgetCreationParams(
    keepAlive: request.keepAlive,
    controllerFromPlatform: _inAppControllerFromPlatform,
    onWebViewCreated: _onWebViewCreated,
    onLoadStart: _onLoadStart,
    onLoadStop: _onLoadStop,
    onReceivedError: _onReceivedError,
    onUpdateVisitedHistory: _onUpdateVisitedHistory,
    onTitleChanged: _onTitleChanged,
    initialUrlRequest: _initialWebViewRequest(request.initialUrl),
  );

  void _onLoadStop(Object? _, WebUri? url) {
    _service._finishLoad(_browserView.sessionId, _browserView.tabId);
    _browserView.onLoadStop(url?.toString());
  }

  void _onReceivedError(
    Object? _,
    WebResourceRequest request,
    WebResourceError _,
  ) {
    if (request.isForMainFrame ?? false) _browserView.onMainFrameError();
  }

  void _onUpdateVisitedHistory(Object? _, WebUri? url, bool? _) =>
      _browserView.onVisitedHistory(url?.toString());

  void _onWebViewCreated(Object? controller) {
    final inAppController = _controllerFromCallback(controller);
    _controller = inAppController;
    _service._attach(
      sessionId: _browserView.sessionId,
      tabId: _browserView.tabId,
      controller: inAppController,
    );
  }

  void _unregisterAndDetach(_InAppWebViewHostRequest request) {
    final browserView = request.browserView;
    final key = _keyFor(browserView.sessionId, browserView.tabId);
    request.service._unregisterRecovery(key, _requestRecovery);
    request.service._detach(
      sessionId: browserView.sessionId,
      tabId: browserView.tabId,
      controller: _controller,
    );
  }

  bool _sameWebViewTab(
    BrowserWebViewRequest previous,
    BrowserWebViewRequest current,
  ) =>
      previous.sessionId == current.sessionId &&
      previous.tabId == current.tabId;

  void _onTitleChanged(Object? _, String? title) =>
      _browserView.onTitleChanged(title);

  void _onLoadStart(Object? _, WebUri? url) =>
      _browserView.onLoadStart(url?.toString());
}
