import 'dart:typed_data';

import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:flutter/widgets.dart';

class FakeBrowserWebViewService
    implements BrowserWebViewHostService, BrowserWebViewControllerService {
  Map<Object?, Object?>? result;
  Map<Object?, Object?>? nextResult;
  final scriptedResults = <Object?>[];
  Uint8List? screenshotBytes;
  String? lastSource;
  int buildViewCount = 0;
  final actions = <String>[];

  BrowserWebViewService get service =>
      BrowserWebViewService(host: this, controller: this);

  @override
  Widget buildView(BrowserWebViewRequest request) {
    buildViewCount++;

    return const SizedBox.expand();
  }

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
