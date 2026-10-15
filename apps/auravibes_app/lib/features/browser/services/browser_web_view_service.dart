import 'dart:typed_data';

import 'package:flutter/widgets.dart';

typedef BrowserPageState = ({
  String? url,
  String? title,
  bool canGoBack,
  bool canGoForward,
});
typedef BrowserWebViewRequest = ({
  String sessionId,
  String tabId,
  String initialUrl,
  ValueChanged<String?> onTitleChanged,
  ValueChanged<String?> onLoadStart,
  ValueChanged<String?> onLoadStop,
  VoidCallback onMainFrameError,
  ValueChanged<String?> onVisitedHistory,
});

class const BrowserWebViewService({
  required final BrowserWebViewHostService host,
  required final BrowserWebViewControllerService controller,
});

abstract interface class BrowserWebViewHostService {
  Widget buildView(BrowserWebViewRequest request);

  Future<void> removeTab({required String sessionId, required String tabId});

  Future<BrowserPageState?> pageStateIfAttached({
    required String sessionId,
    required String tabId,
  });
}

abstract interface class BrowserWebViewControllerService {
  Future<bool> canGoBack({required String sessionId, required String tabId});

  Future<bool> canGoForward({required String sessionId, required String tabId});

  Future<void> navigate({
    required String sessionId,
    required String tabId,
    required String url,
  });

  Future<Object?> evaluateJavascript({
    required String sessionId,
    required String tabId,
    required String source,
  });

  Future<void> goBack({required String sessionId, required String tabId});

  Future<void> goForward({required String sessionId, required String tabId});

  Future<void> reload({required String sessionId, required String tabId});

  Future<void> stopLoading({required String sessionId, required String tabId});

  Future<void> scrollBy({
    required String sessionId,
    required String tabId,
    required int x,
    required int y,
  });

  Future<Uint8List?> captureScreenshot({
    required String sessionId,
    required String tabId,
  });
}
