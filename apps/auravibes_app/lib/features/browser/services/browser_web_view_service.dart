import 'dart:typed_data';

import 'package:flutter/widgets.dart';

typedef BrowserPageState = ({
  String? url,
  String? title,
  bool canGoBack,
  bool canGoForward,
});

abstract interface class BrowserWebViewService {
  Widget buildView({
    required String sessionId,
    required String tabId,
    required String initialUrl,
    required ValueChanged<String?> onTitleChanged,
    required ValueChanged<String?> onLoadStart,
    required ValueChanged<String?> onLoadStop,
    required VoidCallback onMainFrameError,
    required ValueChanged<String?> onVisitedHistory,
  });

  Future<void> removeTab({required String sessionId, required String tabId});

  bool hasController({required String sessionId, required String tabId});

  Future<BrowserPageState?> pageStateIfAttached({
    required String sessionId,
    required String tabId,
  });

  Future<BrowserPageState> pageState({
    required String sessionId,
    required String tabId,
  });

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
