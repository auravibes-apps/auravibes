import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/browser/models/browser_session_state.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_providers.dart';
import 'package:auravibes_app/features/browser/services/browser_web_view_service.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:toon_dart/toon_dart.dart';
import 'package:uuid/uuid.dart';

part 'browser_session_notifier.g.dart';

const int _maxToolScreenshotBytes = 5 * 1024 * 1024;

@riverpod
class BrowserSessionNotifier extends _$BrowserSessionNotifier {
  final Map<String, String> _snapshotIdsByTab = <String, String>{};
  KeepAliveLink? _sessionKeepAliveLink;

  BrowserWebViewService get _webViewService =>
      ref.read(browserWebViewServiceProvider);
  BrowserSessionState get _current => state.requireValue;

  @override
  Future<BrowserSessionState> build(
    String workspaceId,
    String conversationId,
  ) async {
    final session = await (await ref.watch(
      browserSessionRepositoryProvider.future,
    )).load(conversationId);
    if (session.tabs.isNotEmpty && !session.isSuspended) _retainSession();

    return session;
  }

  Future<void> openTab({String url = 'about:blank'}) async {
    _recordAgentActivity('open_tab');
    _retainSession();
    final current = _current;
    final tab = BrowserTab(id: const Uuid().v4(), url: url);
    await _save(
      current.copyWith(
        tabs: [...current.tabs, tab],
        activeTabId: tab.id,
        isSuspended: false,
      ),
    );
  }

  Future<void> selectTab(String tabId) async {
    final current = _current;
    if (!current.tabs.any((tab) => tab.id == tabId)) {
      throw ArgumentError.value(tabId, 'tabId', 'Unknown browser tab.');
    }

    if (current.isSuspended) _retainSession();
    await _save(current.copyWith(activeTabId: tabId, isSuspended: false));
    if (!ref.mounted) return;
    _recordAgentActivity('select_tab');
    await _refreshActiveTab();
  }

  Future<void> closeTab(String tabId) async {
    final current = _current;
    final tabIndex = current.tabs.indexWhere((tab) => tab.id == tabId);
    if (tabIndex < 0) return;

    final _ = _snapshotIdsByTab.remove(tabId);
    if (!current.isSuspended) {
      await _webViewService.removeTab(sessionId: conversationId, tabId: tabId);
    }
    final tabs = [...current.tabs]..removeAt(tabIndex);
    var activeTabId = current.activeTabId;
    if (tabs.isEmpty) {
      activeTabId = '';
    } else if (current.activeTabId == tabId) {
      final replacementIndex = tabIndex < tabs.length
          ? tabIndex
          : tabs.length - 1;
      activeTabId = tabs[replacementIndex].id;
    }
    await _save(
      current.copyWith(
        tabs: tabs,
        activeTabId: activeTabId,
        isLoading: tabs.isEmpty ? false : null,
        hasError: tabs.isEmpty ? false : null,
        canGoBack: tabs.isEmpty ? false : null,
        canGoForward: tabs.isEmpty ? false : null,
        isSuspended: tabs.isEmpty ? false : null,
      ),
    );
    if (tabs.isEmpty) _releaseSession();
    if (!ref.mounted) return;
    if (current.activeTabId == tabId && tabs.isNotEmpty) {
      await _refreshActiveTab();
    }
    if (!ref.mounted) return;
    _recordAgentActivity('close_tab');
  }

  Future<void> suspend() async {
    final current = _current;
    if (current.tabs.isEmpty || current.isSuspended) return;

    for (final tab in current.tabs) {
      final _ = _snapshotIdsByTab.remove(tab.id);
      await _webViewService.removeTab(sessionId: conversationId, tabId: tab.id);
    }

    await _save(
      current.copyWith(
        isSuspended: true,
        isLoading: false,
        hasError: false,
        canGoBack: false,
        canGoForward: false,
      ),
    );
    _releaseSession();
  }

  Future<void> resume() async {
    final current = _current;
    if (current.tabs.isEmpty || !current.isSuspended) return;

    _retainSession();
    await _save(current.copyWith(isSuspended: false));
  }

  Future<void> closeAllTabs() async {
    final current = _current;
    if (current.tabs.isEmpty) return;

    for (final tab in current.tabs) {
      final _ = _snapshotIdsByTab.remove(tab.id);
      if (!current.isSuspended) {
        await _webViewService.removeTab(
          sessionId: conversationId,
          tabId: tab.id,
        );
      }
    }

    await _save(
      current.copyWith(
        tabs: const [],
        activeTabId: '',
        isLoading: false,
        hasError: false,
        canGoBack: false,
        canGoForward: false,
        isSuspended: false,
      ),
    );
    _releaseSession();
  }

  Future<void> navigate(String url, {String? tabId}) async {
    final targetId = _targetTabId(tabId);
    final normalizedUrl = _normalizeUrl(url);
    _recordAgentActivity('navigating');
    await updateTab(targetId, url: normalizedUrl, isLoading: true);
    if (!ref.mounted) return;
    try {
      await _webViewService.navigate(
        sessionId: conversationId,
        tabId: targetId,
        url: normalizedUrl,
      );
      if (!ref.mounted) return;
      _recordAgentActivity('navigated');
    } on Object {
      if (!ref.mounted) rethrow;
      await updateTab(targetId, isLoading: false, hasError: true);
      rethrow;
    }
  }

  Future<void> updateTab(
    String tabId, {
    String? url,
    String? title,
    bool? isLoading,
    bool? hasError,
    bool? canGoBack,
    bool? canGoForward,
  }) async {
    if (isLoading == true) {
      final _ = _snapshotIdsByTab.remove(tabId);
    }
    final current = _current;
    final tabs = current.tabs
        .map(
          (tab) => tab.id == tabId ? tab.copyWith(url: url, title: title) : tab,
        )
        .toList(growable: false);
    final isActive = current.activeTabId == tabId;
    await _save(
      current.copyWith(
        tabs: tabs,
        isLoading: isActive ? isLoading : null,
        hasError: isActive ? hasError : null,
        canGoBack: isActive ? canGoBack : null,
        canGoForward: isActive ? canGoForward : null,
      ),
    );
  }

  Future<Object?> executeJavaScript(String source, {String? tabId}) async {
    if (source.trim().isEmpty) {
      throw ArgumentError.value(source, 'source', 'JavaScript is empty.');
    }

    final targetId = _targetTabId(tabId);
    _recordAgentActivity('running_javascript');
    final result = await _webViewService.evaluateJavascript(
      sessionId: conversationId,
      tabId: targetId,
      source: source,
    );
    if (!ref.mounted) return result;
    _recordAgentActivity('ran_javascript');

    return result;
  }

  Future<bool> goBack({String? tabId}) async {
    if (tabId != null) await selectTab(tabId);
    _recordAgentActivity('going_back');
    final activeTabId = _targetTabId(tabId);
    final _ = _snapshotIdsByTab.remove(activeTabId);
    final canGoBack = await _webViewService.canGoBack(
      sessionId: conversationId,
      tabId: activeTabId,
    );
    if (!ref.mounted) return false;
    if (!canGoBack) return false;
    await _webViewService.goBack(sessionId: conversationId, tabId: activeTabId);
    if (!ref.mounted) return false;
    _recordAgentActivity('went_back');

    return true;
  }

  Future<bool> goForward({String? tabId}) async {
    if (tabId != null) await selectTab(tabId);
    _recordAgentActivity('going_forward');
    final activeTabId = _targetTabId(tabId);
    final _ = _snapshotIdsByTab.remove(activeTabId);
    final canGoForward = await _webViewService.canGoForward(
      sessionId: conversationId,
      tabId: activeTabId,
    );
    if (!ref.mounted) return false;
    if (!canGoForward) return false;
    await _webViewService.goForward(
      sessionId: conversationId,
      tabId: activeTabId,
    );
    if (!ref.mounted) return false;
    _recordAgentActivity('went_forward');

    return true;
  }

  Future<void> reload({String? tabId}) async {
    if (tabId != null) await selectTab(tabId);
    final activeTabId = _targetTabId(tabId);
    final _ = _snapshotIdsByTab.remove(activeTabId);
    _recordAgentActivity('reloading');
    await _webViewService.reload(sessionId: conversationId, tabId: activeTabId);
    if (!ref.mounted) return;
    _recordAgentActivity('reloaded');
  }

  Future<Object?> runSkillTool(
    String toolSlug,
    Map<String, dynamic> arguments,
  ) async {
    _recordBrowserSkillAction();
    if (_current.isSuspended &&
        toolSlug != 'browser_list_tabs' &&
        toolSlug != 'browser_close_tab') {
      await resume();
    }

    return switch (toolSlug) {
      'browser_list_tabs' => _listToolTabs(),
      'browser_open_tab' => await _openToolTab(arguments),
      'browser_close_tab' => await _closeToolTab(arguments),
      'browser_select_tab' => await _selectToolTab(arguments),
      'browser_navigate' => await _navigateToolTab(arguments),
      'browser_go_back' => await _historyTool(arguments, goBack),
      'browser_go_forward' => await _historyTool(arguments, goForward),
      'browser_reload' => await _reloadTool(arguments),
      'browser_execute_javascript' => await _executeToolJavaScript(arguments),
      'browser_read_page' => await _readToolPage(arguments),
      'browser_query_page' => await _queryToolPage(arguments),
      'browser_snapshot' => await _snapshotTool(arguments),
      'browser_find' => await _findTool(arguments),
      'browser_wait_for' => await _waitTool(arguments),
      'browser_click' => await _runBrowserElementAction(
        arguments,
        action: 'click',
      ),
      'browser_fill' => await _runBrowserElementAction(
        arguments,
        action: 'fill',
      ),
      'browser_select_option' => await _runBrowserElementAction(
        arguments,
        action: 'select_option',
      ),
      'browser_set_checked' => await _runBrowserElementAction(
        arguments,
        action: 'set_checked',
      ),
      'browser_scroll' => await _scrollTool(arguments),
      'browser_capture_screenshot' => await _captureScreenshotTool(arguments),
      _ => throw FormatException('Unknown browser tool: $toolSlug'),
    };
  }

  List<Map<String, Object?>> _listToolTabs() {
    _recordAgentActivity('listing_tabs');

    return _current.tabs
        .map((tab) => {'id': tab.id, 'url': tab.url, 'title': tab.title})
        .toList(growable: false);
  }

  Future<Object?> _openToolTab(Map<String, dynamic> arguments) async {
    final url = arguments['url'];
    if (url != null && url is! String) {
      throw const FormatException('Browser tab URL must be a string.');
    }
    final normalizedUrl = url is String && url.trim().isNotEmpty
        ? _normalizeAgentUrl(url)
        : null;
    await openTab();
    if (!ref.mounted) throw StateError('Browser session closed.');
    final tab = _current.activeTab;
    if (tab == null) throw StateError('Browser tab did not open.');
    if (normalizedUrl != null) await navigate(normalizedUrl);
    if (!ref.mounted) throw StateError('Browser session closed.');

    return {'id': tab.id, 'url': _current.activeTab?.url ?? tab.url};
  }

  Future<Object?> _closeToolTab(Map<String, dynamic> arguments) async {
    final tabId = _requiredString(arguments, 'tabId');
    await closeTab(tabId);

    return {'closed': true, 'tabId': tabId};
  }

  Future<Object?> _selectToolTab(Map<String, dynamic> arguments) async {
    final tabId = _requiredString(arguments, 'tabId');
    await selectTab(tabId);

    return {'activeTabId': tabId};
  }

  Future<Object?> _navigateToolTab(Map<String, dynamic> arguments) async {
    final url = _requiredString(arguments, 'url');
    final normalizedUrl = _normalizeAgentUrl(url);
    final tabId = arguments['tabId'] as String?;
    if (tabId != null) await selectTab(tabId);
    await navigate(normalizedUrl, tabId: tabId);

    return {
      'url': _current.tabs
          .firstWhere((tab) => tab.id == (tabId ?? _current.activeTabId))
          .url,
    };
  }

  Future<Object?> _executeToolJavaScript(Map<String, dynamic> arguments) async {
    final tabId = arguments['tabId'] as String?;
    if (tabId != null) await selectTab(tabId);

    return _boundedBrowserResult(
      await executeJavaScript(
        _requiredString(arguments, 'source'),
        tabId: tabId,
      ),
    );
  }

  Future<Object?> _readToolPage(Map<String, dynamic> arguments) async {
    final tabId = arguments['tabId'] as String?;
    if (tabId != null) await selectTab(tabId);
    final page = await _pageMarkup(tabId);
    final format = _contentFormat(arguments['format']);
    final url = (page['url'] as String? ?? '').truncateCharacters(2048);
    final title = (page['title'] as String? ?? '').truncateCharacters(512);
    final content = _formatBrowserContent(
      page['html'] as String? ?? '',
      format == 'toon' ? 'text' : format,
      maxLength: format == 'toon' ? 10000 : 12000,
    );

    return format == 'toon'
        ? toonEncode({'url': url, 'title': title, 'content': content})
        : {'url': url, 'title': title, 'format': format, 'content': content};
  }

  Future<Object?> _historyTool(
    Map<String, dynamic> arguments,
    Future<bool> Function({String? tabId}) action,
  ) async {
    final tabId = arguments['tabId'] as String?;
    final changed = await action(tabId: tabId);

    return {'changed': changed, 'tabId': tabId ?? _current.activeTabId};
  }

  Future<Object?> _reloadTool(Map<String, dynamic> arguments) async {
    final tabId = arguments['tabId'] as String?;
    await reload(tabId: tabId);

    return {'reloaded': true, 'tabId': tabId ?? _current.activeTabId};
  }

  Future<Object?> _queryToolPage(Map<String, dynamic> arguments) async {
    final tabId = arguments['tabId'] as String?;
    if (tabId != null) await selectTab(tabId);
    final selector = _requiredString(arguments, 'selector');
    final limit = arguments['limit'];
    if (limit != null && (limit is! int || limit < 1 || limit > 5)) {
      throw const FormatException(
        'Browser query limit must be between 1 and 5.',
      );
    }
    if (selector.length > 256) {
      throw const FormatException(
        'Browser query selector exceeds 256 characters.',
      );
    }
    final format = _contentFormat(arguments['format']);
    final source =
        '''
(() => {
  try {
    const selector = ${jsonEncode(selector)};
    const nodes = document.querySelectorAll(selector);
    const clean = node => {
      const clone = node.cloneNode(true);
      const removed = 'script,style,noscript,iframe,object,embed,svg,canvas,' +
        'input[type="hidden"],input[type="password"]';
      if (clone.matches(removed)) return { html: '', text: '' };
      clone.querySelectorAll(removed).forEach(el => el.remove());
      clone.querySelectorAll('input,textarea,select').forEach(el => {
        el.removeAttribute('value');
        if ('value' in el) el.value = '';
        if (el.tagName === 'TEXTAREA') el.textContent = '';
        if (el.tagName === 'SELECT') el.selectedIndex = -1;
        el.querySelectorAll('option').forEach(option => {
          option.removeAttribute('value');
          option.removeAttribute('selected');
        });
      });
      return {
        html: clone.outerHTML.slice(0, 2400)
      };
    };
    const matches = Array.from(nodes).slice(0, ${limit ?? 1});
    return {
      url: location.href,
      title: document.title,
      count: nodes.length,
      matches: matches.map(clean)
    };
  } catch (error) {
    return { error: String(error) };
  }
})()
''';
    final page = await executeJavaScript(source, tabId: tabId);
    if (page is! Map<Object?, Object?>) {
      return _boundedBrowserResult(page);
    }
    final error = page['error'];
    if (error is String) {
      throw FormatException(error);
    }
    final url = (page['url'] as String? ?? '').truncateCharacters(2048);
    final title = (page['title'] as String? ?? '').truncateCharacters(512);
    final rawMatches = page['matches'];
    final matches =
        (rawMatches is List<Object?> ? rawMatches : const <Object?>[])
            .whereType<Map<Object?, Object?>>()
            .map(
              (match) => _formatBrowserContent(
                match['html'] as String? ?? '',
                format == 'toon' ? 'text' : format,
                maxLength: 1600,
              ),
            )
            .toList(growable: false);
    final result = {
      'url': url,
      'title': title,
      'count': page['count'],
      'format': format,
      'matches': matches,
    };

    return format == 'toon'
        ? toonEncode(result)
        : _boundedBrowserResult(result);
  }

  Future<Object?> _snapshotTool(Map<String, dynamic> arguments) async {
    final tabId = _optionalTabId(arguments);
    if (tabId != null) await selectTab(tabId);
    _recordAgentActivity('snapshotting');
    final snapshot = await _captureSnapshot(_targetTabId(tabId));
    if (!ref.mounted) return snapshot;
    _recordAgentActivity('snapshot_ready');

    return _boundedBrowserResult(snapshot);
  }

  Future<Object?> _findTool(Map<String, dynamic> arguments) async {
    final tabId = _optionalTabId(arguments);
    final role = _optionalString(arguments, 'role');
    final name = _optionalString(arguments, 'name');
    final text = _optionalString(arguments, 'text');
    if (role == null && name == null && text == null) {
      throw const FormatException(
        'Browser find requires a role, name, or text.',
      );
    }
    final limit = _boundedInteger(
      arguments['limit'],
      name: 'limit',
      defaultValue: 10,
      min: 1,
      max: 10,
    );
    if (tabId != null) await selectTab(tabId);
    _recordAgentActivity('finding');
    final snapshot = await _captureSnapshot(_targetTabId(tabId));
    final elements = _snapshotElements(snapshot);
    final matches = elements
        .where(
          (element) => _matchesSnapshotElement(
            element,
            role: role,
            name: name,
            text: text,
          ),
        )
        .toList(growable: false);
    if (!ref.mounted) return matches.take(limit).toList(growable: false);
    _recordAgentActivity('found');

    return _boundedBrowserResult({
      'url': snapshot['url'],
      'title': snapshot['title'],
      'count': matches.length,
      'matches': matches.take(limit).toList(growable: false),
    });
  }

  Future<Object?> _waitTool(Map<String, dynamic> arguments) async {
    final tabId = _optionalTabId(arguments);
    final selector = _optionalString(arguments, 'selector');
    final role = _optionalString(arguments, 'role');
    final name = _optionalString(arguments, 'name');
    final text = _optionalString(arguments, 'text');
    if (selector == null && role == null && name == null && text == null) {
      throw const FormatException(
        'Browser wait requires a selector, role, name, or text.',
      );
    }
    if (selector != null && selector.length > 256) {
      throw const FormatException(
        'Browser wait selector exceeds 256 characters.',
      );
    }
    final timeoutMs = _boundedInteger(
      arguments['timeoutMs'],
      name: 'timeoutMs',
      defaultValue: 5000,
      min: 1,
      max: 30000,
    );
    if (tabId != null) await selectTab(tabId);
    final targetTabId = _targetTabId(tabId);
    final stopwatch = Stopwatch()..start();
    _recordAgentActivity('waiting');
    Map<Object?, Object?>? matchedSnapshot;

    while (true) {
      if (selector != null) {
        final result = await executeJavaScript(
          _selectorVisibilityScript(selector),
          tabId: targetTabId,
        );
        if (result is Map<Object?, Object?>) {
          final error = result['error'];
          if (error is String) throw FormatException(error);
        }
        if (result == true ||
            (result is Map<Object?, Object?> && result['found'] == true)) {
          matchedSnapshot = await _captureSnapshot(targetTabId);
          break;
        }
      } else {
        final snapshot = await _captureSnapshot(targetTabId);
        final found = _snapshotElements(snapshot).any(
          (element) => _matchesSnapshotElement(
            element,
            role: role,
            name: name,
            text: text,
          ),
        );
        if (found) {
          matchedSnapshot = snapshot;
          break;
        }
      }

      final remainingMs = timeoutMs - stopwatch.elapsedMilliseconds;
      if (remainingMs <= 0) break;
      await Future<void>.delayed(
        .new(milliseconds: remainingMs < 100 ? remainingMs : 100),
      );
      if (!ref.mounted) throw StateError('Browser session closed.');
    }

    if (matchedSnapshot case final snapshot?) {
      _recordAgentActivity('waited');

      return _boundedBrowserResult({'found': true, 'snapshot': snapshot});
    }

    _recordAgentActivity('wait_timed_out');

    return {'found': false, 'timeoutMs': timeoutMs};
  }

  Future<Object?> _scrollTool(Map<String, dynamic> arguments) async {
    final tabId = _optionalTabId(arguments);
    final x = _boundedInteger(
      arguments['x'],
      name: 'x',
      defaultValue: 0,
      min: -10000,
      max: 10000,
    );
    final y = _boundedInteger(
      arguments['y'],
      name: 'y',
      defaultValue: 0,
      min: -10000,
      max: 10000,
    );
    if (x == 0 && y == 0) {
      throw const FormatException('Browser scroll requires non-zero x or y.');
    }
    if (tabId != null) await selectTab(tabId);
    final targetTabId = _targetTabId(tabId);
    _recordAgentActivity('scrolling');
    await _webViewService.scrollBy(
      sessionId: conversationId,
      tabId: targetTabId,
      x: x,
      y: y,
    );
    final result = await executeJavaScript(
      '({x: window.scrollX, y: window.scrollY})',
      tabId: targetTabId,
    );
    if (!ref.mounted) return {'scrolled': true};
    _recordAgentActivity('scrolled');

    return result is Map<Object?, Object?>
        ? {
            'scrolled': true,
            if (result['x'] is num) 'x': result['x'],
            if (result['y'] is num) 'y': result['y'],
          }
        : {'scrolled': true};
  }

  Future<Object?> _captureScreenshotTool(Map<String, dynamic> arguments) async {
    final tabId = _optionalTabId(arguments);
    if (tabId != null) await selectTab(tabId);
    final targetTabId = _targetTabId(tabId);
    _recordAgentActivity('capturing_screenshot');
    final bytes = await _webViewService.captureScreenshot(
      sessionId: conversationId,
      tabId: targetTabId,
    );
    final snapshot = await _captureSnapshot(targetTabId);
    final output = {
      'screenshotCaptured':
          bytes != null && bytes.length <= _maxToolScreenshotBytes,
      'url': snapshot['url'],
      'title': snapshot['title'],
      'snapshot': snapshot,
      if (bytes != null && bytes.length > _maxToolScreenshotBytes)
        'reason': 'Screenshot exceeds the 5 MiB attachment limit.',
    };
    if (bytes == null || bytes.length > _maxToolScreenshotBytes) {
      if (ref.mounted) _recordAgentActivity('screenshot_fallback');

      return output;
    }
    if (ref.mounted) _recordAgentActivity('screenshot_captured');

    return AgentToolExecutionOutput(
      output: output,
      media: [
        AgentToolResultMedia(
          bytes: bytes,
          mimeType: 'image/png',
          fileName: 'browser-viewport.png',
        ),
      ],
    );
  }

  Future<Map<Object?, Object?>> _captureSnapshot(String tabId) async {
    final snapshotId = const Uuid().v4();
    final result = await executeJavaScript(
      _snapshotScript(snapshotId),
      tabId: tabId,
    );
    if (result is! Map<Object?, Object?>) {
      throw StateError('Browser page returned an invalid snapshot.');
    }
    if (result['error'] case final String error) {
      throw FormatException(error);
    }
    _snapshotIdsByTab[tabId] = snapshotId;

    return result;
  }

  List<Map<Object?, Object?>> _snapshotElements(
    Map<Object?, Object?> snapshot,
  ) {
    final elements = snapshot['elements'];
    if (elements is! List<Object?>) return const [];

    return elements.whereType<Map<Object?, Object?>>().toList(growable: false);
  }

  bool _matchesSnapshotElement(
    Map<Object?, Object?> element, {
    String? role,
    String? name,
    String? text,
  }) {
    final elementRole = element['role'];
    final elementName = element['name'];
    final elementText = element['text'];

    return (role == null ||
            elementRole is String &&
                elementRole.toLowerCase() == role.toLowerCase()) &&
        (name == null ||
            elementName is String &&
                elementName.toLowerCase().contains(name.toLowerCase())) &&
        (text == null ||
            elementText is String &&
                elementText.toLowerCase().contains(text.toLowerCase()));
  }

  Future<Object?> _runBrowserElementAction(
    Map<String, dynamic> arguments, {
    required String action,
  }) async {
    final tabId = _optionalTabId(arguments);
    if (tabId != null) await selectTab(tabId);
    final targetTabId = _targetTabId(tabId);
    final target = _browserElementTarget(arguments, targetTabId);
    final text = arguments['text'];
    if (action == 'fill' && (text is! String || text.length > 16000)) {
      throw const FormatException(
        'Browser fill text must be a string no longer than 16000 characters.',
      );
    }
    final optionValue = arguments['value'];
    if (action == 'select_option' &&
        (optionValue is! String || optionValue.length > 256)) {
      throw const FormatException(
        'Browser option value must be a string no longer than 256 characters.',
      );
    }
    final checked = arguments['checked'];
    if (action == 'set_checked' && checked is! bool) {
      throw const FormatException('Browser checked state must be a boolean.');
    }
    final result = await executeJavaScript(
      _browserElementActionScript(
        target,
        action: action,
        text: text is String ? text : null,
        optionValue: optionValue is String ? optionValue : null,
        checked: checked is bool ? checked : null,
      ),
      tabId: targetTabId,
    );
    final error = result is Map<Object?, Object?> ? result['error'] : null;
    if (error is String) {
      throw FormatException(error);
    }

    return result;
  }

  ({String? selector, String? ref, String? snapshotId}) _browserElementTarget(
    Map<String, dynamic> arguments,
    String tabId,
  ) {
    final selector = _optionalString(arguments, 'selector');
    final ref = _optionalString(arguments, 'ref');
    if ((selector == null) == (ref == null)) {
      throw const FormatException(
        'Browser element action requires exactly one selector or ref.',
      );
    }
    if (selector != null && selector.length > 256) {
      throw const FormatException('Browser selector exceeds 256 characters.');
    }
    if (ref != null) {
      final snapshotId = _snapshotIdsByTab[tabId];
      if (snapshotId == null || !ref.startsWith('$snapshotId:')) {
        throw const FormatException(
          'Browser element ref is stale. Take a fresh snapshot.',
        );
      }

      return (selector: null, ref: ref, snapshotId: snapshotId);
    }

    return (selector: selector, ref: null, snapshotId: null);
  }

  String _browserElementActionScript(
    ({String? selector, String? ref, String? snapshotId}) target, {
    required String action,
    String? text,
    String? optionValue,
    bool? checked,
  }) {
    final ref = target.ref;
    final elementLookup = ref != null
        ? '''
  const snapshot = window.__auraBrowserSnapshotRefs;
  const snapshotId = ${jsonEncode(target.snapshotId)};
  const ref = ${jsonEncode(ref)};
  if (!snapshot || snapshot.id !== snapshotId || !snapshot.elements.has(ref)) {
    return { error: 'Browser element ref is stale. Take a fresh snapshot.' };
  }
  element = snapshot.elements.get(ref);
  if (!element || !element.isConnected) {
    return { error: 'Browser element ref is stale. Take a fresh snapshot.' };
  }
  '''
        : '''
  const selector = ${jsonEncode(target.selector)};
  let matches;
  try {
    matches = document.querySelectorAll(selector);
  } catch (_) {
    return { error: 'Invalid CSS selector.' };
  }
  if (matches.length !== 1) {
    return { error: matches.length === 0
      ? 'No element matches the selector.'
      : 'Selector must match exactly one element.' };
  }
  element = matches[0];
  ''';
    final actionScript = switch (action) {
      'fill' =>
        '''
  if (element instanceof HTMLInputElement) {
    if (element.type === 'password') {
      return { error: 'Password fields cannot be filled.' };
    }
    if (['button', 'checkbox', 'file', 'hidden', 'image', 'radio', 'reset', 'submit'].includes(element.type)) {
      return { error: 'Element is not a text field.' };
    }
    if (element.readOnly) return { error: 'Element is read-only.' };
    Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set.call(element, ${jsonEncode(text)});
  } else if (element instanceof HTMLTextAreaElement) {
    if (element.readOnly) return { error: 'Element is read-only.' };
    Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value').set.call(element, ${jsonEncode(text)});
  } else if (element.isContentEditable) {
    element.textContent = ${jsonEncode(text)};
  } else {
    return { error: 'Element is not a supported text field.' };
  }
  element.dispatchEvent(new InputEvent('input', { bubbles: true, inputType: 'insertText', data: ${jsonEncode(text)} }));
  element.dispatchEvent(new Event('change', { bubbles: true }));
  return { filled: true };
  ''',
      'select_option' =>
        '''
  if (!(element instanceof HTMLSelectElement) || element.multiple) {
    return { error: 'Element is not a supported single select.' };
  }
  const optionValue = ${jsonEncode(optionValue)};
  const option = Array.from(element.options).find(item => item.value === optionValue);
  if (!option || option.disabled) return { error: 'Select option is unavailable.' };
  Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, 'value').set.call(element, optionValue);
  element.dispatchEvent(new Event('input', { bubbles: true }));
  element.dispatchEvent(new Event('change', { bubbles: true }));
  return { selected: true };
  ''',
      'set_checked' =>
        '''
  if (!(element instanceof HTMLInputElement) ||
      !['checkbox', 'radio'].includes(element.type)) {
    return { error: 'Element is not a checkbox or radio input.' };
  }
  const checked = ${jsonEncode(checked)};
  if (element.type === 'radio' && !checked) {
    return { error: 'Radio inputs cannot be unchecked.' };
  }
  Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'checked').set.call(element, checked);
  element.dispatchEvent(new Event('input', { bubbles: true }));
  element.dispatchEvent(new Event('change', { bubbles: true }));
  return { checked };
  ''',
      _ =>
        '''
  element.scrollIntoView({ block: 'center', inline: 'center' });
  element.click();
  return { clicked: true };
  ''',
    };

    return '''
(() => {
  let element;
  $elementLookup
  if (!(element instanceof HTMLElement)) {
    return { error: 'Selector must match an HTML element.' };
  }
  const style = window.getComputedStyle(element);
  const bounds = element.getBoundingClientRect();
  if (style.display === 'none' || style.visibility === 'hidden' ||
      style.opacity === '0' || bounds.width === 0 || bounds.height === 0) {
    return { error: 'Element is not visible.' };
  }
  if (element.matches(':disabled') ||
      element.getAttribute('aria-disabled') === 'true') {
    return { error: 'Element is disabled.' };
  }
  $actionScript
})()
''';
  }

  String _snapshotScript(String snapshotId) =>
      '''
(() => {
  const id = ${jsonEncode(snapshotId)};
  const refs = new Map();
  window.__auraBrowserSnapshotRefs = { id, elements: refs };
  const visible = element => {
    const style = window.getComputedStyle(element);
    const bounds = element.getBoundingClientRect();
    return style.display !== 'none' && style.visibility !== 'hidden' &&
      Number(style.opacity) !== 0 && bounds.width > 0 && bounds.height > 0 &&
      element.getAttribute('aria-hidden') !== 'true';
  };
  const candidates = Array.from(document.querySelectorAll(
    'a[href],button,input:not([type="hidden"]):not([type="password"]),' +
    'textarea,select,[role],[contenteditable="true"],' +
    '[tabindex]:not([tabindex="-1"]),h1,h2,h3,h4,h5,h6,summary'
  ));
  const elements = [];
  let visibleCount = 0;
  for (const element of candidates) {
    if (!visible(element)) continue;
    visibleCount++;
    const labelledBy = element.getAttribute('aria-labelledby')
      ?.split(/\\s+/).map(labelId => document.getElementById(labelId)?.innerText)
      .filter(Boolean).join(' ');
    const label = element.labels
      ? Array.from(element.labels).map(item => item.innerText).join(' ')
      : '';
    const text = (element.innerText || '').replace(/\\s+/g, ' ').trim();
    const name = element.getAttribute('aria-label') || labelledBy || label ||
      element.getAttribute('alt') || element.getAttribute('title') || text;
    let role = element.getAttribute('role');
    if (!role) {
      if (element instanceof HTMLButtonElement) role = 'button';
      else if (element instanceof HTMLAnchorElement) role = 'link';
      else if (element instanceof HTMLTextAreaElement || element.isContentEditable) role = 'textbox';
      else if (element instanceof HTMLSelectElement) role = element.multiple ? 'listbox' : 'combobox';
      else if (element instanceof HTMLInputElement) {
        role = ({checkbox: 'checkbox', radio: 'radio', button: 'button',
          submit: 'button', reset: 'button', search: 'searchbox'})[element.type] || 'textbox';
      } else if (element.tagName[0] === 'H' && '123456'.includes(element.tagName[1])) role = 'heading';
      else if (element instanceof HTMLElement && element.isContentEditable) role = 'textbox';
      else if (element instanceof HTMLElement && element.tagName === 'SUMMARY') role = 'button';
      else if (element instanceof HTMLAnchorElement) role = 'link';
      else role = 'generic';
    }
    const ref = id + ':' + (elements.length + 1);
    refs.set(ref, element);
    elements.push({
      ref,
      role: String(role).slice(0, 40),
      name: String(name || '').replace(/\\s+/g, ' ').trim().slice(0, 120),
      text: text.slice(0, 120),
      tag: element.tagName.toLowerCase(),
      type: element instanceof HTMLInputElement ? element.type : undefined
    });
    if (elements.length >= 30) break;
  }
  return {
    url: location.href,
    title: document.title.slice(0, 512),
    count: visibleCount,
    truncated: visibleCount > elements.length,
    elements
  };
})()
''';

  String _selectorVisibilityScript(String selector) =>
      '''
(() => {
  try {
    const nodes = document.querySelectorAll(${jsonEncode(selector)});
    const found = Array.from(nodes).some(element => {
      const style = window.getComputedStyle(element);
      const bounds = element.getBoundingClientRect();
      return style.display !== 'none' && style.visibility !== 'hidden' &&
        Number(style.opacity) !== 0 && bounds.width > 0 && bounds.height > 0;
    });
    return { found };
  } catch (_) {
    return { error: 'Invalid CSS selector.' };
  }
})()
''';

  Future<Map<Object?, Object?>> _pageMarkup(String? tabId) async {
    const source = '''
(() => {
  const body = document.body?.cloneNode(true);
  if (!body) return { url: location.href, title: document.title, html: '' };
  body.querySelectorAll(
    'script,style,noscript,iframe,object,embed,svg,canvas,' +
      'input[type="hidden"],input[type="password"]'
  ).forEach(el => el.remove());
  body.querySelectorAll('input,textarea,select').forEach(el => {
    el.removeAttribute('value');
    if ('value' in el) el.value = '';
    if (el.tagName === 'TEXTAREA') el.textContent = '';
    if (el.tagName === 'SELECT') el.selectedIndex = -1;
    el.querySelectorAll('option').forEach(option => {
      option.removeAttribute('value');
      option.removeAttribute('selected');
    });
  });
  return {
    url: location.href,
    title: document.title,
    html: body.outerHTML.slice(0, 12000)
  };
})()
''';
    final result = await executeJavaScript(source, tabId: tabId);
    if (result is! Map<Object?, Object?>) {
      throw StateError('Browser page returned invalid content.');
    }

    return result;
  }

  String _contentFormat(Object? value) {
    if (value == null) return 'text';
    if (value is! String ||
        !const {'text', 'markdown', 'html', 'toon'}.contains(value)) {
      throw const FormatException(
        'Browser format must be text, markdown, html, or toon.',
      );
    }

    return value;
  }

  String _formatBrowserContent(
    String html,
    String format, {
    int maxLength = 12000,
  }) {
    if (format == 'html') return html.truncateCharacters(maxLength);
    final transformed = const UrlContentTransformer().transform(
      .new(
        statusCode: 200,
        body: html,
        headers: const {
          'content-type': ['text/html'],
        },
        elapsed: .zero,
      ),
      requestedFormat: format == 'markdown' ? .markdown : .text,
    );

    return transformed.body.truncateCharacters(maxLength);
  }

  void _recordAgentActivity(String activity) {
    state = AsyncData(_current.copyWith(agentActivity: activity));
  }

  void _recordBrowserSkillAction() {
    state = AsyncData(
      _current.copyWith(agentActionRevision: _current.agentActionRevision + 1),
    );
  }

  void _retainSession() => _sessionKeepAliveLink ??= ref.keepAlive();

  void _releaseSession() {
    final keepAliveLink = _sessionKeepAliveLink;
    _sessionKeepAliveLink = null;
    keepAliveLink?.close();
  }

  Future<void> _save(BrowserSessionState next) async {
    final repository = await ref.read(browserSessionRepositoryProvider.future);
    if (!ref.mounted) return;
    state = AsyncData(next);
    await repository.save(conversationId, next);
  }

  Future<void> _refreshActiveTab() async {
    final tabId = _current.activeTab?.id;
    if (tabId == null) return;
    if (!_webViewService.hasController(
      sessionId: conversationId,
      tabId: tabId,
    )) {
      state = AsyncData(
        _current.copyWith(
          isLoading: false,
          hasError: false,
          canGoBack: false,
          canGoForward: false,
        ),
      );

      return;
    }

    final page = await _webViewService.pageState(
      sessionId: conversationId,
      tabId: tabId,
    );
    if (!ref.mounted) return;
    await updateTab(
      tabId,
      url: page.url,
      title: page.title,
      isLoading: false,
      hasError: false,
      canGoBack: page.canGoBack,
      canGoForward: page.canGoForward,
    );
  }

  String _targetTabId(String? tabId) {
    final current = _current;
    if (tabId == null && current.activeTab == null) {
      throw StateError('Open a browser tab first.');
    }
    final targetId = tabId ?? current.activeTabId;
    if (!current.tabs.any((tab) => tab.id == targetId)) {
      throw ArgumentError.value(targetId, 'tabId', 'Unknown browser tab.');
    }

    return targetId;
  }
}

String _requiredString(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();

  throw FormatException('Browser tool requires a non-empty $key.');
}

Object? _boundedBrowserResult(Object? result) {
  if (result is String && result.length > 16000) {
    return result.truncateCharacters(16000);
  }
  if (result is Map || result is List) {
    final encoded = jsonEncode(result);
    if (encoded.length > 16000) {
      return {'truncated': true, 'preview': encoded.truncateCharacters(15000)};
    }
  }

  return result;
}

String? _optionalTabId(Map<String, dynamic> arguments) =>
    _optionalString(arguments, 'tabId');

String? _optionalString(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value == null) return null;
  if (value is String && value.trim().isNotEmpty) return value.trim();

  throw FormatException('Browser tool $key must be a non-empty string.');
}

int _boundedInteger(
  Object? value, {
  required String name,
  required int defaultValue,
  required int min,
  required int max,
}) {
  if (value == null) return defaultValue;
  if (value is int && value >= min && value <= max) return value;

  throw FormatException('Browser tool $name must be between $min and $max.');
}

String _normalizeUrl(String input) {
  final value = input.trim();
  if (value.isEmpty) return 'about:blank';
  final uri = Uri.tryParse(value);
  if (uri?.hasScheme ?? false) return value;
  if (value.contains(' ') || !value.contains('.') && !value.contains(':')) {
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(value)}';
  }

  return 'https://$value';
}

String _normalizeAgentUrl(String input) {
  final normalized = _normalizeUrl(input);
  final uri = Uri.tryParse(normalized);
  final isBlank = normalized == 'about:blank';
  final isWebUrl =
      uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
  if (!isBlank && !isWebUrl) {
    throw const FormatException(
      'Browser tools support HTTP, HTTPS, and about:blank URLs.',
    );
  }

  return normalized;
}
