import 'dart:typed_data';

import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:flutter/widgets.dart';

class FakeBrowserWebViewService implements BrowserWebViewService {
  Map<Object?, Object?>? result;
  Map<Object?, Object?>? nextResult;
  final scriptedResults = <Object?>[];
  Uint8List? screenshotBytes;
  String? lastSource;
  int buildViewCount = 0;
  final actions = <String>[];

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
    buildViewCount++;

    return const SizedBox.expand();
  }

  @override
  bool hasController({required String sessionId, required String tabId}) =>
      false;

  @override
  Future<bool> canGoBack({
    required String sessionId,
    required String tabId,
  }) async => true;

  @override
  Future<bool> canGoForward({
    required String sessionId,
    required String tabId,
  }) async => true;

  @override
  Future<Object?> evaluateJavascript({
    required String sessionId,
    required String tabId,
    required String source,
  }) async {
    lastSource = source;
    if (scriptedResults.isNotEmpty) return scriptedResults.removeAt(0);

    return nextResult ?? result;
  }

  @override
  Future<void> goBack({
    required String sessionId,
    required String tabId,
  }) async {
    actions.add('back');
  }

  @override
  Future<void> goForward({
    required String sessionId,
    required String tabId,
  }) async {
    actions.add('forward');
  }

  @override
  Future<void> navigate({
    required String sessionId,
    required String tabId,
    required String url,
  }) async {
    actions.add('navigate');
  }

  @override
  Future<BrowserPageState> pageState({
    required String sessionId,
    required String tabId,
  }) async => (url: null, title: null, canGoBack: false, canGoForward: false);

  @override
  Future<BrowserPageState?> pageStateIfAttached({
    required String sessionId,
    required String tabId,
  }) async => null;

  @override
  Future<void> removeTab({
    required String sessionId,
    required String tabId,
  }) async {
    actions.add('remove');
  }

  @override
  Future<void> reload({
    required String sessionId,
    required String tabId,
  }) async {
    actions.add('reload');
  }

  @override
  Future<void> stopLoading({
    required String sessionId,
    required String tabId,
  }) async {
    actions.add('stop');
  }

  @override
  Future<void> scrollBy({
    required String sessionId,
    required String tabId,
    required int x,
    required int y,
  }) async {
    actions.add('scroll:$x:$y');
  }

  @override
  Future<Uint8List?> captureScreenshot({
    required String sessionId,
    required String tabId,
  }) async => screenshotBytes;
}
