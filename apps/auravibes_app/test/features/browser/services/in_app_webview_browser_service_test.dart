import 'package:auravibes_app/features/browser/services/browser_web_view_adapter.dart';
import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_webview_flutter/in_app_webview_flutter.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('reattaches a previously mounted view after controller loss', (
    tester,
  ) async {
    final originalPlatformOverride = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = .linux;
    try {
      final platform = _TestInAppWebViewPlatform();
      InAppWebViewPlatform.instance = platform;
      final service = BrowserWebViewAdapter();

      BrowserWebViewRequest request(String initialUrl) => (
        sessionId: 'conversation',
        tabId: 'tab',
        initialUrl: initialUrl,
        onTitleChanged: (_) => expect(true, isTrue),
        onLoadStart: (_) => expect(true, isTrue),
        onLoadStop: (_) => expect(true, isTrue),
        onMainFrameError: () => expect(true, isTrue),
        onVisitedHistory: (_) => expect(true, isTrue),
      );

      Widget view() =>
          MaterialApp(home: service.buildView(request('about:blank')));

      await tester.pumpWidget(view());
      expect(
        service.hasController(sessionId: 'conversation', tabId: 'tab'),
        isTrue,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(view());
      expect(
        service.hasController(sessionId: 'conversation', tabId: 'tab'),
        isFalse,
      );

      final canGoBack = service.canGoBack(
        sessionId: 'conversation',
        tabId: 'tab',
      );
      await tester.pump();
      await tester.pump();

      expect(await canGoBack, isTrue);
      expect(platform.creationCount, 3);
      expect(
        service.hasController(sessionId: 'conversation', tabId: 'tab'),
        isTrue,
      );
    } finally {
      debugDefaultTargetPlatformOverride = originalPlatformOverride;
    }
  });

  testWidgets('keeps a WebView active while its host is unmounted', (
    tester,
  ) async {
    final originalPlatformOverride = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = .macOS;
    try {
      final platform = _TestInAppWebViewPlatform();
      InAppWebViewPlatform.instance = platform;
      final service = BrowserWebViewAdapter();

      BrowserWebViewRequest request(String initialUrl) => (
        sessionId: 'conversation',
        tabId: 'tab',
        initialUrl: initialUrl,
        onTitleChanged: (_) => expect(true, isTrue),
        onLoadStart: (_) => expect(true, isTrue),
        onLoadStop: (_) => expect(true, isTrue),
        onMainFrameError: () => expect(true, isTrue),
        onVisitedHistory: (_) => expect(true, isTrue),
      );

      Widget view() =>
          MaterialApp(home: service.buildView(request('https://example.com')));

      await tester.pumpWidget(view());
      final keepAlive = platform.creationParams.single.keepAlive;
      expect(keepAlive, isNotNull);
      expect(platform.creationParams.single.initialUrlRequest, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(
        service.hasController(sessionId: 'conversation', tabId: 'tab'),
        isTrue,
      );
      expect(
        await service.canGoBack(sessionId: 'conversation', tabId: 'tab'),
        isTrue,
      );

      await tester.pumpWidget(view());
      expect(platform.creationCount, 2);
      expect(platform.creationParams.last.keepAlive, same(keepAlive));
      expect(platform.creationParams.last.initialUrlRequest, isNull);
      expect(
        service.hasController(sessionId: 'conversation', tabId: 'tab'),
        isTrue,
      );

      await service.removeTab(sessionId: 'conversation', tabId: 'tab');
      expect(platform.disposedKeepAlives, 1);
      expect(
        service.hasController(sessionId: 'conversation', tabId: 'tab'),
        isFalse,
      );
    } finally {
      debugDefaultTargetPlatformOverride = originalPlatformOverride;
    }
  });
}

class _TestInAppWebViewPlatform extends InAppWebViewPlatform {
  int creationCount = 0;
  int disposedKeepAlives = 0;
  final List<PlatformInAppWebViewWidgetCreationParams> creationParams = [];

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidgetStatic() =>
      _TestInAppWebViewWidget.withParams(params: .new(), shouldAttach: false);

  @override
  PlatformInAppWebViewController createPlatformInAppWebViewControllerStatic() =>
      _TestPlatformController.forTest(
        onDisposeKeepAlive: () => disposedKeepAlives++,
      );

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    creationCount++;
    creationParams.add(params);

    return _TestInAppWebViewWidget.withParams(
      params: params,
      shouldAttach: creationCount != 2,
    );
  }
}

class _TestInAppWebViewWidget extends PlatformInAppWebViewWidget {
  new withParams({
    required PlatformInAppWebViewWidgetCreationParams params,
    required this.shouldAttach,
  }) : super.implementation(params);

  final bool shouldAttach;
  _TestPlatformController? _controller;
  var _didAttach = false;

  @override
  Widget build(BuildContext context) {
    if (shouldAttach && !_didAttach) {
      _didAttach = true;
      final platformController = _TestPlatformController.forTest();
      _controller = platformController;
      final controller = controllerFromPlatform<InAppWebViewController>(
        platformController,
      );
      params.onWebViewCreated?.call(controller);
    }

    return const SizedBox.expand();
  }

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      params.controllerFromPlatform?.call(controller) as T;

  @override
  void dispose() {
    _controller?.dispose(isKeepAlive: params.keepAlive != null);
    _controller = null;
    _didAttach = false;
  }
}

class _TestPlatformController extends PlatformInAppWebViewController {
  new forTest({this.onDisposeKeepAlive})
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 'test'),
      );

  final VoidCallback? onDisposeKeepAlive;

  @override
  Future<bool> canGoBack() async => true;

  @override
  Future<void> disposeKeepAlive(InAppWebViewKeepAlive keepAlive) async {
    onDisposeKeepAlive?.call();
  }

  @override
  void dispose({bool isKeepAlive = false}) {
    final _ = isKeepAlive;
  }
}
