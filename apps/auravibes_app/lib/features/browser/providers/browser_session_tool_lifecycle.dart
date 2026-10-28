part of 'browser_session_notifier.dart';

typedef _BrowserFindCriteria = ({String? role, String? name, String? text});
typedef _BrowserWaitCriteria = ({
  String? selector,
  _BrowserFindCriteria elements,
  int timeoutMs,
});
typedef _BrowserHistoryRequest = ({String tabId, bool backwards});
typedef _BrowserQueryRequest = ({
  String? tabId,
  String selector,
  int limit,
  String format,
});

enum _BrowserSkillToolGroup { tabs, page, element }

const Map<String, _BrowserSkillToolGroup> _browserSkillToolGroups = {
  'browser_list_tabs': _BrowserSkillToolGroup.tabs,
  'browser_open_tab': _BrowserSkillToolGroup.tabs,
  'browser_close_tab': _BrowserSkillToolGroup.tabs,
  'browser_select_tab': _BrowserSkillToolGroup.tabs,
  'browser_navigate': _BrowserSkillToolGroup.tabs,
  'browser_go_back': _BrowserSkillToolGroup.tabs,
  'browser_go_forward': _BrowserSkillToolGroup.tabs,
  'browser_reload': _BrowserSkillToolGroup.tabs,
  'browser_execute_javascript': _BrowserSkillToolGroup.tabs,
  'browser_read_page': _BrowserSkillToolGroup.tabs,
  'browser_query_page': _BrowserSkillToolGroup.page,
  'browser_snapshot': _BrowserSkillToolGroup.page,
  'browser_find': _BrowserSkillToolGroup.page,
  'browser_wait_for': _BrowserSkillToolGroup.page,
  'browser_click': _BrowserSkillToolGroup.element,
  'browser_fill': _BrowserSkillToolGroup.element,
  'browser_select_option': _BrowserSkillToolGroup.element,
  'browser_set_checked': _BrowserSkillToolGroup.element,
  'browser_scroll': _BrowserSkillToolGroup.element,
  'browser_capture_screenshot': _BrowserSkillToolGroup.element,
};

const Set<String> _browserToolsAllowedWhileSuspended = {
  'browser_list_tabs',
  'browser_close_tab',
};

const String _browserQueryScriptPrefix = '''
(() => {
  try {
    const selector = ''';
const String _browserQueryScriptMiddle = '''
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
        html: clone.outerHTML.slice(0, ''';
const String _browserQueryScriptLimit = '''
);
      };
      const matches = Array.from(nodes).slice(0, ''';
const String _browserQueryScriptSuffix = '''
);
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

String _browserQueryScript(String selector, int limit) =>
    '$_browserQueryScriptPrefix${jsonEncode(selector)}'
    '$_browserQueryScriptMiddle$_maxBrowserQueryMarkupCharacters'
    '$_browserQueryScriptLimit$limit$_browserQueryScriptSuffix';

int _browserQueryLimit(Object? value) {
  if (value == null) return _minBrowserQueryMatches;
  if (value is int &&
      value >= _minBrowserQueryMatches &&
      value <= _maxBrowserQueryMatches) {
    return value;
  }
  throw const FormatException('Browser query limit must be between 1 and 5.');
}

mixin BrowserSessionToolLifecycle on _$BrowserSessionNotifier {
  final Map<String, String> _snapshotIdsByTab = <String, String>{};
  KeepAliveLink? _sessionKeepAliveLink;

  BrowserWebViewService get _webViewService =>
      ref.read(browserWebViewServiceProvider);
  bool get _isBrowserSessionMounted => ref.mounted;
  BrowserSessionState get _current => state.requireValue;

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
    final repositoryFuture = ref.read(browserSessionRepositoryProvider.future);
    if (!ref.mounted) return;
    state = AsyncData(next);
    final repository = await repositoryFuture;
    if (!ref.mounted) return;
    await repository.save(conversationId, next);
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

mixin BrowserSessionTabRefresh on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _refreshNotifier => this as BrowserSessionNotifier;

  Future<void> _finishSelectingTab() async {
    if (!ref.mounted) return;
    _refreshNotifier._recordAgentActivity('select_tab');
    await _refreshActiveTab();
  }

  Future<void> _refreshActiveTab() async {
    final notifier = _refreshNotifier;
    final tabId = notifier._current.activeTab?.id;
    if (tabId == null) return;
    final page = await notifier._webViewService.host.pageStateIfAttached(
      sessionId: conversationId,
      tabId: tabId,
    );
    if (page == null) {
      _resetActiveTabState();

      return;
    }

    await _refreshTabPage(tabId, page);
  }

  Future<void> _refreshTabPage(String tabId, BrowserPageState page) async {
    final notifier = _refreshNotifier;
    if (!ref.mounted) return;
    await notifier.updateTab(tabId, (
      url: page.url,
      title: page.title,
      isLoading: false,
      hasError: false,
      canGoBack: page.canGoBack,
      canGoForward: page.canGoForward,
    ));
  }

  void _resetActiveTabState() => state = AsyncData(
    _refreshNotifier._current.copyWith(
      isLoading: false,
      hasError: false,
      canGoBack: false,
      canGoForward: false,
    ),
  );
}

mixin BrowserSessionTabOperations on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _operationsNotifier =>
      this as BrowserSessionNotifier;

  Future<void> _removeRuntimeTab(String tabId, bool isSuspended) async {
    final notifier = _operationsNotifier;
    final _ = notifier._snapshotIdsByTab.remove(tabId);
    if (isSuspended) return;
    await notifier._webViewService.host.removeTab(
      sessionId: conversationId,
      tabId: tabId,
    );
  }

  Future<void> _removeRuntimeTabs(BrowserSessionState current) async {
    for (final tab in current.tabs) {
      await _removeRuntimeTab(tab.id, current.isSuspended);
    }
  }

  Future<void> _finishClosingTab(
    BrowserSessionState current,
    List<BrowserTab> tabs,
    String tabId,
  ) async {
    final notifier = _operationsNotifier;
    if (tabs.isEmpty) notifier._releaseSession();
    if (!ref.mounted) return;
    if (current.activeTabId == tabId && tabs.isNotEmpty) {
      await notifier._refreshActiveTab();
    }
    if (!ref.mounted) return;
    notifier._recordAgentActivity('close_tab');
  }

  Future<void> _markNavigationFailed(String tabId) =>
      _operationsNotifier.updateTab(tabId, (
        url: null,
        title: null,
        isLoading: false,
        hasError: true,
        canGoBack: null,
        canGoForward: null,
      ));

  Future<bool> _navigateHistory(
    String? tabId, {
    required bool backwards,
  }) async {
    final notifier = _operationsNotifier;
    if (tabId != null) await notifier.selectTab(tabId);

    return await _runBrowserHistory(notifier, (
      tabId: notifier._targetTabId(tabId),
      backwards: backwards,
    ));
  }
}

Future<bool> _runBrowserHistory(
  BrowserSessionNotifier notifier,
  _BrowserHistoryRequest request,
) async {
  _startBrowserHistory(notifier, request);
  final service = notifier._webViewService.controller;
  final canNavigate = await _canNavigateBrowserHistory(
    notifier,
    service,
    request,
  );
  if (!canNavigate) return false;
  await _performBrowserHistoryNavigation(
    service,
    notifier.conversationId,
    request,
  );
  if (!notifier._isBrowserSessionMounted) return false;
  _completeBrowserHistory(notifier, request);

  return true;
}

void _startBrowserHistory(
  BrowserSessionNotifier notifier,
  _BrowserHistoryRequest request,
) {
  notifier._recordAgentActivity(
    _historyActivity(backwards: request.backwards, inProgress: true),
  );
  final _ = notifier._snapshotIdsByTab.remove(request.tabId);
}

Future<bool> _canNavigateBrowserHistory(
  BrowserSessionNotifier notifier,
  BrowserWebViewControllerService service,
  _BrowserHistoryRequest request,
) async {
  final canNavigate = await _browserCanNavigateHistory(
    service,
    notifier.conversationId,
    request,
  );

  return notifier._isBrowserSessionMounted && canNavigate;
}

void _completeBrowserHistory(
  BrowserSessionNotifier notifier,
  _BrowserHistoryRequest request,
) {
  notifier._recordAgentActivity(
    _historyActivity(backwards: request.backwards, inProgress: false),
  );
}

String _historyActivity({required bool backwards, required bool inProgress}) =>
    switch ((backwards: backwards, inProgress: inProgress)) {
      (backwards: true, inProgress: true) => 'going_back',
      (backwards: true, inProgress: false) => 'went_back',
      (backwards: false, inProgress: true) => 'going_forward',
      (backwards: false, inProgress: false) => 'went_forward',
    };

Future<bool> _browserCanNavigateHistory(
  BrowserWebViewControllerService service,
  String conversationId,
  _BrowserHistoryRequest request,
) {
  final canNavigate = request.backwards
      ? service.canGoBack
      : service.canGoForward;

  return canNavigate(sessionId: conversationId, tabId: request.tabId);
}

Future<void> _performBrowserHistoryNavigation(
  BrowserWebViewControllerService service,
  String conversationId,
  _BrowserHistoryRequest request,
) {
  final navigate = request.backwards ? service.goBack : service.goForward;

  return navigate(sessionId: conversationId, tabId: request.tabId);
}

mixin BrowserSessionToolDispatch on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _toolNotifier => this as BrowserSessionNotifier;

  List<Map<String, Object?>> _listToolTabs() {
    _toolNotifier._recordAgentActivity('listing_tabs');

    return _toolNotifier._current.tabs
        .map((tab) => {'id': tab.id, 'url': tab.url, 'title': tab.title})
        .toList(growable: false);
  }

  Future<Object?> _openToolTab(Map<String, dynamic> arguments) {
    final normalizedUrl = _optionalBrowserToolUrl(arguments['url']);

    return _openToolTabAt(normalizedUrl);
  }

  String? _optionalBrowserToolUrl(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Browser tab URL must be a string.');
    }
    if (value.trim().isEmpty) return null;

    return _normalizeAgentUrl(value);
  }

  Future<Object?> _openToolTabAt(String? normalizedUrl) async {
    await _toolNotifier.openTab();
    if (!ref.mounted) throw StateError('Browser session closed.');
    final tab = _toolNotifier._current.activeTab;
    if (tab == null) throw StateError('Browser tab did not open.');
    if (normalizedUrl != null) await _toolNotifier.navigate(normalizedUrl);
    if (!ref.mounted) throw StateError('Browser session closed.');

    return {
      'id': tab.id,
      'url': _toolNotifier._current.activeTab?.url ?? tab.url,
    };
  }

  Future<Object?> _closeToolTab(Map<String, dynamic> arguments) async {
    final tabId = _requiredString(arguments, 'tabId');
    await _toolNotifier.closeTab(tabId);

    return {'closed': true, 'tabId': tabId};
  }

  Future<Object?> _selectToolTab(Map<String, dynamic> arguments) async {
    final tabId = _requiredString(arguments, 'tabId');
    await _toolNotifier.selectTab(tabId);

    return {'activeTabId': tabId};
  }

  Future<Object?> _executeToolJavaScript(Map<String, dynamic> arguments) async {
    final tabId = arguments['tabId'] as String?;
    if (tabId != null) await _toolNotifier.selectTab(tabId);

    return _boundedBrowserResult(
      await _toolNotifier.executeJavaScript(
        _requiredString(arguments, 'source'),
        tabId: tabId,
      ),
    );
  }
}

mixin BrowserSessionToolPageActions on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _pageActionNotifier =>
      this as BrowserSessionNotifier;

  Future<Object?> _readToolPage(Map<String, dynamic> arguments) async {
    final notifier = _pageActionNotifier;
    final tabId = arguments['tabId'] as String?;
    if (tabId != null) await notifier.selectTab(tabId);
    final page = await notifier._pageMarkup(tabId);
    final format = notifier._contentFormat(arguments['format']);

    return _encodeBrowserReadResult(
      notifier._formatReadPage(page, format),
      format,
    );
  }

  Future<Object?> _historyTool(
    Map<String, dynamic> arguments,
    Future<bool> Function({String? tabId}) action,
  ) async {
    final tabId = arguments['tabId'] as String?;
    final changed = await action(tabId: tabId);

    return {
      'changed': changed,
      'tabId': tabId ?? _pageActionNotifier._current.activeTabId,
    };
  }

  Future<Object?> _reloadTool(Map<String, dynamic> arguments) async {
    final notifier = _pageActionNotifier;
    final tabId = arguments['tabId'] as String?;
    await notifier.reload(tabId: tabId);

    return {'reloaded': true, 'tabId': tabId ?? notifier._current.activeTabId};
  }
}

Object _encodeBrowserReadResult(Map<String, Object?> result, String format) =>
    format == 'toon' ? toonEncode(result) : result;

mixin BrowserSessionToolTabNavigation on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _tabNavigationNotifier =>
      this as BrowserSessionNotifier;

  Future<Object?> _navigateToolTab(Map<String, dynamic> arguments) async {
    final url = _requiredString(arguments, 'url');
    final normalizedUrl = _normalizeAgentUrl(url);
    final tabId = arguments['tabId'] as String?;
    await _selectOptionalToolTab(tabId);
    await _tabNavigationNotifier.navigate(normalizedUrl, tabId: tabId);

    return _toolTabUrl(tabId);
  }

  Future<void> _selectOptionalToolTab(String? tabId) async {
    if (tabId != null) await _tabNavigationNotifier.selectTab(tabId);
  }

  Map<String, String> _toolTabUrl(String? tabId) => {
    'url': _tabNavigationNotifier._current.tabs
        .firstWhere(
          (tab) =>
              tab.id == (tabId ?? _tabNavigationNotifier._current.activeTabId),
        )
        .url,
  };
}

mixin BrowserSessionPageContent on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _contentNotifier => this as BrowserSessionNotifier;

  Map<String, Object?> _formatReadPage(
    Map<Object?, Object?> page,
    String format,
  ) {
    final content = _readPageContent(page, format);

    return {
      ..._pageIdentity(page),
      if (format != 'toon') 'format': format,
      'content': content,
    };
  }

  String _readPageContent(Map<Object?, Object?> page, String format) {
    final requestedFormat = format == 'toon' ? 'text' : format;
    final maxLength = format == 'toon'
        ? _maxBrowserToonContentCharacters
        : _maxBrowserReadContentCharacters;

    return _contentNotifier._formatBrowserContent(
      page['html'] as String? ?? '',
      requestedFormat,
      maxLength: maxLength,
    );
  }

  Map<String, Object?> _formatQueryPage(
    Map<Object?, Object?> page,
    String format,
  ) {
    final rawMatches = switch (page['matches']) {
      final List<Object?> matches => matches,
      _ => const <Object?>[],
    };

    return {
      ..._pageIdentity(page),
      'count': page['count'],
      'format': format,
      'matches': _formatQueryMatches(rawMatches, format),
    };
  }

  Map<String, String> _pageIdentity(Map<Object?, Object?> page) => {
    'url': (page['url'] as String? ?? '').truncateCharacters(
      _browserPageUrlCharacters,
    ),
    'title': (page['title'] as String? ?? '').truncateCharacters(
      _browserPageTitleCharacters,
    ),
  };

  List<String> _formatQueryMatches(List<Object?> rawMatches, String format) =>
      rawMatches
          .whereType<Map<Object?, Object?>>()
          .map((match) => _formatQueryMatch(match, format))
          .toList(growable: false);

  String _formatQueryMatch(Map<Object?, Object?> match, String format) =>
      _contentNotifier._formatBrowserContent(
        match['html'] as String? ?? '',
        format == 'toon' ? 'text' : format,
        maxLength: _maxBrowserQueryMarkupCharacters,
      );

  Future<Map<Object?, Object?>> _pageMarkup(String? tabId) async {
    const source =
        '''
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
    html: body.outerHTML.slice(0, $_maxBrowserPageMarkupCharacters)
  };
})()
''';
    final result = await _contentNotifier.executeJavaScript(
      source,
      tabId: tabId,
    );
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
    int maxLength = _maxBrowserPageMarkupCharacters,
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
}

mixin BrowserSessionPageInspection on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _pageNotifier => this as BrowserSessionNotifier;

  Future<Object?> _queryToolPage(Map<String, dynamic> arguments) =>
      _runBrowserQuery(
        _pageNotifier,
        _browserQueryRequest(_pageNotifier, arguments),
      );

  Future<Object?> _snapshotTool(Map<String, dynamic> arguments) async {
    final tabId = _optionalTabId(arguments);
    if (tabId != null) await _pageNotifier.selectTab(tabId);
    _pageNotifier._recordAgentActivity('snapshotting');
    final snapshot = await _captureSnapshot(_pageNotifier._targetTabId(tabId));
    if (!ref.mounted) return snapshot;
    _pageNotifier._recordAgentActivity('snapshot_ready');

    return _boundedBrowserResult(snapshot);
  }

  Future<Map<Object?, Object?>> _captureSnapshot(String tabId) async {
    final snapshotId = const Uuid().v4();
    final result = await _pageNotifier.executeJavaScript(
      _snapshotScript(snapshotId),
      tabId: tabId,
    );
    if (result is! Map<Object?, Object?>) {
      throw StateError('Browser page returned an invalid snapshot.');
    }
    if (result['error'] case final String error) {
      throw FormatException(error);
    }
    _pageNotifier._snapshotIdsByTab[tabId] = snapshotId;

    return result;
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
}

mixin BrowserSessionPageFindWait on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _findWaitNotifier =>
      this as BrowserSessionNotifier;

  Future<Object?> _findTool(Map<String, dynamic> arguments) async {
    final criteria = _browserFindCriteria(arguments);
    final limit = _browserFindLimit(arguments);
    final tabId = _optionalTabId(arguments);
    if (tabId != null) await _findWaitNotifier.selectTab(tabId);
    _findWaitNotifier._recordAgentActivity('finding');
    final result = await _findPage(_findWaitNotifier, tabId, criteria);

    return _findResult(_findWaitNotifier, result, limit);
  }

  Future<
    ({Map<Object?, Object?> snapshot, List<Map<Object?, Object?>> matches})
  >
  _findPage(
    BrowserSessionNotifier notifier,
    String? tabId,
    _BrowserFindCriteria criteria,
  ) async {
    final snapshot = await notifier._captureSnapshot(
      notifier._targetTabId(tabId),
    );
    final elements = notifier._snapshotElements(snapshot);
    final matches = elements
        .where(
          (element) =>
              notifier._matchesSnapshotElement(element, criteria: criteria),
        )
        .toList(growable: false);

    return (snapshot: snapshot, matches: matches);
  }

  Future<Object?> _waitTool(Map<String, dynamic> arguments) async {
    final criteria = _browserWaitCriteria(arguments);
    final tabId = _optionalTabId(arguments);
    if (tabId != null) await _findWaitNotifier.selectTab(tabId);
    _findWaitNotifier._recordAgentActivity('waiting');
    final snapshot = await _waitForSnapshot(
      _findWaitNotifier._targetTabId(tabId),
      criteria,
    );

    return _waitResult(snapshot, criteria);
  }

  Map<String, Object?> _waitResult(
    Map<Object?, Object?>? snapshot,
    _BrowserWaitCriteria criteria,
  ) {
    if (!ref.mounted) throw StateError('Browser session closed.');
    if (snapshot == null) {
      _findWaitNotifier._recordAgentActivity('wait_timed_out');

      return {'found': false, 'timeoutMs': criteria.timeoutMs};
    }
    _findWaitNotifier._recordAgentActivity('waited');

    final result = _boundedBrowserResult({'found': true, 'snapshot': snapshot});
    if (result is Map<String, Object?>) return result;

    throw StateError('Browser wait result is not a map.');
  }

  Future<Map<Object?, Object?>?> _waitForSnapshot(
    String targetTabId,
    _BrowserWaitCriteria criteria,
  ) async {
    final stopwatch = Stopwatch()..start();

    while (true) {
      final snapshot = await _browserWaitSnapshot(
        _findWaitNotifier,
        targetTabId,
        criteria,
      );
      if (snapshot != null) return snapshot;
      if (!await _waitForNextBrowserSnapshot(
        _findWaitNotifier,
        criteria,
        stopwatch.elapsedMilliseconds,
      )) {
        return null;
      }
    }
  }
}

_BrowserFindCriteria _browserFindCriteria(Map<String, dynamic> arguments) {
  final criteria = (
    role: _optionalString(arguments, 'role'),
    name: _optionalString(arguments, 'name'),
    text: _optionalString(arguments, 'text'),
  );
  if (criteria.role != null || criteria.name != null || criteria.text != null) {
    return criteria;
  }
  throw const FormatException('Browser find requires a role, name, or text.');
}

Future<Object?> _runBrowserPageTool(
  BrowserSessionNotifier notifier,
  String toolSlug,
  Map<String, dynamic> arguments,
) => switch (toolSlug) {
  'browser_query_page' => notifier._queryToolPage(arguments),
  'browser_snapshot' => notifier._snapshotTool(arguments),
  'browser_find' => notifier._findTool(arguments),
  'browser_wait_for' => notifier._waitTool(arguments),
  _ => throw FormatException('Unknown browser page tool: $toolSlug'),
};

_BrowserQueryRequest _browserQueryRequest(
  BrowserSessionNotifier notifier,
  Map<String, dynamic> arguments,
) => (
  tabId: _optionalTabId(arguments),
  selector: _requiredString(arguments, 'selector'),
  limit: _browserQueryLimit(arguments['limit']),
  format: notifier._contentFormat(arguments['format']),
);

Future<Object?> _runBrowserQuery(
  BrowserSessionNotifier notifier,
  _BrowserQueryRequest request,
) async {
  final tabId = request.tabId;
  if (tabId != null) await notifier.selectTab(tabId);
  final page = await notifier.executeJavaScript(
    _browserQueryScript(request.selector, request.limit),
    tabId: tabId,
  );

  return _formatBrowserQueryResult(notifier, page, request.format);
}

Object? _findResult(
  BrowserSessionNotifier notifier,
  ({Map<Object?, Object?> snapshot, List<Map<Object?, Object?>> matches})
  result,
  int limit,
) {
  if (!notifier._isBrowserSessionMounted) {
    return result.matches.take(limit).toList(growable: false);
  }
  notifier._recordAgentActivity('found');

  return _boundedBrowserFindResult(result.snapshot, result.matches, limit);
}

Future<bool> _waitForNextBrowserSnapshot(
  BrowserSessionNotifier notifier,
  _BrowserWaitCriteria criteria,
  int elapsedMilliseconds,
) async {
  if (!notifier._isBrowserSessionMounted) {
    throw StateError('Browser session closed.');
  }
  final remainingMs = _remainingWaitMilliseconds(
    criteria.timeoutMs,
    elapsedMilliseconds,
  );
  if (remainingMs == null) return false;
  await Future<void>.delayed(.new(milliseconds: remainingMs));

  return true;
}

_BrowserWaitCriteria _browserWaitCriteria(Map<String, dynamic> arguments) {
  final selector = _optionalString(arguments, 'selector');
  final elements = (
    role: _optionalString(arguments, 'role'),
    name: _optionalString(arguments, 'name'),
    text: _optionalString(arguments, 'text'),
  );
  _validateWaitPresence(selector, elements);
  _validateWaitSelector(selector);
  final timeoutMs = _browserWaitTimeout(arguments['timeoutMs']);

  return (selector: selector, elements: elements, timeoutMs: timeoutMs);
}

int _browserWaitTimeout(Object? value) => _boundedInteger(value, (
  name: 'timeoutMs',
  defaultValue: _defaultBrowserWaitMilliseconds,
  min: _minBrowserWaitMilliseconds,
  max: _maxBrowserWaitMilliseconds,
));

void _validateWaitSelector(String? selector) {
  if (selector == null || selector.length <= _maxBrowserSelectorCharacters) {
    return;
  }
  throw const FormatException('Browser wait selector exceeds 256 characters.');
}

void _validateWaitPresence(String? selector, _BrowserFindCriteria elements) {
  if (selector != null ||
      elements.role != null ||
      elements.name != null ||
      elements.text != null) {
    return;
  }
  throw const FormatException(
    'Browser wait requires a selector, role, name, or text.',
  );
}

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

Object? _boundedBrowserFindResult(
  Map<Object?, Object?> snapshot,
  List<Map<Object?, Object?>> matches,
  int limit,
) => _boundedBrowserResult({
  'url': snapshot['url'],
  'title': snapshot['title'],
  'count': matches.length,
  'matches': matches.take(limit).toList(growable: false),
});

int _browserFindLimit(Map<String, dynamic> arguments) =>
    _boundedInteger(arguments['limit'], (
      name: 'limit',
      defaultValue: _defaultBrowserFindLimit,
      min: _minBrowserWaitMilliseconds,
      max: _maxBrowserFindLimit,
    ));

int? _remainingWaitMilliseconds(int timeoutMs, int elapsedMs) {
  final remainingMs = timeoutMs - elapsedMs;
  if (remainingMs <= 0) return null;

  return remainingMs < _browserWaitPollMilliseconds
      ? remainingMs
      : _browserWaitPollMilliseconds;
}

Future<Map<Object?, Object?>?> _browserWaitSnapshot(
  BrowserSessionNotifier notifier,
  String tabId,
  _BrowserWaitCriteria criteria,
) {
  final selector = criteria.selector;
  if (selector != null) {
    return _browserWaitForSelector(notifier, tabId, selector);
  }

  return _browserWaitForElement(notifier, tabId, criteria.elements);
}

Future<Map<Object?, Object?>?> _browserWaitForSelector(
  BrowserSessionNotifier notifier,
  String tabId,
  String selector,
) async {
  final result = await notifier.executeJavaScript(
    _selectorVisibilityScript(selector),
    tabId: tabId,
  );
  if (result is Map<Object?, Object?>) {
    final error = result['error'];
    if (error is String) throw FormatException(error);
  }
  if (!_selectorWasFound(result)) return null;

  return await notifier._captureSnapshot(tabId);
}

bool _selectorWasFound(Object? result) =>
    result == true ||
    (result is Map<Object?, Object?> && result['found'] == true);

Future<Map<Object?, Object?>?> _browserWaitForElement(
  BrowserSessionNotifier notifier,
  String tabId,
  _BrowserFindCriteria criteria,
) async {
  final snapshot = await notifier._captureSnapshot(tabId);
  final found = notifier
      ._snapshotElements(snapshot)
      .any(
        (element) =>
            notifier._matchesSnapshotElement(element, criteria: criteria),
      );

  return found ? snapshot : null;
}

Object? _formatBrowserQueryResult(
  BrowserSessionNotifier notifier,
  Object? page,
  String format,
) {
  if (page is! Map<Object?, Object?>) return _boundedBrowserResult(page);
  if (page['error'] case final String error) throw FormatException(error);

  final result = notifier._formatQueryPage(page, format);

  return format == 'toon' ? toonEncode(result) : _boundedBrowserResult(result);
}

mixin BrowserSessionElementActions on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _elementNotifier => this as BrowserSessionNotifier;

  Future<Object?> _runElementTool(
    String toolSlug,
    Map<String, dynamic> arguments,
  ) => switch (toolSlug) {
    'browser_click' => _runBrowserElementAction(arguments, action: 'click'),
    'browser_fill' => _runBrowserElementAction(arguments, action: 'fill'),
    'browser_select_option' => _runBrowserElementAction(
      arguments,
      action: 'select_option',
    ),
    'browser_set_checked' => _runBrowserElementAction(
      arguments,
      action: 'set_checked',
    ),
    'browser_scroll' => _scrollTool(arguments),
    'browser_capture_screenshot' => _captureScreenshotTool(arguments),
    _ => throw FormatException('Unknown browser element tool: $toolSlug'),
  };

  Future<Object?> _scrollTool(Map<String, dynamic> arguments) async {
    final offset = _browserScrollOffset(arguments);
    final targetTabId = await _selectedElementTab(arguments);
    _elementNotifier._recordAgentActivity('scrolling');
    await _performBrowserScroll(_elementNotifier, targetTabId, offset);
    if (!ref.mounted) return {'scrolled': true};
    _elementNotifier._recordAgentActivity('scrolled');

    return _browserScrollResult(
      await _browserScrollPosition(_elementNotifier, targetTabId),
    );
  }

  Future<Object?> _captureScreenshotTool(Map<String, dynamic> arguments) async {
    final targetTabId = await _selectedElementTab(arguments);
    _elementNotifier._recordAgentActivity('capturing_screenshot');
    final capture = await _captureBrowserScreenshot(targetTabId);

    return _browserScreenshotResponse(_elementNotifier, capture);
  }

  _BrowserScrollOffset _browserScrollOffset(Map<String, dynamic> arguments) {
    final x = _boundedInteger(arguments['x'], (
      name: 'x',
      defaultValue: 0,
      min: _minBrowserScrollOffset,
      max: _maxBrowserScrollOffset,
    ));
    final y = _boundedInteger(arguments['y'], (
      name: 'y',
      defaultValue: 0,
      min: _minBrowserScrollOffset,
      max: _maxBrowserScrollOffset,
    ));
    if (x == 0 && y == 0) {
      throw const FormatException('Browser scroll requires non-zero x or y.');
    }

    return (x: x, y: y);
  }

  Future<String> _selectedElementTab(Map<String, dynamic> arguments) async {
    final tabId = _optionalTabId(arguments);
    if (tabId != null) await _elementNotifier.selectTab(tabId);

    return _elementNotifier._targetTabId(tabId);
  }

  Future<_BrowserScreenshotCapture> _captureBrowserScreenshot(
    String tabId,
  ) async {
    final bytes = await _elementNotifier._webViewService.controller
        .captureScreenshot(sessionId: conversationId, tabId: tabId);
    final snapshot = await _elementNotifier._captureSnapshot(tabId);

    return (bytes: bytes, snapshot: snapshot);
  }

  Future<Object?> _runBrowserElementAction(
    Map<String, dynamic> arguments, {
    required String action,
  }) async {
    final targetTabId = await _selectedElementTab(arguments);
    final request = _browserElementActionRequest(
      arguments,
      targetTabId,
      action,
    );
    final result = await _elementNotifier.executeJavaScript(
      _browserElementActionScript(request),
      tabId: targetTabId,
    );

    _throwBrowserElementActionError(result);

    return result;
  }

  _BrowserElementActionRequest _browserElementActionRequest(
    Map<String, dynamic> arguments,
    String tabId,
    String action,
  ) {
    final target = _browserElementTarget(_elementNotifier, arguments, tabId);

    return (
      target: target,
      action: action,
      text: _browserFillText(arguments, action),
      optionValue: _browserOptionValue(arguments, action),
      checked: _browserCheckedValue(arguments, action),
    );
  }

  String _browserElementActionScript(_BrowserElementActionRequest request) {
    final elementLookup = _browserElementLookup(request.target);
    final actionScript = _browserActionScript(request);

    return _wrapBrowserElementAction(elementLookup, actionScript);
  }
}

_BrowserElementTarget _browserElementTarget(
  BrowserSessionNotifier notifier,
  Map<String, dynamic> arguments,
  String tabId,
) {
  final selector = _optionalString(arguments, 'selector');
  final ref = _optionalString(arguments, 'ref');
  if (selector != null) return _selectorElementTarget(selector, ref);
  if (ref == null) _throwMissingBrowserElementTarget();

  final snapshotId = notifier._snapshotIdsByTab[tabId];
  if (snapshotId == null || !ref.startsWith('$snapshotId:')) {
    throw const FormatException(
      'Browser element ref is stale. Take a fresh snapshot.',
    );
  }

  return (selector: null, ref: ref, snapshotId: snapshotId);
}

_BrowserElementTarget _selectorElementTarget(String selector, String? ref) {
  if (ref != null) _throwInvalidBrowserElementTarget();
  if (selector.length > _maxBrowserSelectorCharacters) {
    throw const FormatException(
      'Browser selector exceeds $_maxBrowserSelectorCharacters characters.',
    );
  }

  return (selector: selector, ref: null, snapshotId: null);
}

Never _throwMissingBrowserElementTarget() => throw const FormatException(
  'Browser element action requires exactly one selector or ref.',
);

Never _throwInvalidBrowserElementTarget() => throw const FormatException(
  'Browser element action requires exactly one selector or ref.',
);

String _browserElementLookup(_BrowserElementTarget target) {
  if (target.ref case final ref?) return _snapshotElementLookup(target, ref);
  final selector = target.selector;
  if (selector == null) throw StateError('Browser element target is missing.');

  return _selectorElementLookup(selector);
}

String _snapshotElementLookup(_BrowserElementTarget target, String ref) =>
    '''
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
  ''';

String _selectorElementLookup(String selector) =>
    '''
  const selector = ${jsonEncode(selector)};
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

String _browserActionScript(_BrowserElementActionRequest request) =>
    switch (request.action) {
      'fill' => _browserFillScript(request.text),
      'select_option' => _browserSelectOptionScript(request.optionValue),
      'set_checked' => _browserSetCheckedScript(request.checked),
      _ => _browserClickScript(),
    };

String _browserFillScript(String? text) =>
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
  ''';

String _browserSelectOptionScript(String? value) =>
    '''
  if (!(element instanceof HTMLSelectElement) || element.multiple) {
    return { error: 'Element is not a supported single select.' };
  }
  const optionValue = ${jsonEncode(value)};
  const option = Array.from(element.options).find(item => item.value === optionValue);
  if (!option || option.disabled) return { error: 'Select option is unavailable.' };
  Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, 'value').set.call(element, optionValue);
  element.dispatchEvent(new Event('input', { bubbles: true }));
  element.dispatchEvent(new Event('change', { bubbles: true }));
  return { selected: true };
  ''';

String _browserSetCheckedScript(bool? checked) =>
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
  ''';

String _browserClickScript() => '''
  element.scrollIntoView({ block: 'center', inline: 'center' });
  element.click();
  return { clicked: true };
  ''';

String _wrapBrowserElementAction(String lookup, String action) =>
    '''
(() => {
  let element;
  $lookup
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
  $action
})()
''';

String? _browserFillText(Map<String, dynamic> arguments, String action) {
  if (action != 'fill') return null;
  final value = arguments['text'];
  if (value is String && value.length <= _maxBrowserFillCharacters) {
    return value;
  }
  throw const FormatException(
    'Browser fill text must be a string no longer than '
    '$_maxBrowserFillCharacters characters.',
  );
}

String? _browserOptionValue(Map<String, dynamic> arguments, String action) {
  if (action != 'select_option') return null;
  final value = arguments['value'];
  if (value is String && value.length <= _maxBrowserOptionCharacters) {
    return value;
  }
  throw const FormatException(
    'Browser option value must be a string no longer than '
    '$_maxBrowserOptionCharacters characters.',
  );
}

bool? _browserCheckedValue(Map<String, dynamic> arguments, String action) {
  if (action != 'set_checked') return null;
  final value = arguments['checked'];
  if (value is bool) return value;

  throw const FormatException('Browser checked state must be a boolean.');
}

void _throwBrowserElementActionError(Object? result) {
  if (result is! Map<Object?, Object?>) return;
  final error = result['error'];
  if (error is String) throw FormatException(error);
}

Object _browserScrollResult(Object? result) => result is Map<Object?, Object?>
    ? {
        'scrolled': true,
        if (result['x'] is num) 'x': result['x'],
        if (result['y'] is num) 'y': result['y'],
      }
    : {'scrolled': true};

Future<void> _performBrowserScroll(
  BrowserSessionNotifier notifier,
  String tabId,
  _BrowserScrollOffset offset,
) => notifier._webViewService.controller.scrollBy(
  sessionId: notifier.conversationId,
  tabId: tabId,
  x: offset.x,
  y: offset.y,
);

Future<Object?> _browserScrollPosition(
  BrowserSessionNotifier notifier,
  String tabId,
) => notifier.executeJavaScript(
  '({x: window.scrollX, y: window.scrollY})',
  tabId: tabId,
);

Object _browserScreenshotResponse(
  BrowserSessionNotifier notifier,
  _BrowserScreenshotCapture capture,
) {
  final output = _browserScreenshotOutput(capture);
  final bytes = capture.bytes;
  if (bytes == null || bytes.length > _maxToolScreenshotBytes) {
    if (notifier._isBrowserSessionMounted) {
      notifier._recordAgentActivity('screenshot_fallback');
    }

    return output;
  }
  if (notifier._isBrowserSessionMounted) {
    notifier._recordAgentActivity('screenshot_captured');
  }

  return AgentToolExecutionOutput(
    output: output,
    media: [_browserScreenshotMedia(bytes)],
  );
}

Map<String, Object?> _browserScreenshotOutput(
  _BrowserScreenshotCapture capture,
) {
  final snapshot = capture.snapshot;

  return {
    'screenshotCaptured': _screenshotHasAttachment(capture.bytes),
    'url': snapshot['url'],
    'title': snapshot['title'],
    'snapshot': snapshot,
    if (_screenshotExceedsLimit(capture.bytes))
      'reason': 'Screenshot exceeds the 5 MiB attachment limit.',
  };
}

bool _screenshotHasAttachment(Uint8List? bytes) =>
    bytes != null && bytes.length <= _maxToolScreenshotBytes;

bool _screenshotExceedsLimit(Uint8List? bytes) =>
    bytes != null && bytes.length > _maxToolScreenshotBytes;

AgentToolResultMedia _browserScreenshotMedia(Uint8List bytes) =>
    AgentToolResultMedia(
      bytes: bytes,
      mimeType: 'image/png',
      fileName: 'browser-viewport.png',
    );

mixin BrowserSessionToolControls on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _controlNotifier => this as BrowserSessionNotifier;

  Future<void> suspend() async {
    final current = _controlNotifier._current;
    if (current.tabs.isEmpty || current.isSuspended) return;

    await _controlNotifier._removeRuntimeTabs(current);

    await _controlNotifier._save(
      current.copyWith(
        isSuspended: true,
        isLoading: false,
        hasError: false,
        canGoBack: false,
        canGoForward: false,
      ),
    );
    _controlNotifier._releaseSession();
  }

  Future<void> resume() async {
    final current = _controlNotifier._current;
    if (current.tabs.isEmpty || !current.isSuspended) return;

    _controlNotifier._retainSession();
    await _controlNotifier._save(current.copyWith(isSuspended: false));
  }
}

mixin BrowserSessionTabStateUpdates on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _updateNotifier => this as BrowserSessionNotifier;

  Future<void> saveWorkspaceTabs({
    required List<WorkspaceContentTab> tabs,
    required String? selectedTabId,
  }) async {
    final current = _updateNotifier._current;
    await _updateNotifier._save(
      current.copyWith(
        workspaceTabs: tabs,
        selectedWorkspaceTabId: selectedTabId,
        clearSelectedWorkspaceTab: selectedTabId == null,
      ),
    );
  }

  Future<void> updateTab(String tabId, BrowserTabUpdate update) async {
    if (update.isLoading == true) {
      final _ = _updateNotifier._snapshotIdsByTab.remove(tabId);
    }
    final current = _updateNotifier._current;
    final next = _sessionAfterTabUpdate(current, tabId, update);
    await _updateNotifier._save(next);
  }

  BrowserSessionState _sessionAfterTabUpdate(
    BrowserSessionState current,
    String tabId,
    BrowserTabUpdate update,
  ) => _copyBrowserTabUpdate(
    current,
    _updatedBrowserTabs(current.tabs, tabId, update),
    _browserTabNavigationUpdate(current.activeTabId == tabId, update),
  );
}

List<BrowserTab> _updatedBrowserTabs(
  List<BrowserTab> tabs,
  String tabId,
  BrowserTabUpdate update,
) => tabs
    .map(
      (tab) => tab.id == tabId
          ? tab.copyWith(url: update.url, title: update.title)
          : tab,
    )
    .toList(growable: false);

({bool? isLoading, bool? hasError, bool? canGoBack, bool? canGoForward})
_browserTabNavigationUpdate(bool isActive, BrowserTabUpdate update) => (
  isLoading: isActive ? update.isLoading : null,
  hasError: isActive ? update.hasError : null,
  canGoBack: isActive ? update.canGoBack : null,
  canGoForward: isActive ? update.canGoForward : null,
);

BrowserSessionState _copyBrowserTabUpdate(
  BrowserSessionState current,
  List<BrowserTab> tabs,
  ({bool? isLoading, bool? hasError, bool? canGoBack, bool? canGoForward})
  navigation,
) => current.copyWith(
  tabs: tabs,
  isLoading: navigation.isLoading,
  hasError: navigation.hasError,
  canGoBack: navigation.canGoBack,
  canGoForward: navigation.canGoForward,
);

mixin BrowserSessionSnapshotMatching on _$BrowserSessionNotifier {
  List<Map<Object?, Object?>> _snapshotElements(
    Map<Object?, Object?> snapshot,
  ) {
    final elements = snapshot['elements'];
    if (elements is! List<Object?>) return const [];

    return elements.whereType<Map<Object?, Object?>>().toList(growable: false);
  }

  bool _matchesSnapshotElement(
    Map<Object?, Object?> element, {
    required _BrowserFindCriteria criteria,
  }) =>
      _matchesSnapshotValue(element['role'], criteria.role, contains: false) &&
      _matchesSnapshotValue(element['name'], criteria.name) &&
      _matchesSnapshotValue(element['text'], criteria.text);

  bool _matchesSnapshotValue(
    Object? value,
    String? query, {
    bool contains = true,
  }) {
    if (query == null) return true;
    if (value is! String) return false;
    final normalizedValue = value.toLowerCase();
    final normalizedQuery = query.toLowerCase();

    return contains
        ? normalizedValue.contains(normalizedQuery)
        : normalizedValue == normalizedQuery;
  }
}

mixin BrowserSessionSkillToolRouter on _$BrowserSessionNotifier {
  BrowserSessionNotifier get _routerNotifier => this as BrowserSessionNotifier;

  Future<Object?> runSkillTool(
    String toolSlug,
    Map<String, dynamic> arguments,
  ) {
    final group = _browserSkillToolGroups[toolSlug];
    if (group == null) throw FormatException('Unknown browser tool: $toolSlug');
    _routerNotifier._recordBrowserSkillAction();

    return _resumeAndRunTool(group, toolSlug, arguments);
  }

  Future<Object?> _resumeAndRunTool(
    _BrowserSkillToolGroup group,
    String toolSlug,
    Map<String, dynamic> arguments,
  ) async {
    if (_routerNotifier._current.isSuspended &&
        !_browserToolsAllowedWhileSuspended.contains(toolSlug)) {
      await _routerNotifier.resume();
    }

    return await switch (group) {
      .tabs => _runTabTool(toolSlug, arguments),
      .page => _runBrowserPageTool(_routerNotifier, toolSlug, arguments),
      .element => _routerNotifier._runElementTool(toolSlug, arguments),
    };
  }

  Future<Object?> _runTabTool(
    String toolSlug,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolSlug) {
      case 'browser_list_tabs':
        return _routerNotifier._listToolTabs();
      case 'browser_open_tab':
        return await _routerNotifier._openToolTab(arguments);
      case 'browser_close_tab':
        return await _routerNotifier._closeToolTab(arguments);
      case 'browser_select_tab':
        return await _routerNotifier._selectToolTab(arguments);
      case 'browser_navigate':
      case 'browser_go_back':
      case 'browser_go_forward':
      case 'browser_reload':
        return await _runTabNavigationTool(toolSlug, arguments);
      case 'browser_execute_javascript':
      case 'browser_read_page':
        return await _runTabContentTool(toolSlug, arguments);
      default:
        throw FormatException('Unknown browser tool: $toolSlug');
    }
  }

  Future<Object?> _runTabNavigationTool(
    String toolSlug,
    Map<String, dynamic> arguments,
  ) => switch (toolSlug) {
    'browser_navigate' => _routerNotifier._navigateToolTab(arguments),
    'browser_go_back' => _routerNotifier._historyTool(
      arguments,
      _routerNotifier.goBack,
    ),
    'browser_go_forward' => _routerNotifier._historyTool(
      arguments,
      _routerNotifier.goForward,
    ),
    'browser_reload' => _routerNotifier._reloadTool(arguments),
    _ => throw FormatException('Unknown browser navigation tool: $toolSlug'),
  };

  Future<Object?> _runTabContentTool(
    String toolSlug,
    Map<String, dynamic> arguments,
  ) => switch (toolSlug) {
    'browser_execute_javascript' => _routerNotifier._executeToolJavaScript(
      arguments,
    ),
    'browser_read_page' => _routerNotifier._readToolPage(arguments),
    _ => throw FormatException('Unknown browser page tool: $toolSlug'),
  };
}
